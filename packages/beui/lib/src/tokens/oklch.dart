import 'dart:math' as math;
import 'dart:ui';

/// CSS `oklch(L% C H / A)` → sRGB [Color].
Color oklch({
  required double l,
  required double c,
  required double h,
  double alpha = 1,
}) {
  final hr = h * math.pi / 180.0;
  final a = c * math.cos(hr);
  final b = c * math.sin(hr);

  final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  final s_ = l - 0.0894841775 * a - 1.2914855480 * b;

  final lmsL = l_ * l_ * l_;
  final lmsM = m_ * m_ * m_;
  final lmsS = s_ * s_ * s_;

  final rLin =
      4.0767416621 * lmsL - 3.3077115913 * lmsM + 0.2309699292 * lmsS;
  final gLin =
      -1.2684380046 * lmsL + 2.6097574011 * lmsM - 0.3413193965 * lmsS;
  final bLin =
      -0.0041960863 * lmsL - 0.7034186147 * lmsM + 1.7076147010 * lmsS;

  return Color.fromARGB(
    (alpha.clamp(0.0, 1.0) * 255).round(),
    (_srgb(rLin) * 255).round().clamp(0, 255),
    (_srgb(gLin) * 255).round().clamp(0, 255),
    (_srgb(bLin) * 255).round().clamp(0, 255),
  );
}

double _srgb(double c) {
  final x = c.clamp(0.0, 1.0);
  if (x <= 0.0031308) return 12.92 * x;
  return 1.055 * math.pow(x, 1.0 / 2.4) - 0.055;
}

Color oklchPercent({
  required double lPercent,
  required double c,
  required double h,
  double alpha = 1,
}) =>
    oklch(l: lPercent / 100.0, c: c, h: h, alpha: alpha);
