import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

/// 3D perspective tilt on hover with cursor-tracked glare.
/// Port of `components/motion/tilt-card.tsx`.
class BeuiTiltCard extends StatefulWidget {
  const BeuiTiltCard({
    super.key,
    required this.child,
    this.max = 12,
    this.glare = true,
  });

  final Widget child;

  /// Max tilt in degrees. React default 12.
  final double max;
  final bool glare;

  @override
  State<BeuiTiltCard> createState() => _BeuiTiltCardState();
}

class _BeuiTiltCardState extends State<BeuiTiltCard>
    with TickerProviderStateMixin {
  late final BeuiFollowSpring _rx;
  late final BeuiFollowSpring _ry;
  double _gx = 50;
  double _gy = 50;
  bool _frame = false;

  @override
  void initState() {
    super.initState();
    _rx = BeuiFollowSpring(spec: BeuiSpringSpec.mouse)..attach(this);
    _ry = BeuiFollowSpring(spec: BeuiSpringSpec.mouse)..attach(this);
    _rx.addListener(_tick);
    _ry.addListener(_tick);
  }

  void _tick() {
    if (_frame) return;
    _frame = true;
    beuiAfterPointer(() {
      _frame = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _rx
      ..removeListener(_tick)
      ..dispose();
    _ry
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  bool get _enabled =>
      !beuiReduceMotion(context) && beuiHoverCapable(context);

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final enabled = _enabled;
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(_rx.value * math.pi / 180)
      ..rotateY(_ry.value * math.pi / 180);

    return MouseRegion(
      onHover: (e) {
        if (!_enabled) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final px = (e.localPosition.dx / box.size.width).clamp(0.0, 1.0);
        final py = (e.localPosition.dy / box.size.height).clamp(0.0, 1.0);
        _ry.setTarget((px - 0.5) * widget.max);
        _rx.setTarget((0.5 - py) * widget.max);
        _gx = px * 100;
        _gy = py * 100;
      },
      onExit: (_) {
        _rx.setTarget(0, enabled: _enabled);
        _ry.setTarget(0, enabled: _enabled);
      },
      child: Transform(
        alignment: Alignment.center,
        transform: transform,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BeuiRadii.card),
          child: Stack(
            children: [
              widget.child,
              if (widget.glare && enabled)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.15,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(
                              (_gx / 50) - 1,
                              (_gy / 50) - 1,
                            ),
                            radius: 1,
                            colors: [
                              colors.foreground,
                              colors.foreground.withValues(alpha: 0),
                            ],
                            stops: const [0, 0.5],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
