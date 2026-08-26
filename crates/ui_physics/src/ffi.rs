//! C-ABI exports for native iOS/macOS via `dart:ffi`.
//!
//! These `#[no_mangle] extern "C"` functions wrap the same physics/dynamics
//! logic as the wasm-bindgen exports, but are callable from Dart FFI when the
//! crate is compiled to a static library and linked into the Flutter app.

use std::slice;

#[no_mangle]
pub extern "C" fn ui_physics_spring_ease(
    t: f64,
    mass: f64,
    stiffness: f64,
    damping: f64,
) -> f64 {
    crate::spring_ease(t, mass, stiffness, damping)
}

#[no_mangle]
pub extern "C" fn ui_physics_spring_response(
    t: f64,
    mass: f64,
    stiffness: f64,
    damping: f64,
) -> f64 {
    crate::spring_response(t, mass, stiffness, damping)
}

#[no_mangle]
pub extern "C" fn ui_physics_deceleration_ease(t: f64, rate: f64) -> f64 {
    crate::deceleration_ease(t, rate)
}

#[no_mangle]
pub extern "C" fn ui_physics_back_ease(t: f64, amount: f64) -> f64 {
    crate::back_ease(t, amount)
}

#[no_mangle]
pub extern "C" fn ui_physics_compute_deceleration(velocity: f64, dt: f64) -> f64 {
    crate::compute_deceleration(velocity, dt)
}

#[no_mangle]
pub extern "C" fn ui_physics_resolve_overscroll(
    target: f64,
    max_offset: f64,
    bounces: bool,
) -> f64 {
    crate::resolve_overscroll(target, max_offset, bounces)
}

/// One gravity+collision step; writes `[y, vy]` into `out` (len >= 2).
#[no_mangle]
pub unsafe extern "C" fn ui_physics_dynamics_step(
    y: f64,
    vy: f64,
    gravity: f64,
    ground: f64,
    elasticity: f64,
    dt: f64,
    out: *mut f64,
) {
    let r = crate::dynamics_step(y, vy, gravity, ground, elasticity, dt);
    if !out.is_null() {
        let out = slice::from_raw_parts_mut(out, 2);
        out[0] = r[0];
        out[1] = r[1];
    }
}

/// Simulates a falling item; writes the trajectory into `out` (len >= 2) and
/// returns the number of samples written.
#[no_mangle]
pub unsafe extern "C" fn ui_physics_simulate_ball_drop(
    start_y: f64,
    gravity: f64,
    ground: f64,
    elasticity: f64,
    max_steps: usize,
    dt: f64,
    out: *mut f64,
) -> usize {
    let traj = crate::simulate_ball_drop(start_y, gravity, ground, elasticity, max_steps as u32, dt);
    let n = traj.len().min(max_steps);
    if !out.is_null() {
        let out = slice::from_raw_parts_mut(out, n);
        for (i, v) in traj.iter().take(n).enumerate() {
            out[i] = *v;
        }
    }
    n
}

/// Fills `out` (len `steps`) with decelerating offsets and returns the number
/// written (port of `batch_compute_offsets`).
#[no_mangle]
pub unsafe extern "C" fn ui_physics_batch_offsets(
    current: f64,
    velocity: f64,
    steps: usize,
    dt: f64,
    content_size: f64,
    container_size: f64,
    bounces: bool,
    out: *mut f64,
) -> usize {
    let res = crate::batch_compute_offsets(
        current,
        velocity,
        steps as u32,
        dt,
        content_size,
        container_size,
        bounces,
    );
    let n = res.len().min(steps);
    if !out.is_null() {
        let out = slice::from_raw_parts_mut(out, n);
        for (i, v) in res.iter().take(n).enumerate() {
            out[i] = *v;
        }
    }
    n
}
