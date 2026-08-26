import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

/// Slide-to-confirm track with a morphing chevron thumb.
/// Port of `slide-action-button.tsx`.
class BeuiSlideActionButton extends StatefulWidget {
  const BeuiSlideActionButton({
    super.key,
    required this.child,
    this.completeLabel = const Text('Complete'),
    this.threshold = 0.82,
    this.resetDelay = const Duration(milliseconds: 1200),
    this.onComplete,
    this.enabled = true,
    this.semanticLabel,
  });

  final Widget child;
  final Widget completeLabel;
  final double threshold;
  final Duration resetDelay;
  final VoidCallback? onComplete;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<BeuiSlideActionButton> createState() => _BeuiSlideActionButtonState();
}

class _BeuiSlideActionButtonState extends State<BeuiSlideActionButton>
    with TickerProviderStateMixin {
  late final BeuiSpringValue _x;
  late final BeuiSpringValue _press;
  late final AnimationController _reset;
  late final AnimationController _completeFade;
  final FocusNode _focus = FocusNode();
  double _maxDistance = 0;
  bool _completed = false;
  bool _completedOnce = false;

  @override
  void initState() {
    super.initState();
    _x = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)
      ..attach(this)
      ..addListener(_onTick);
    _press = BeuiSpringValue(value: 1, spec: BeuiSpringSpec.press)
      ..attach(this)
      ..addListener(_onTick);
    _reset = AnimationController(vsync: this, duration: widget.resetDelay)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _resetThumb();
      });
    _completeFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(_onTick);
    _focus.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = beuiReduceMotion(context);
    _x.reducedMotion = reduce;
    _press.reducedMotion = reduce;
  }

  @override
  void didUpdateWidget(BeuiSlideActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetDelay != widget.resetDelay) {
      _reset.duration = widget.resetDelay;
    }
  }

  @override
  void dispose() {
    _reset.dispose();
    _completeFade
      ..removeListener(_onTick)
      ..dispose();
    _x
      ..removeListener(_onTick)
      ..dispose();
    _press
      ..removeListener(_onTick)
      ..dispose();
    _focus
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _moveTo(double target) {
    if (beuiReduceMotion(context)) {
      _x.jump(target);
      return;
    }
    _x.animateTo(target);
  }

  void _resetThumb() {
    _completedOnce = false;
    _completed = false;
    _completeFade.reverse();
    _moveTo(0);
    if (mounted) setState(() {});
  }

  void _complete() {
    if (_completedOnce || _maxDistance == 0) return;
    _completedOnce = true;
    _completed = true;
    _moveTo(_maxDistance);
    _completeFade.forward();
    widget.onComplete?.call();
    _reset
      ..duration = widget.resetDelay
      ..forward(from: 0);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.space) {
      return KeyEventResult.ignored;
    }
    _complete();
    return KeyEventResult.handled;
  }

  double _progress() {
    final distance = math.max(_maxDistance, 1);
    return (_x.value / distance).clamp(0.0, 1.0);
  }

  double _labelOpacity() {
    final distance = math.max(_maxDistance, 1);
    final x = _x.value.clamp(0.0, distance);
    final a = distance * 0.35;
    final b = distance * 0.65;
    if (x <= 0) return 1;
    if (x >= b) return 0;
    if (x <= a) return 1 - 0.25 * (x / a);
    return 0.75 * (1 - (x - a) / (b - a));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final progress = _progress();
    final focused = _focus.hasFocus;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 288, minHeight: 64),
        child: SizedBox(
          width: 288,
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final next = math.max(constraints.maxWidth - 56 - 8, 0.0);
              if (next != _maxDistance) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && next != _maxDistance) {
                    setState(() => _maxDistance = next);
                  }
                });
              }
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Transform.scale(
                          alignment: Alignment.centerLeft,
                          scaleX: progress,
                          child: ColoredBox(color: colors.primary),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 40),
                            child: Opacity(
                              opacity: _labelOpacity(),
                              child: Center(
                                child: DefaultTextStyle(
                                  style: TextStyle(
                                    color: colors.foreground,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  child: widget.child,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: reduce
                                ? (_completed ? 1 : 0)
                                : _completeFade.value,
                            child: Center(
                              child: DefaultTextStyle(
                                style: TextStyle(
                                  color: colors.primaryForeground,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                child: _completed
                                    ? widget.completeLabel
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 4 + _x.value,
                        top: 4,
                        child: Focus(
                          focusNode: _focus,
                          canRequestFocus: widget.enabled,
                          onKeyEvent: _onKey,
                          child: GestureDetector(
                            onHorizontalDragStart: widget.enabled && !_completed
                                ? (_) {
                                    _focus.requestFocus();
                                  }
                                : null,
                            onHorizontalDragUpdate:
                                widget.enabled && !_completed
                                    ? (d) {
                                        final nextX = (_x.value + d.delta.dx)
                                            .clamp(0.0, _maxDistance);
                                        _x.jump(nextX);
                                      }
                                    : null,
                            onHorizontalDragEnd: widget.enabled && !_completed
                                ? (_) {
                                    _press.animateTo(1);
                                    if (_x.value >=
                                        _maxDistance * widget.threshold) {
                                      _complete();
                                    } else {
                                      _moveTo(0);
                                    }
                                  }
                                : null,
                            onTapDown: widget.enabled && !_completed
                                ? (_) {
                                    if (!reduce) _press.animateTo(0.94);
                                  }
                                : null,
                            onTapUp: (_) => _press.animateTo(1),
                            onTapCancel: () {
                              _press.animateTo(1);
                            },
                            child: Transform.scale(
                              scale: _press.value,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _completed
                                      ? colors.background
                                      : colors.primary,
                                  borderRadius: BorderRadius.circular(18),
                                  border: focused
                                      ? Border.all(
                                          color: colors.primary,
                                          width: 2,
                                        )
                                      : null,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1A000000),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: CustomPaint(
                                  size: const Size(20, 20),
                                  painter: _SlideIconPainter(
                                    progress: progress,
                                    color: _completed
                                        ? colors.foreground
                                        : colors.primaryForeground,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SlideIconPainter extends CustomPainter {
  _SlideIconPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const _a = [Offset(8, 5), Offset(15, 12), Offset(8, 19)];
  static const _b = [Offset(7, 8), Offset(12, 14), Offset(17, 10)];
  static const _c = [Offset(5, 12), Offset(10, 17), Offset(19, 7)];

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final from = t < 0.5 ? _a : _b;
    final to = t < 0.5 ? _b : _c;
    final u = t < 0.5 ? t / 0.5 : (t - 0.5) / 0.5;
    final sx = size.width / 24;
    final sy = size.height / 24;
    final path = Path()
      ..moveTo(
        Offset.lerp(from[0], to[0], u)!.dx * sx,
        Offset.lerp(from[0], to[0], u)!.dy * sy,
      )
      ..lineTo(
        Offset.lerp(from[1], to[1], u)!.dx * sx,
        Offset.lerp(from[1], to[1], u)!.dy * sy,
      )
      ..lineTo(
        Offset.lerp(from[2], to[2], u)!.dx * sx,
        Offset.lerp(from[2], to[2], u)!.dy * sy,
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * (2 / 24)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SlideIconPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
