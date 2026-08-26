import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

enum BeuiPullToRefreshStatus { idle, pulling, ready, refreshing }

/// Native-feeling refresh container with resisted pull and async refresh.
/// Port of `components/motion/pull-to-refresh.tsx`.
class BeuiPullToRefresh extends StatefulWidget {
  const BeuiPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.refreshing = false,
    this.enabled = true,
    this.threshold = 76,
    this.maxPull = 132,
    this.holdDistance = 68,
    this.pullingLabel = 'Pull to refresh',
    this.releaseLabel = 'Release to refresh',
    this.refreshingLabel = 'Refreshing',
    this.semanticLabel = 'Refreshable content',
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final bool refreshing;
  final bool enabled;
  final double threshold;
  final double maxPull;
  final double holdDistance;
  final String pullingLabel;
  final String releaseLabel;
  final String refreshingLabel;
  final String semanticLabel;

  @override
  State<BeuiPullToRefresh> createState() => _BeuiPullToRefreshState();
}

double _resistedDistance(double distance, double maxPull) {
  return maxPull * (1 - math.exp(-math.max(0, distance) / maxPull));
}

class _BeuiPullToRefreshState extends State<BeuiPullToRefresh>
    with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  late final BeuiSpringValue _pull;
  late final AnimationController _loop;
  BeuiPullToRefreshStatus _status = BeuiPullToRefreshStatus.idle;
  bool _internalRefreshing = false;

  Offset? _start;
  int? _pointer;
  bool _active = false;
  bool _pulling = false;

  bool get _isRefreshing => widget.refreshing || _internalRefreshing;

  double get _threshold => math.max(24, widget.threshold);
  double get _limit => math.max(widget.maxPull, _threshold + 24);
  double get _rest =>
      math.min(math.max(0, widget.holdDistance), _threshold);

  @override
  void initState() {
    super.initState();
    _pull = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.panel)
      ..attach(this)
      ..addListener(_onPull);
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  void _onPull() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pull.reducedMotion = beuiReduceMotion(context);
  }

  @override
  void didUpdateWidget(BeuiPullToRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isRefreshing) {
      _setStatus(BeuiPullToRefreshStatus.refreshing);
      _settle(_rest);
      _loop.repeat();
    } else if (_status == BeuiPullToRefreshStatus.refreshing) {
      _setStatus(BeuiPullToRefreshStatus.idle);
      _settle(0);
      _loop
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pull
      ..removeListener(_onPull)
      ..dispose();
    _loop.dispose();
    super.dispose();
  }

  void _setStatus(BeuiPullToRefreshStatus next) {
    if (_status == next) return;
    _status = next;
    if (mounted) setState(() {});
  }

  void _settle(double target) {
    if (beuiReduceMotion(context)) {
      _pull.jump(target);
      return;
    }
    _pull.animateTo(target);
  }

  void _updatePull(double distance) {
    if (!widget.enabled || _isRefreshing) return;
    final next = _resistedDistance(distance, _limit);
    _pull.jump(next);
    _setStatus(
      next >= _threshold
          ? BeuiPullToRefreshStatus.ready
          : BeuiPullToRefreshStatus.pulling,
    );
  }

  Future<void> _runRefresh() async {
    if (!widget.enabled || _isRefreshing) return;
    _internalRefreshing = true;
    _setStatus(BeuiPullToRefreshStatus.refreshing);
    _settle(_rest);
    _loop.repeat();
    try {
      await widget.onRefresh();
    } finally {
      _internalRefreshing = false;
      if (!widget.refreshing) {
        _setStatus(BeuiPullToRefreshStatus.idle);
        _settle(0);
        _loop
          ..stop()
          ..value = 0;
      }
    }
  }

  void _finishPull() {
    final shouldRefresh =
        _pull.value >= _threshold && widget.enabled && !_isRefreshing;
    _active = false;
    _pulling = false;
    _start = null;
    _pointer = null;
    if (shouldRefresh) {
      _runRefresh();
      return;
    }
    _setStatus(BeuiPullToRefreshStatus.idle);
    _settle(0);
  }

  bool get _atTop => !_scroll.hasClients || _scroll.offset <= 0;

  void _onPointerDown(PointerDownEvent e) {
    if (e.kind == PointerDeviceKind.trackpad) return;
    if (!_atTop || !widget.enabled || _isRefreshing) return;
    _active = true;
    _start = e.position;
    _pointer = e.pointer;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_active || _pointer != e.pointer || _start == null) return;
    final delta = e.position - _start!;
    if (!_atTop || delta.dy < 0) {
      _active = false;
      _pulling = false;
      return;
    }
    if (delta.dx.abs() > delta.dy) return;
    _pulling = true;
    _updatePull(delta.dy);
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_pointer == e.pointer && (_active || _pulling)) _finishPull();
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (_pointer == e.pointer && (_active || _pulling)) _finishPull();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final y = _pull.value;
    final progress = (y / _threshold).clamp(0.0, 1.0);
    final indicatorOpacity = y <= 0
        ? 0.0
        : y < 10
            ? 0.45 * (y / 10)
            : 1.0;
    final indicatorScale = reduce ? 1.0 : 0.86 + 0.14 * progress;
    final label = switch (_status) {
      BeuiPullToRefreshStatus.refreshing => widget.refreshingLabel,
      BeuiPullToRefreshStatus.ready => widget.releaseLabel,
      _ => widget.pullingLabel,
    };

    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: Stack(
          children: [
            Transform.translate(
              offset: reduce ? Offset.zero : Offset(0, y),
              child: ColoredBox(
                color: colors.background,
                child: SingleChildScrollView(
                  controller: _scroll,
                  physics: _pulling
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                  child: widget.child,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 68,
              child: IgnorePointer(
                child: Opacity(
                  opacity: indicatorOpacity.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.background,
                          colors.background.withValues(alpha: 0.95),
                          colors.background.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: Transform.scale(
                      scale: indicatorScale,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RefreshBuddy(
                            progress: progress,
                            status: _status,
                            reduce: reduce,
                            loop: _loop,
                            color: colors.foreground,
                            muted: colors.mutedForeground,
                            background: colors.background,
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 16,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              switchInCurve: BeuiCurves.easeOut,
                              switchOutCurve: BeuiCurves.easeOut,
                              transitionBuilder: (child, anim) {
                                final dy = reduce ? 0.0 : 3.0;
                                return FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: Offset(0, dy / 16),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                label,
                                key: ValueKey(_status),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ),
                          ),
                        ],
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
  }
}

class _RefreshBuddy extends StatelessWidget {
  const _RefreshBuddy({
    required this.progress,
    required this.status,
    required this.reduce,
    required this.loop,
    required this.color,
    required this.muted,
    required this.background,
  });

  final double progress;
  final BeuiPullToRefreshStatus status;
  final bool reduce;
  final Animation<double> loop;
  final Color color;
  final Color muted;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final ready = status == BeuiPullToRefreshStatus.ready;
    final refreshing = status == BeuiPullToRefreshStatus.refreshing;
    final lift = reduce ? 0.0 : -7 + 7 * progress;
    final tilt = reduce ? 0.0 : -10 + 10 * progress;
    final stretch = reduce
        ? 1.0
        : progress < 0.55
            ? 0.68 + (1.1 - 0.68) * (progress / 0.55)
            : 1.1 + (0.92 - 1.1) * ((progress - 0.55) / 0.45);

    return AnimatedBuilder(
      animation: loop,
      builder: (context, child) {
        final t = loop.value;
        final bounceY = refreshing && !reduce ? -2 * math.sin(t * math.pi * 2) : 0.0;
        final wobble =
            refreshing && !reduce ? -3 + 6 * math.sin(t * math.pi * 2) : 0.0;
        return Transform.translate(
          offset: Offset(0, lift + bounceY),
          child: Transform.rotate(
            angle: (tilt + wobble) * math.pi / 180,
            child: Transform.scale(
              alignment: Alignment.bottomCenter,
              scaleY: stretch,
              scaleX: ready && !refreshing && !reduce ? 1.08 : 1,
              child: SizedBox(
                width: 36,
                height: 36,
                child: CustomPaint(
                  painter: _BuddyPainter(
                    progress: progress,
                    status: status,
                    reduce: reduce,
                    loop: t,
                    color: color,
                    muted: muted,
                    background: background,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BuddyPainter extends CustomPainter {
  _BuddyPainter({
    required this.progress,
    required this.status,
    required this.reduce,
    required this.loop,
    required this.color,
    required this.muted,
    required this.background,
  });

  final double progress;
  final BeuiPullToRefreshStatus status;
  final bool reduce;
  final double loop;
  final Color color;
  final Color muted;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final ready = status == BeuiPullToRefreshStatus.ready;
    final refreshing = status == BeuiPullToRefreshStatus.refreshing;
    final spinnerOpacity = (ready || refreshing) ? 1.0 : 0.0;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    if (refreshing && !reduce) {
      canvas.rotate(loop * math.pi * 2);
    } else if (!reduce && !ready) {
      canvas.rotate(-35 * math.pi / 180);
    }

    final arc = Paint()
      ..color = muted.withValues(alpha: spinnerOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: 15.5),
      -math.pi / 2,
      math.pi * 0.7,
      false,
      arc,
    );
    canvas.drawCircle(
      Offset(math.cos(-0.2) * 15.5, math.sin(-0.2) * 15.5),
      2.2,
      Paint()..color = color.withValues(alpha: spinnerOpacity),
    );
    canvas.restore();

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(7, 7, 22, 22),
      const Radius.circular(9),
    );
    canvas.drawRRect(body, Paint()..color = color);

    canvas.save();
    canvas.translate(18, 16);
    var eyeScale = 1.0;
    if (refreshing && !reduce) {
      if (loop > 0.4 && loop < 0.55) {
        eyeScale = 0.15 + 0.85 * (1 - ((loop - 0.4) / 0.15));
        if (loop > 0.47) {
          eyeScale = 0.15 + 0.85 * ((loop - 0.47) / 0.08);
        }
      }
    } else if (ready && !reduce) {
      eyeScale = 1.18;
    }
    canvas.scale(1, eyeScale);
    final eye = Paint()..color = background;
    canvas.drawCircle(const Offset(-3.8, 0), 1.45, eye);
    canvas.drawCircle(const Offset(3.8, 0), 1.45, eye);
    canvas.restore();

    final mouth = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    if (refreshing) {
      canvas.drawCircle(
        const Offset(18, 21),
        1.6,
        Paint()..color = background,
      );
    } else if (ready) {
      canvas.drawArc(
        const Rect.fromLTWH(14, 19, 8, 5),
        0.15,
        math.pi - 0.3,
        false,
        mouth,
      );
    } else {
      canvas.drawLine(const Offset(14.5, 21), const Offset(21.5, 21), mouth);
    }
  }

  @override
  bool shouldRepaint(covariant _BuddyPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.status != status ||
      oldDelegate.loop != loop ||
      oldDelegate.color != color;
}
