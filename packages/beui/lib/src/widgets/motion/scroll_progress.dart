import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

enum BeuiScrollProgressVariant { bar, circle }

enum BeuiScrollProgressEdge { top, bottom }

/// Soft follow so the indicator trails the scroll (`scroll-progress.tsx`).
const _kProgressSpring = BeuiSpringSpec(stiffness: 120, damping: 30, mass: 0.6);

/// Reading-progress indicator — bar or circular ring.
/// Port of `components/motion/scroll-progress.tsx`.
class BeuiScrollProgress extends StatefulWidget {
  const BeuiScrollProgress({
    super.key,
    this.variant = BeuiScrollProgressVariant.bar,
    this.progress,
    this.controller,
    this.spring = true,
    this.position = BeuiScrollProgressEdge.top,
    this.height = 2,
    this.size = 40,
    this.thickness = 3,
  });

  final BeuiScrollProgressVariant variant;

  /// Explicit 0–1 progress. Overrides [controller] and the nearest scrollable.
  final double? progress;
  final ScrollController? controller;

  /// Spring-smooth the value. Disabled automatically under reduced motion.
  final bool spring;
  final BeuiScrollProgressEdge position;

  /// Bar thickness in logical pixels.
  final double height;

  /// Circle diameter in logical pixels.
  final double size;

  /// Circle stroke width in logical pixels.
  final double thickness;

  @override
  State<BeuiScrollProgress> createState() => _BeuiScrollProgressState();
}

class _BeuiScrollProgressState extends State<BeuiScrollProgress>
    with SingleTickerProviderStateMixin {
  late final BeuiFollowSpring _follow;
  ScrollPosition? _position;
  ScrollController? _controller;

  @override
  void initState() {
    super.initState();
    _follow =
        BeuiFollowSpring(value: widget.progress ?? 0, spec: _kProgressSpring)
          ..attach(this)
          ..addListener(_onTick);
    _controller = widget.controller;
    _controller?.addListener(_onScroll);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachNearest();
    _sync();
  }

  @override
  void didUpdateWidget(BeuiScrollProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onScroll);
      _controller = widget.controller;
      _controller?.addListener(_onScroll);
    }
    if (widget.controller == null) _attachNearest();
    _sync();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onScroll);
    _position?.removeListener(_onScroll);
    _follow
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _attachNearest() {
    if (widget.controller != null || widget.progress != null) return;
    final next = Scrollable.maybeOf(context)?.position;
    if (identical(next, _position)) return;
    _position?.removeListener(_onScroll);
    _position = next;
    _position?.addListener(_onScroll);
  }

  void _onScroll() => _sync();

  double _raw() {
    if (widget.progress != null) return widget.progress!.clamp(0.0, 1.0);
    final metrics = widget.controller?.hasClients == true
        ? widget.controller!.position
        : _position;
    if (metrics == null || !metrics.hasPixels) return 0;
    final extent = metrics.maxScrollExtent;
    if (extent <= 0) return 0;
    return (metrics.pixels / extent).clamp(0.0, 1.0);
  }

  void _sync({bool jump = false}) {
    final raw = _raw();
    final reduce = beuiReduceMotion(context);
    if (jump || !widget.spring || reduce) {
      _follow.jump(raw);
    } else {
      _follow.setTarget(raw);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final value = _follow.value.clamp(0.0, 1.0);
    if (widget.variant == BeuiScrollProgressVariant.circle) {
      return ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _RingPainter(
            progress: value,
            color: colors.foreground,
            thickness: widget.thickness,
          ),
        ),
      );
    }
    return ExcludeSemantics(
      child: Align(
        alignment: widget.position == BeuiScrollProgressEdge.top
            ? Alignment.topCenter
            : Alignment.bottomCenter,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Transform.scale(
            alignment: Alignment.centerLeft,
            scaleX: value,
            child: ColoredBox(color: colors.foreground),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.thickness,
  });

  final double progress;
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - thickness) / 2;
    final track = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 2);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi * progress,
      false,
      fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.thickness != thickness;
}
