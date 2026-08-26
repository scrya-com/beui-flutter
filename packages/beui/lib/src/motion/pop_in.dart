import 'package:flutter/widgets.dart';

import '../tokens/ease.dart';
import 'reduce.dart';
import 'spring_motion.dart';

/// Mount-only scale + opacity pop. Starts at [fromScale] and springs to 1.
class BeuiPopIn extends StatefulWidget {
  const BeuiPopIn({
    super.key,
    required this.child,
    this.spec = const BeuiSpringSpec(stiffness: 520, damping: 27, mass: 0.52),
    this.alignment = Alignment.bottomLeft,
    this.fromScale = 0.92,
    this.enabled = true,
  });

  final Widget child;
  final BeuiSpringSpec spec;
  final Alignment alignment;
  final double fromScale;
  final bool enabled;

  @override
  State<BeuiPopIn> createState() => _BeuiPopInState();
}

class _BeuiPopInState extends State<BeuiPopIn>
    with SingleTickerProviderStateMixin {
  late final BeuiSpringValue _spring;

  @override
  void initState() {
    super.initState();
    _spring = BeuiSpringValue(
      value: widget.enabled ? 0 : 1,
      spec: widget.spec,
    )..attach(this);
    _spring.addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.enabled) return;
      _spring.reducedMotion = beuiReduceMotion(context);
      _spring.animateTo(1);
    });
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _spring.reducedMotion = beuiReduceMotion(context);
  }

  @override
  void dispose() {
    _spring
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _spring.value;
    final scale = widget.fromScale + (1 - widget.fromScale) * t;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.scale(
        alignment: widget.alignment,
        scale: scale,
        child: widget.child,
      ),
    );
  }
}
