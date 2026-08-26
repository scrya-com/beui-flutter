import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/theme.dart';
import 'button.dart';

/// Neutral button framed by a chrome rim with a traveling reflection.
/// Port of `components/motion/button/metallic.tsx`.
class BeuiMetallicButton extends StatefulWidget {
  const BeuiMetallicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.size = BeuiButtonSize.md,
    this.paused = false,
    this.enabled = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final BeuiButtonSize size;
  final bool paused;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<BeuiMetallicButton> createState() => _BeuiMetallicButtonState();
}

class _BeuiMetallicButtonState extends State<BeuiMetallicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (!widget.paused) _drift.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(BeuiMetallicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused || beuiReduceMotion(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = widget.paused || beuiReduceMotion(context);
    final radius = widget.size == BeuiButtonSize.icon
        ? BeuiRadii.pill
        : BeuiRadii.pill;
    return BeuiButton(
      onPressed: widget.onPressed,
      variant: BeuiButtonVariant.ghost,
      size: widget.size,
      enabled: widget.enabled,
      semanticLabel: widget.semanticLabel,
      surface: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: still
            ? const _ChromeFill(shift: 0)
            : AnimatedBuilder(
                animation: _drift,
                builder: (context, _) => _ChromeFill(shift: _drift.value * 0.13),
              ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Color(0xFFF5F5F5),
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: Color(0x80000000), blurRadius: 4)],
        ),
        child: widget.child,
      ),
    );
  }
}

class _ChromeFill extends StatelessWidget {
  const _ChromeFill({required this.shift});
  final double shift;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(shift * 40, 0),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1, 0),
            end: Alignment(1, 0),
            colors: [
              Color(0xFF111111),
              Color(0xFF737373),
              Color(0xFFFAFAFA),
              Color(0xFF525252),
              Color(0xFF0A0A0A),
              Color(0xFFA3A3A3),
              Color(0xFFFFFFFF),
              Color(0xFF404040),
              Color(0xFF111111),
            ],
            stops: [0, 0.14, 0.26, 0.38, 0.50, 0.64, 0.75, 0.87, 1],
          ),
        ),
      ),
    );
  }
}
