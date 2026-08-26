import 'dart:math' as math;

import '../tokens/ease.dart';

/// Closed-form damped harmonic oscillator, ported from
/// `crates/ui_physics/src/lib.rs` (`spring_response` / `spring_ease`).
///
/// Response is the displacement at time [t] seconds of a spring released from
/// 1 with zero velocity. Ease is `1 - response` (0 → 1, may overshoot).
double beuiSpringResponse(
  double t,
  double mass,
  double stiffness,
  double damping,
) {
  if (t <= 0) return 1;
  final omega = math.sqrt(stiffness / mass);
  final zeta = damping / (2.0 * math.sqrt(mass * stiffness));
  final env = math.exp(-zeta * omega * t);
  if (zeta < 1.0) {
    final omegaD = omega * math.sqrt(1.0 - zeta * zeta);
    return env *
        (math.cos(omegaD * t) + (zeta * omega / omegaD) * math.sin(omegaD * t));
  }
  if ((zeta - 1.0).abs() < 1e-9) {
    return env * (1.0 + omega * t);
  }
  final a = omega * math.sqrt(zeta * zeta - 1.0);
  return env *
      ((math.exp(a * t) + math.exp(-a * t)) / 2.0 +
          (zeta * omega / a) *
              ((math.exp(a * t) - math.exp(-a * t)) / 2.0));
}

/// Spring-based easing 0 → 1, possibly overshooting past 1 then settling.
double beuiSpringEase(
  double t,
  double mass,
  double stiffness,
  double damping,
) =>
    1.0 - beuiSpringResponse(t, mass, stiffness, damping);

double beuiSpringEaseSpec(double t, BeuiSpringSpec spec) =>
    beuiSpringEase(t, spec.mass, spec.stiffness, spec.damping);

/// Approximate settling time: 4 / (ζω), floored at 80ms, capped at 1.2s.
Duration beuiSpringSettleDuration(BeuiSpringSpec spec) {
  final omega = math.sqrt(spec.stiffness / spec.mass);
  final zeta = spec.damping / (2.0 * math.sqrt(spec.mass * spec.stiffness));
  final seconds = (4.0 / (zeta * omega)).clamp(0.08, 1.2);
  return Duration(milliseconds: (seconds * 1000).round());
}

/// One Euler step of a follow-spring toward a moving target.
/// Used by magnetic / tilt cursor tracking (`SPRING_MOUSE`).
({double value, double velocity}) beuiSpringStep({
  required double value,
  required double velocity,
  required double target,
  required BeuiSpringSpec spec,
  required double dt,
}) {
  final acc =
      (spec.stiffness * (target - value) - spec.damping * velocity) / spec.mass;
  final nextV = velocity + acc * dt;
  final next = value + nextV * dt;
  return (value: next, velocity: nextV);
}

/// Ease-out-back. Port of `back_ease` in ui_physics.
double beuiBackEase(double t, [double amount = 1.70158]) {
  final u = t - 1.0;
  return 1.0 + (amount + 1.0) * u * u * u + amount * u * u;
}

/// iOS-style deceleration ease. Port of `deceleration_ease`.
double beuiDecelerationEase(double t, [double rate = 0.998]) {
  if ((rate - 1.0).abs() < 1e-9) return t;
  return (1.0 - math.pow(rate, t)) / (1.0 - rate);
}
