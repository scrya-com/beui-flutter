import 'package:flutter/widgets.dart';

import 'button.dart';
import 'magnetic.dart';

/// Button composed with the Magnetic wrapper. Port of `button/magnetic.tsx`.
class BeuiMagneticButton extends StatelessWidget {
  const BeuiMagneticButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = BeuiButtonVariant.primary,
    this.size = BeuiButtonSize.md,
    this.strength = 0.25,
    this.pressScale = 0.93,
    this.ripple = false,
    this.enabled = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final BeuiButtonVariant variant;
  final BeuiButtonSize size;
  final double strength;
  final double pressScale;
  final bool ripple;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return BeuiMagnetic(
      strength: strength,
      child: BeuiButton(
        onPressed: onPressed,
        variant: variant,
        size: size,
        pressScale: pressScale,
        ripple: ripple,
        enabled: enabled,
        semanticLabel: semanticLabel,
        child: child,
      ),
    );
  }
}
