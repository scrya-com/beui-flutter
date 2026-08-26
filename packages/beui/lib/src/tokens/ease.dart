import 'package:flutter/animation.dart';

/// Shared motion tokens. Mirrors `lib/ease.ts` in the React library.
///
/// Springs are damped harmonic oscillators with the same mass / stiffness /
/// damping the React components pass to Motion. The solver lives in
/// `crates/ui_physics` (Rust) with a Dart fallback of the same closed form.
class BeuiCurves {
  BeuiCurves._();

  /// `EASE_OUT` — cubic-bezier(0.16, 1, 0.3, 1)
  static const Cubic easeOut = Cubic(0.16, 1.0, 0.3, 1.0);

  /// `EASE_IN_OUT` — cubic-bezier(0.77, 0, 0.175, 1)
  static const Cubic easeInOut = Cubic(0.77, 0.0, 0.175, 1.0);

  /// `EASE_DRAWER` — cubic-bezier(0.32, 0.72, 0, 1)
  static const Cubic easeDrawer = Cubic(0.32, 0.72, 0.0, 1.0);
}

/// A Framer Motion-compatible spring: `type: "spring"` with k / c / m.
class BeuiSpringSpec {
  const BeuiSpringSpec({
    required this.stiffness,
    required this.damping,
    required this.mass,
  });

  final double stiffness;
  final double damping;
  final double mass;

  /// Press feedback on buttons and other tappable surfaces.
  static const press = BeuiSpringSpec(
    stiffness: 500,
    damping: 30,
    mass: 0.6,
  );

  /// Content swaps — label/icon slots trading places inside a control.
  static const swap = BeuiSpringSpec(
    stiffness: 460,
    damping: 30,
    mass: 0.55,
  );

  /// Overlay panel entrances — modals and sheets summoned by pointer.
  static const panel = BeuiSpringSpec(
    stiffness: 420,
    damping: 40,
    mass: 0.5,
  );

  /// Shared-layout glides — pills, indicators and panels morphing.
  static const layout = BeuiSpringSpec(
    stiffness: 360,
    damping: 32,
    mass: 0.6,
  );

  /// Cursor-follow physics for decorative mouse tracking.
  static const mouse = BeuiSpringSpec(
    stiffness: 200,
    damping: 15,
    mass: 0.3,
  );

  /// Dragged handles and fills — critically damped, no rebound.
  static const glide = BeuiSpringSpec(
    stiffness: 700,
    damping: 50,
    mass: 0.5,
  );

  /// Weighty tab indicator (`tabs.tsx` local spring).
  static const tabs = BeuiSpringSpec(
    stiffness: 170,
    damping: 24,
    mass: 1.2,
  );

  /// Heavy switch thumb (`switch.tsx` local spring).
  static const switchThumb = BeuiSpringSpec(
    stiffness: 800,
    damping: 80,
    mass: 4,
  );
}
