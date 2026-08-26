import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';

/// Scroll axis and sense of a [BeuiMarquee].
enum BeuiMarqueeDirection { left, right, up, down }

/// Infinite duplicated-track marquee. Port of `components/motion/marquee.tsx`.
class BeuiMarquee extends StatefulWidget {
  const BeuiMarquee({
    super.key,
    required this.children,
    this.direction = BeuiMarqueeDirection.left,
    this.speed = 30,
    this.pauseOnHover = true,
    this.gap = 16,
    this.fade = true,
  });

  final List<Widget> children;

  /// CSS `left` / `right` / `up` / `down`.
  final BeuiMarqueeDirection direction;

  /// Seconds for one track length to pass. Default 30.
  final double speed;

  final bool pauseOnHover;

  /// Item-to-item and track-to-track spacing, in logical pixels (`1rem`).
  final double gap;

  /// Fade the leading and trailing 12% of the clip.
  final bool fade;

  @override
  State<BeuiMarquee> createState() => _BeuiMarqueeState();
}

class _BeuiMarqueeState extends State<BeuiMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  double _extent = 0;
  bool _paused = false;

  bool get _vertical =>
      widget.direction == BeuiMarqueeDirection.up ||
      widget.direction == BeuiMarqueeDirection.down;

  bool get _reverse =>
      widget.direction == BeuiMarqueeDirection.right ||
      widget.direction == BeuiMarqueeDirection.down;

  Duration get _period => Duration(
        microseconds: (widget.speed * 1000000).round().clamp(1, 1000000000),
      );

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: _period);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncClock();
  }

  @override
  void didUpdateWidget(BeuiMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _clock.duration = _period;
    }
    _syncClock();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _syncClock() {
    final live = TickerMode.valuesOf(context).enabled &&
        !beuiReduceMotion(context) &&
        !_paused &&
        widget.children.isNotEmpty;
    if (live) {
      if (!_clock.isAnimating) _clock.repeat();
    } else if (_clock.isAnimating) {
      _clock.stop();
    }
  }

  void _setPaused(bool value) {
    if (_paused == value) return;
    _paused = value;
    beuiAfterPointer(() {
      if (!mounted) return;
      _syncClock();
    });
  }

  void _onExtent(double next) {
    if ((next - _extent).abs() < 0.5) return;
    _extent = next;
    if (mounted) setState(() {});
  }

  Widget _track({required bool duplicate}) {
    return ExcludeSemantics(
      excluding: duplicate,
      child: IgnorePointer(
        ignoring: duplicate,
        child: Flex(
          direction: _vertical ? Axis.vertical : Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          spacing: widget.gap,
          children: widget.children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = _vertical
            ? (constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 200.0)
            : (constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 460.0);

        Widget scroller = ClipRect(
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, child) {
              final travel = _extent + widget.gap;
              final t = _clock.value;
              final offset = travel * (_reverse ? -(1 - t) : -t);
              return Transform.translate(
                offset: _vertical ? Offset(0, offset) : Offset(offset, 0),
                child: child,
              );
            },
            child: Flex(
              direction: _vertical ? Axis.vertical : Axis.horizontal,
              mainAxisSize: MainAxisSize.min,
              spacing: widget.gap,
              children: [
                _MeasureExtent(
                  axis: _vertical ? Axis.vertical : Axis.horizontal,
                  onExtent: _onExtent,
                  child: _track(duplicate: false),
                ),
                _track(duplicate: true),
              ],
            ),
          ),
        );

        if (widget.fade) {
          scroller = ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              return LinearGradient(
                begin: _vertical
                    ? Alignment.topCenter
                    : Alignment.centerLeft,
                end: _vertical
                    ? Alignment.bottomCenter
                    : Alignment.centerRight,
                colors: const [
                  Color(0x00000000),
                  Color(0xFF000000),
                  Color(0xFF000000),
                  Color(0x00000000),
                ],
                stops: const [0, 0.12, 0.88, 1],
              ).createShader(rect);
            },
            child: scroller,
          );
        }

        Widget box = SizedBox(
          width: _vertical ? null : bounded,
          height: _vertical ? bounded : null,
          child: scroller,
        );

        if (widget.pauseOnHover) {
          box = MouseRegion(
            onEnter: (_) {
              if (!beuiHoverCapable(context)) return;
              _setPaused(true);
            },
            onExit: (_) => _setPaused(false),
            child: box,
          );
        }

        return box;
      },
    );
  }
}

class _MeasureExtent extends StatelessWidget {
  const _MeasureExtent({
    required this.axis,
    required this.onExtent,
    required this.child,
  });

  final Axis axis;
  final ValueChanged<double> onExtent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      onExtent(axis == Axis.vertical ? box.size.height : box.size.width);
    });
    return child;
  }
}
