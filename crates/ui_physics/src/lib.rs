use wasm_bindgen::prelude::*;

mod ffi;

const DECELERATION_RATE: f64 = 0.998;
const SPRING_TIGHTNESS: f64 = 0.55;
const DAMPING_RATIO: f64 = 0.85;
const PI: f64 = std::f64::consts::PI;

#[wasm_bindgen]
pub fn compute_deceleration(velocity: f64, dt: f64) -> f64 {
    let pow = DECELERATION_RATE.powf(1000.0 * dt);
    velocity * pow
}

#[wasm_bindgen]
pub fn compute_bounce_offset(offset: f64, max_offset: f64) -> f64 {
    if offset < 0.0 {
        return offset * 0.5;
    }
    if offset > max_offset && max_offset > 0.0 {
        let overscroll = offset - max_offset;
        return max_offset + overscroll * 0.5;
    }
    offset
}

#[wasm_bindgen]
pub fn compute_spring_bounce(
    offset: f64,
    max_offset: f64,
    time: f64,
    velocity: f64,
) -> f64 {
    let overshoot = if offset > max_offset {
        offset - max_offset
    } else if offset < 0.0 {
        offset
    } else {
        return offset;
    };

    let angular_frequency = SPRING_TIGHTNESS * 2.0 * PI;
    let damping = DAMPING_RATIO;
    let envelope = (-damping * angular_frequency * time).exp();
    let oscillation =
        (angular_frequency * (1.0 - damping * damping).sqrt() * time).cos();
    let correction = overshoot * envelope * oscillation;

    if offset > max_offset {
        max_offset + correction
    } else {
        correction
    }
}

#[wasm_bindgen]
pub fn should_decelerate(velocity: f64) -> bool {
    velocity.abs() > 10.0
}

#[wasm_bindgen]
pub fn should_bounce(offset: f64, max_offset: f64) -> bool {
    (offset < -0.5) || (offset > max_offset + 0.5 && max_offset > 0.0)
}

#[wasm_bindgen]
pub fn resolve_overscroll(target_offset: f64, max_offset: f64, bounces: bool) -> f64 {
    if !bounces {
        if max_offset > 0.0 {
            return target_offset.clamp(0.0, max_offset);
        }
        return target_offset.max(0.0);
    }
    if target_offset < 0.0 {
        return target_offset * 0.3;
    }
    if target_offset > max_offset && max_offset > 0.0 {
        let overshoot = target_offset - max_offset;
        return max_offset + overshoot * 0.3;
    }
    target_offset
}

#[wasm_bindgen]
pub fn compute_content_offset(
    current_offset: f64,
    velocity: f64,
    dt: f64,
    content_size: f64,
    container_size: f64,
    bounces: bool,
) -> f64 {
    let decel_velocity = compute_deceleration(velocity, dt);
    // Distance travelled this step = velocity × dt.
    let delta = decel_velocity * dt;
    let new_offset = current_offset + delta;
    let max_off = (content_size - container_size).max(0.0);

    if should_bounce(new_offset, max_off) && bounces {
        return new_offset;
    }
    if !bounces {
        return new_offset.clamp(0.0, max_off);
    }
    resolve_overscroll(new_offset, max_off, true)
}

#[wasm_bindgen]
pub fn batch_compute_offsets(
    current_offset: f64,
    velocity: f64,
    steps: u32,
    dt: f64,
    content_size: f64,
    container_size: f64,
    bounces: bool,
) -> Vec<f64> {
    let mut results = Vec::with_capacity(steps as usize);
    let mut off = current_offset;
    let mut vel = velocity;
    let max_off = (content_size - container_size).max(0.0);

    for _ in 0..steps {
        vel = compute_deceleration(vel, dt);
        // Distance travelled this step = velocity × dt.
        let delta = vel * dt;
        off += delta;

        if !bounces {
            off = off.clamp(0.0, max_off);
        } else {
            off = resolve_overscroll(off, max_off, true);
        }

        results.push(off);

        if vel.abs() < 0.5 {
            break;
        }
    }

    results
}

#[wasm_bindgen]
pub fn visible_row_range(
    scroll_offset: f64,
    container_height: f64,
    row_height: f64,
    total_rows: u32,
    cache_extent: f64,
) -> Vec<u32> {
    let start = ((scroll_offset - cache_extent) / row_height).floor() as i32;
    let end = ((scroll_offset + container_height + cache_extent) / row_height).ceil() as i32;

    let start_clamped = start.max(0) as u32;
    let end_clamped = (end as u32).min(total_rows);

    (start_clamped..end_clamped).collect()
}

/// Response of a damped harmonic oscillator (the spring) at time `t`, released
/// from displacement 1 with zero velocity. Used to build UIKit-style spring
/// easing curves. Port of `UISpringTimingParameters` dynamics.
#[wasm_bindgen]
pub fn spring_response(t: f64, mass: f64, stiffness: f64, damping: f64) -> f64 {
    let omega = (stiffness / mass).sqrt();
    let zeta = damping / (2.0 * (mass * stiffness).sqrt());
    let env = (-zeta * omega * t).exp();

    if zeta < 1.0 {
        // Underdamped: decaying sinusoid.
        let omega_d = omega * (1.0 - zeta * zeta).sqrt();
        env * ((omega_d * t).cos() + (zeta * omega / omega_d) * (omega_d * t).sin())
    } else if (zeta - 1.0).abs() < 1e-9 {
        // Critically damped: returns to zero fastest without oscillation.
        env * (1.0 + omega * t)
    } else {
        // Overdamped: two real exponentials, no oscillation.
        let a = omega * (zeta * zeta - 1.0).sqrt();
        env * ((a * t).cosh() + (zeta * omega / a) * (a * t).sinh())
    }
}

/// A spring-based easing: 0 -> 1, possibly overshooting past 1 then settling
/// (the "bounce" look), matching UIKit spring timing.
#[wasm_bindgen]
pub fn spring_ease(t: f64, mass: f64, stiffness: f64, damping: f64) -> f64 {
    1.0 - spring_response(t, mass, stiffness, damping)
}

/// Ease-out driven by the iOS deceleration rate: fast at first, tapering to
/// rest. Port of `compute_deceleration`-based momentum as an easing curve.
#[wasm_bindgen]
pub fn deceleration_ease(t: f64, rate: f64) -> f64 {
    if (rate - 1.0).abs() < 1e-9 {
        return t;
    }
    (1.0 - rate.powf(t)) / (1.0 - rate)
}

/// Ease-out-back: overshoots `amount` beyond 1 then settles (a back-ease).
#[wasm_bindgen]
pub fn back_ease(t: f64, amount: f64) -> f64 {
    let u = t - 1.0;
    1.0 + (amount + 1.0) * u * u * u + amount * u * u
}

/// One integration step of a falling item under gravity with a ground
/// collision (elasticity in 0..1). Used by the UIKit Dynamics engine.
///
/// Returns `[y, vy]` after `dt` seconds.
#[wasm_bindgen]
pub fn dynamics_step(
    y: f64,
    vy: f64,
    gravity: f64,
    ground: f64,
    elasticity: f64,
    dt: f64,
) -> Vec<f64> {
    let mut v = vy + gravity * dt;
    let mut pos = y + v * dt;
    if pos >= ground {
        pos = ground;
        if v > 0.0 {
            v = -v * elasticity;
            if v.abs() < 20.0 {
                v = 0.0;
            }
        }
    }
    vec![pos, v]
}

/// Simulates `steps` dynamics steps from rest, returning the y trajectory.
/// Powers the gravity/bounce showcase.
#[wasm_bindgen]
pub fn simulate_ball_drop(
    start_y: f64,
    gravity: f64,
    ground: f64,
    elasticity: f64,
    steps: u32,
    dt: f64,
) -> Vec<f64> {
    let mut results = Vec::with_capacity(steps as usize);
    let mut y = start_y;
    let mut vy = 0.0;
    for _ in 0..steps {
        let r = dynamics_step(y, vy, gravity, ground, elasticity, dt);
        y = r[0];
        vy = r[1];
        results.push(y);
        if vy.abs() < 0.5 && (y - ground).abs() < 1.0 {
            break;
        }
    }
    results
}
