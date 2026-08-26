import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/ease.dart';

/// Spring-eased slide + blur on viewport enter.
/// Port of `components/motion/scroll-reveal.tsx`.
class BeuiScrollReveal extends StatefulWidget {
  const BeuiScrollReveal({
    super.key,
    required this.child,
    this.y = 16,
    this.blur = 8,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.once = true,
    this.amount = 0.3,
  });

  final Widget child;

  /// Slide distance in logical pixels before reveal.
  final double y;

  /// Enter blur in px (kept ≤ 10).
  final double blur;

  final Duration duration;
  final Duration delay;

  /// Reveal only once (default) or every time it enters view.
  final bool once;

  /// Portion of the element that must be visible to trigger (0–1).
  final double amount;

  @override
  State<BeuiScrollReveal> createState() => _BeuiScrollRevealState();
}

class _BeuiScrollRevealState extends State<BeuiScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ScrollPosition? _position;
  bool _inView = false;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _syncTiming();
    _controller.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _syncTiming() {
    final total = widget.duration + widget.delay;
    _controller.duration = total <= Duration.zero
        ? const Duration(milliseconds: 1)
        : total;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attach();
  }

  @override
  void didUpdateWidget(BeuiScrollReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration ||
        oldWidget.delay != widget.delay) {
      _syncTiming();
    }
  }

  void _attach() {
    final next = Scrollable.maybeOf(context)?.position;
    if (identical(next, _position)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _check();
      });
      return;
    }
    _position?.removeListener(_check);
    _position = next;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  double get _t {
    final totalMs = _controller.duration?.inMilliseconds ?? 1;
    final delayMs = widget.delay.inMilliseconds.clamp(0, totalMs);
    final start = delayMs / math.max(totalMs, 1);
    if (_controller.value <= start) return 0;
    final local = ((_controller.value - start) / (1 - start)).clamp(0.0, 1.0);
    return BeuiCurves.easeOut.transform(local);
  }

  bool _isVisible() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final childRect = box.localToGlobal(Offset.zero) & box.size;
    if (childRect.isEmpty) return false;

    Rect viewportRect;
    final scrollableContext = Scrollable.maybeOf(context)?.context;
    final viewportBox = scrollableContext?.findRenderObject() as RenderBox?;
    if (viewportBox != null && viewportBox.hasSize) {
      viewportRect = viewportBox.localToGlobal(Offset.zero) & viewportBox.size;
    } else {
      viewportRect = Offset.zero & MediaQuery.sizeOf(context);
    }

    final intersection = childRect.intersect(viewportRect);
    if (intersection.isEmpty) return false;
    final area = childRect.width * childRect.height;
    if (area <= 0) return false;
    final visible = intersection.width * intersection.height;
    return visible / area >= widget.amount;
  }

  void _check() {
    if (!mounted) return;
    if (_shown && widget.once) return;
    final visible = _isVisible();
    if (visible == _inView) return;
    _inView = visible;
    if (visible) {
      _shown = true;
      _controller.forward();
    } else if (!widget.once) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = beuiReduceMotion(context);
    final t = _t;
    final opacity = t.clamp(0.0, 1.0);
    final dy = reduce ? 0.0 : widget.y * (1 - t);
    final blur = reduce
        ? 0.0
        : (math.min(widget.blur, 10) * (1 - t)).clamp(0.0, 10.0);

    Widget child = widget.child;
    if (blur > 0.2) {
      child = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      );
    }
    return Opacity(
      opacity: opacity,
      child: Transform.translate(offset: Offset(0, dy), child: child),
    );
  }
}
