import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../physics/spring.dart';
import '../../tokens/colors.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

enum BeuiAnimatedBadgeStatus {
  neutral,
  info,
  success,
  warning,
  danger,
  loading,
}

enum BeuiAnimatedBadgeSize { sm, md }

const _kIconY = BeuiSpringSpec(stiffness: 210, damping: 24, mass: 0.85);
const _kIconScale = BeuiSpringSpec(stiffness: 250, damping: 24, mass: 0.75);
const _kLayout = BeuiSpringSpec(stiffness: 420, damping: 30, mass: 0.7);

/// Status pill with a rolling icon/label. Port of `animated-badge.tsx`.
class BeuiAnimatedBadge extends StatefulWidget {
  const BeuiAnimatedBadge({
    super.key,
    this.status = BeuiAnimatedBadgeStatus.neutral,
    this.size = BeuiAnimatedBadgeSize.md,
    this.label,
    this.child,
    this.icon,
    this.showIcon = true,
    this.pulse,
    this.contentKey,
    this.semanticLabel,
  });

  final BeuiAnimatedBadgeStatus status;
  final BeuiAnimatedBadgeSize size;

  /// Rolling text. Takes precedence over [child] for the label slot.
  final String? label;
  final Widget? child;
  final Widget? icon;
  final bool showIcon;

  /// Defaults to on when [status] is [BeuiAnimatedBadgeStatus.loading].
  final bool? pulse;
  final Object? contentKey;
  final String? semanticLabel;

  @override
  State<BeuiAnimatedBadge> createState() => _BeuiAnimatedBadgeState();
}

class _BeuiAnimatedBadgeState extends State<BeuiAnimatedBadge>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _elapsed = Duration.zero;
  Duration? _lastTick;

  late BeuiAnimatedBadgeStatus _status = widget.status;
  BeuiAnimatedBadgeStatus? _prevStatus;
  Duration _statusAt = Duration.zero;

  late Object _contentId = _idFor(widget);
  Widget? _prevLabel;
  Duration _labelAt = Duration.zero;

  bool get _pulse =>
      widget.pulse ?? widget.status == BeuiAnimatedBadgeStatus.loading;

  static Object _idFor(BeuiAnimatedBadge w) =>
      w.contentKey ?? w.label ?? w.status;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(BeuiAnimatedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _prevStatus = _status;
      _status = widget.status;
      _statusAt = _elapsed;
    }
    final nextId = _idFor(widget);
    if (nextId != _contentId) {
      _prevLabel = _labelChild(oldWidget);
      _contentId = nextId;
      _labelAt = _elapsed;
    }
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final last = _lastTick ?? elapsed;
    _lastTick = elapsed;
    _elapsed += elapsed - last;
    if (mounted) setState(() {});
    if (!_wantsTick) {
      _lastTick = null;
      _ticker?.stop();
    }
  }

  bool get _wantsTick {
    if (!TickerMode.valuesOf(context).enabled) return false;
    if (beuiReduceMotion(context)) return false;
    if (_pulse) return true;
    if (widget.status == BeuiAnimatedBadgeStatus.loading) return true;
    final sec = _elapsed.inMicroseconds / 1e6;
    if (_prevStatus != null && sec - _statusAt.inMicroseconds / 1e6 < 0.5) {
      return true;
    }
    if (_prevLabel != null && sec - _labelAt.inMicroseconds / 1e6 < 0.5) {
      return true;
    }
    return false;
  }

  void _syncTicker() {
    final live = _wantsTick;
    if (live) {
      if (!(_ticker?.isActive ?? false)) {
        _lastTick = null;
        _ticker?.start();
      }
    } else if (_ticker?.isActive ?? false) {
      _lastTick = null;
      _ticker?.stop();
    }
  }

  double get _seconds => _elapsed.inMicroseconds / 1e6;

  Widget? _labelChild(BeuiAnimatedBadge w) {
    if (w.label != null) return Text(w.label!);
    return w.child;
  }

  ({double h, double gap, double px, double font, double icon}) get _metrics {
    return switch (widget.size) {
      BeuiAnimatedBadgeSize.sm => (
          h: 24.0,
          gap: 6.0,
          px: 8.0,
          font: 11.0,
          icon: 12.0,
        ),
      BeuiAnimatedBadgeSize.md => (
          h: 32.0,
          gap: 8.0,
          px: 12.0,
          font: 12.0,
          icon: 14.0,
        ),
    };
  }

  ({Color border, Color bg, Color fg}) _colors(BeuiColors c) {
    return switch (widget.status) {
      BeuiAnimatedBadgeStatus.neutral => (
          border: c.border,
          bg: c.card,
          fg: c.mutedForeground,
        ),
      BeuiAnimatedBadgeStatus.info ||
      BeuiAnimatedBadgeStatus.loading => (
          border: c.primary.withValues(alpha: 0.3),
          bg: c.primary.withValues(alpha: 0.1),
          fg: c.primary,
        ),
      BeuiAnimatedBadgeStatus.success => (
          border: c.success.withValues(alpha: 0.3),
          bg: c.success.withValues(alpha: 0.1),
          fg: c.success,
        ),
      BeuiAnimatedBadgeStatus.warning => (
          border: c.warning.withValues(alpha: 0.3),
          bg: c.warning.withValues(alpha: 0.1),
          fg: c.warning,
        ),
      BeuiAnimatedBadgeStatus.danger => (
          border: c.destructive.withValues(alpha: 0.3),
          bg: c.destructive.withValues(alpha: 0.1),
          fg: c.destructive,
        ),
    };
  }

  BeuiIconPainter _iconFor(BeuiAnimatedBadgeStatus status) {
    return switch (status) {
      BeuiAnimatedBadgeStatus.neutral => BeuiIcons.circle,
      BeuiAnimatedBadgeStatus.info => _infoIcon,
      BeuiAnimatedBadgeStatus.success => BeuiIcons.check,
      BeuiAnimatedBadgeStatus.warning => _warningIcon,
      BeuiAnimatedBadgeStatus.danger => BeuiIcons.x,
      BeuiAnimatedBadgeStatus.loading => BeuiIcons.loader,
    };
  }

  Widget _statusIcon(BeuiAnimatedBadgeStatus status, Color fg, double size) {
    final icon = widget.icon ??
        BeuiIcon(_iconFor(status), size: size, color: fg);
    final reduce = beuiReduceMotion(context);
    if (status == BeuiAnimatedBadgeStatus.loading &&
        !reduce &&
        widget.icon == null) {
      return Transform.rotate(
        angle: (_seconds % 1.0) * 2 * math.pi,
        child: icon,
      );
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final tone = _colors(colors);
    final m = _metrics;
    final reduce = beuiReduceMotion(context);
    final pulseOn = _pulse && !reduce;
    final seconds = _seconds;

    final label = _labelChild(widget);

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      liveRegion: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BeuiRadii.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: BeuiCurves.easeOut,
          height: m.h,
          padding: EdgeInsets.symmetric(horizontal: m.px),
          decoration: BoxDecoration(
            color: tone.bg,
            borderRadius: BorderRadius.circular(BeuiRadii.pill),
            border: Border.all(color: tone.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (pulseOn)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.scale(
                      scale: lerpDouble(
                        0.94,
                        1.08,
                        _pingPong(seconds, duration: 1.6),
                      )!,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tone.fg.withValues(
                            alpha: lerpDouble(
                              0.08,
                              0.16,
                              _pingPong(seconds, duration: 1.6),
                            )!,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              AnimatedSize(
                duration: beuiSpringSettleDuration(_kLayout),
                curve: BeuiCurves.easeOut,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: m.gap,
                  children: [
                  if (widget.showIcon)
                    _RollLayer(
                      elapsed: seconds - _statusAt.inMicroseconds / 1e6,
                      outgoing: _prevStatus == null || reduce
                          ? null
                          : _statusIcon(_prevStatus!, tone.fg, m.icon),
                      incoming: _statusIcon(_status, tone.fg, m.icon),
                      reduce: reduce,
                      icon: true,
                    ),
                  if (label != null)
                    DefaultTextStyle(
                      style: TextStyle(
                        color: tone.fg,
                        fontSize: m.font,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      child: _RollLayer(
                        elapsed: seconds - _labelAt.inMicroseconds / 1e6,
                        outgoing: _prevLabel == null || reduce
                            ? null
                            : DefaultTextStyle(
                                style: TextStyle(
                                  color: tone.fg,
                                  fontSize: m.font,
                                  fontWeight: FontWeight.w500,
                                  height: 1,
                                ),
                                child: _prevLabel!,
                              ),
                        incoming: label,
                        reduce: reduce,
                        icon: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RollLayer extends StatelessWidget {
  const _RollLayer({
    required this.elapsed,
    required this.incoming,
    required this.reduce,
    required this.icon,
    this.outgoing,
  });

  final double elapsed;
  final Widget incoming;
  final Widget? outgoing;
  final bool reduce;
  final bool icon;

  @override
  Widget build(BuildContext context) {
    if (reduce || elapsed < 0 || outgoing == null) {
      return incoming;
    }
    final showOut = elapsed < (icon ? 0.22 : 0.2);
    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showOut)
            IgnorePointer(
              child: _roll(
                child: outgoing!,
                t: (elapsed / (icon ? 0.22 : 0.2)).clamp(0.0, 1.0),
                enter: false,
                icon: icon,
              ),
            ),
          _roll(
            child: incoming,
            t: elapsed,
            enter: true,
            icon: icon,
          ),
        ],
      ),
    );
  }

  Widget _roll({
    required Widget child,
    required double t,
    required bool enter,
    required bool icon,
  }) {
    if (!enter) {
      final u = BeuiCurves.easeOut.transform(t);
      final y = icon ? -0.80 * u : -0.85 * u;
      final opacity = lerpDouble(1, 0.5, u)!;
      final scale = icon ? lerpDouble(1, 0.96, u)! : 1.0;
      final rot = icon ? (8 * math.pi / 180) * u : 0.0;
      final blur = 6 * u;
      return _paint(
        child: child,
        y: y,
        opacity: opacity,
        scale: scale,
        rotation: rot,
        blur: blur,
      );
    }

    final yT = beuiSpringEaseSpec(t, _kIconY).clamp(0.0, 1.2);
    final y = (icon ? 0.80 : 0.85) * (1 - yT);
    final scaleT = icon
        ? beuiSpringEaseSpec(t, _kIconScale).clamp(0.0, 1.2)
        : 1.0;
    final scale = icon ? lerpDouble(0.92, 1, scaleT)! : 1.0;
    final rotT = BeuiCurves.easeOut.transform((t / 0.28).clamp(0.0, 1.0));
    final rot = icon ? (-8 * math.pi / 180) * (1 - rotT) : 0.0;
    final fadeDur = icon ? 0.28 : 0.3;
    final opacity = lerpDouble(
      icon ? 0.72 : 0.76,
      1,
      BeuiCurves.easeOut.transform((t / fadeDur).clamp(0.0, 1.0)),
    )!;
    final blur =
        6 * (1 - BeuiCurves.easeOut.transform((t / 0.42).clamp(0.0, 1.0)));
    return _paint(
      child: child,
      y: y,
      opacity: opacity,
      scale: scale,
      rotation: rot,
      blur: blur,
    );
  }

  Widget _paint({
    required Widget child,
    required double y,
    required double opacity,
    required double scale,
    required double rotation,
    required double blur,
  }) {
    Widget layer = child;
    if (blur > 0.2) {
      layer = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blur.clamp(0.0, 10.0),
          sigmaY: blur.clamp(0.0, 10.0),
        ),
        child: layer,
      );
    }
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: FractionalTranslation(
        translation: Offset(0, y),
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(scale: scale, child: layer),
        ),
      ),
    );
  }
}

double _pingPong(double seconds, {required double duration, double delay = 0}) {
  final local = seconds - delay;
  if (local <= 0) return 0;
  final u = (local % duration) / duration;
  final half = u < 0.5 ? u * 2 : (u - 0.5) * 2;
  final eased = BeuiCurves.easeInOut.transform(half);
  return u < 0.5 ? eased : 1 - eased;
}

void _infoIcon(Canvas c, Size s, Paint p) {
  c.drawCircle(const Offset(12, 12), 9, p);
  c.drawLine(const Offset(12, 10), const Offset(12, 16), p);
  c.drawCircle(const Offset(12, 7.5), 0.6, p);
}

void _warningIcon(Canvas c, Size s, Paint p) {
  c.drawPath(
    Path()
      ..moveTo(12, 3)
      ..lineTo(21, 20)
      ..lineTo(3, 20)
      ..close(),
    p,
  );
  c.drawLine(const Offset(12, 9), const Offset(12, 14), p);
  c.drawCircle(const Offset(12, 17), 0.6, p);
}
