import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';

/// Cursor-attracted magnetic pull wrapper. Port of `components/motion/magnetic.tsx`.
class BeuiMagnetic extends StatefulWidget {
  const BeuiMagnetic({
    super.key,
    required this.child,
    this.strength = 0.35,
  });

  final Widget child;
  final double strength;

  @override
  State<BeuiMagnetic> createState() => _BeuiMagneticState();
}

class _BeuiMagneticState extends State<BeuiMagnetic>
    with TickerProviderStateMixin {
  late final BeuiFollowSpring _x;
  late final BeuiFollowSpring _y;

  @override
  void initState() {
    super.initState();
    _x = BeuiFollowSpring(spec: BeuiSpringSpec.mouse)..attach(this);
    _y = BeuiFollowSpring(spec: BeuiSpringSpec.mouse)..attach(this);
    _x.addListener(_tick);
    _y.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _x
      ..removeListener(_tick)
      ..dispose();
    _y
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  bool get _enabled =>
      !beuiReduceMotion(context) && beuiHoverCapable(context);

  void _onHover(PointerEvent event, Size size) {
    if (!_enabled) return;
    final dx = (event.localPosition.dx - size.width / 2) * widget.strength;
    final dy = (event.localPosition.dy - size.height / 2) * widget.strength;
    _x.setTarget(dx);
    _y.setTarget(dy);
  }

  void _reset() {
    _x.setTarget(0);
    _y.setTarget(0);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        _onHover(e, box.size);
      },
      onExit: (_) => _reset(),
      child: Transform.translate(
        offset: Offset(_x.value, _y.value),
        child: widget.child,
      ),
    );
  }
}
