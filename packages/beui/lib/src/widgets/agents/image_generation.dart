import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import '../motion/button.dart';

enum BeuiImageGenerationStatus {
  queued,
  generating,
  refining,
  complete,
  error,
}

enum BeuiImageGenerationSize { compact, fluid }

class _MediaLook {
  const _MediaLook(this.opacity, this.blur, this.saturate, this.scale);
  final double opacity;
  final double blur;
  final double saturate;
  final double scale;
}

const _kStatusText = {
  BeuiImageGenerationStatus.queued: 'Waiting to generate',
  BeuiImageGenerationStatus.generating: 'Generating image',
  BeuiImageGenerationStatus.refining: 'Refining details',
  BeuiImageGenerationStatus.complete: 'Image ready',
  BeuiImageGenerationStatus.error: 'Generation failed',
};

const _kMedia = {
  BeuiImageGenerationStatus.queued: _MediaLook(0, 4, 0.75, 1.02),
  BeuiImageGenerationStatus.generating: _MediaLook(0, 3, 0.85, 1.015),
  BeuiImageGenerationStatus.refining: _MediaLook(0.62, 1.5, 0.95, 1.005),
  BeuiImageGenerationStatus.complete: _MediaLook(1, 0, 1, 1),
  BeuiImageGenerationStatus.error: _MediaLook(0.28, 2, 0.5, 1),
};

const _kOverlay = {
  BeuiImageGenerationStatus.queued: 1.0,
  BeuiImageGenerationStatus.generating: 1.0,
  BeuiImageGenerationStatus.refining: 0.48,
  BeuiImageGenerationStatus.complete: 0.0,
  BeuiImageGenerationStatus.error: 0.0,
};

ColorFilter _saturate(double s) {
  final inv = 1 - s;
  return ColorFilter.matrix(<double>[
    0.213 * inv + s, 0.715 * inv, 0.072 * inv, 0, 0,
    0.213 * inv, 0.715 * inv + s, 0.072 * inv, 0, 0,
    0.213 * inv, 0.715 * inv, 0.072 * inv + s, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

/// Stable generated-media canvas. Port of `ImageGeneration`.
class BeuiImageGeneration extends StatelessWidget {
  const BeuiImageGeneration({
    super.key,
    this.child,
    this.status = BeuiImageGenerationStatus.generating,
    this.label,
    this.prompt,
    this.resolution = '1024 × 1024',
    this.aspectRatio = 1,
    this.size = BeuiImageGenerationSize.compact,
    this.interactive = true,
    this.statusText,
    this.showStatus = true,
    this.onRetry,
  });

  final Widget? child;
  final BeuiImageGenerationStatus status;
  final String? label;
  final String? prompt;
  final String? resolution;
  final double aspectRatio;
  final BeuiImageGenerationSize size;
  final bool interactive;
  final String? statusText;
  final bool showStatus;
  final VoidCallback? onRetry;

  bool get _active =>
      status == BeuiImageGenerationStatus.queued ||
      status == BeuiImageGenerationStatus.generating ||
      status == BeuiImageGenerationStatus.refining;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final look = _kMedia[status]!;
    final resolvedStatus = statusText ?? _kStatusText[status]!;
    final resolvedLabel = label ??
        (prompt != null ? '$resolvedStatus: $prompt' : resolvedStatus);
    final duration = Duration(milliseconds: reduce ? 0 : 400);

    Widget canvas = AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BeuiRadii.lg),
        child: ColoredBox(
          color: colors.muted,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: look.opacity, end: look.opacity),
                duration: duration,
                curve: BeuiCurves.easeOut,
                builder: (context, opacity, _) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: look.scale, end: look.scale),
                    duration: duration,
                    curve: BeuiCurves.easeOut,
                    builder: (context, scale, _) {
                      Widget media = child ?? const SizedBox.expand();
                      if (!reduce) {
                        media = ColorFiltered(
                          colorFilter: _saturate(look.saturate),
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: look.blur,
                              sigmaY: look.blur,
                            ),
                            child: Transform.scale(scale: scale, child: media),
                          ),
                        );
                      }
                      return Opacity(opacity: opacity, child: media);
                    },
                  );
                },
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: _kOverlay[status],
                  end: _kOverlay[status],
                ),
                duration: duration,
                curve: BeuiCurves.easeOut,
                builder: (context, overlay, _) {
                  if (overlay < 0.01 && !_active) {
                    return const SizedBox.shrink();
                  }
                  return Opacity(
                    opacity: overlay,
                    child: _DitherField(
                      interactive: interactive,
                      reduce: reduce,
                      active: _active,
                    ),
                  );
                },
              ),
              if (resolution != null && resolution!.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.background.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(BeuiRadii.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        resolution!,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: colors.mutedForeground,
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

    if (size == BeuiImageGenerationSize.compact) {
      canvas = Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 208),
          child: canvas,
        ),
      );
    }

    return Semantics(
      image: true,
      label: resolvedLabel,
      liveRegion: _active,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          canvas,
          if (showStatus || prompt != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showStatus)
                    Row(
                      children: [
                        _DitherMark(status: status, reduce: reduce),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: reduce ? 0 : 150),
                            switchInCurve: BeuiCurves.easeOut,
                            switchOutCurve: BeuiCurves.easeOut,
                            layoutBuilder: (current, previous) {
                              return Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  ...previous,
                                  ?current,
                                ],
                              );
                            },
                            transitionBuilder: (child, anim) {
                              return FadeTransition(
                                opacity: anim,
                                child: reduce
                                    ? child
                                    : SlideTransition(
                                        position: Tween(
                                          begin: const Offset(0, 0.15),
                                          end: Offset.zero,
                                        ).animate(anim),
                                        child: child,
                                      ),
                              );
                            },
                            child: Text(
                              resolvedStatus,
                              key: ValueKey(resolvedStatus),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: status == BeuiImageGenerationStatus.error
                                    ? colors.destructive
                                    : colors.foreground,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (prompt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '“$prompt”',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (status == BeuiImageGenerationStatus.error && onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BeuiButton(
                  variant: BeuiButtonVariant.ghost,
                  onPressed: onRetry,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      BeuiIcon(BeuiIcons.rotateCcw, size: 16),
                      Text('Try again'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DitherMark extends StatefulWidget {
  const _DitherMark({required this.status, required this.reduce});
  final BeuiImageGenerationStatus status;
  final bool reduce;

  @override
  State<_DitherMark> createState() => _DitherMarkState();
}

class _DitherMarkState extends State<_DitherMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_DitherMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final live = TickerMode.valuesOf(context).enabled &&
        !widget.reduce &&
        widget.status != BeuiImageGenerationStatus.complete &&
        widget.status != BeuiImageGenerationStatus.error;
    if (live && !_spin.isAnimating) _spin.repeat();
    if (!live && _spin.isAnimating) _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == BeuiImageGenerationStatus.complete) {
      return const BeuiIcon(BeuiIcons.check, size: 14);
    }
    if (widget.status == BeuiImageGenerationStatus.error) {
      return BeuiIcon(
        BeuiIcons.alertCircle,
        size: 14,
        color: context.beuiColors.destructive,
      );
    }
    final color = DefaultTextStyle.of(context).style.color ??
        context.beuiColors.foreground;
    Widget cell(double a) => Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: a),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
    Widget mark = SizedBox(
      width: 14,
      height: 14,
      child: Column(
        spacing: 2,
        children: [
          Expanded(child: Row(spacing: 2, children: [cell(1), cell(0.55)])),
          Expanded(child: Row(spacing: 2, children: [cell(0.55), cell(1)])),
        ],
      ),
    );
    if (!widget.reduce) {
      mark = AnimatedBuilder(
        animation: _spin,
        builder: (context, child) {
          return Transform.rotate(
            angle: _spin.value * math.pi * 2,
            child: child,
          );
        },
        child: mark,
      );
    }
    return mark;
  }
}

class _DitherField extends StatefulWidget {
  const _DitherField({
    required this.interactive,
    required this.reduce,
    required this.active,
  });

  final bool interactive;
  final bool reduce;
  final bool active;

  @override
  State<_DitherField> createState() => _DitherFieldState();
}

class _DitherFieldState extends State<_DitherField>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _elapsed = Duration.zero;
  Offset _pointer = Offset.zero;
  Offset _target = Offset.zero;
  bool _inside = false;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      _elapsed = d;
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_DitherField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final live = TickerMode.valuesOf(context).enabled &&
        widget.active &&
        !widget.reduce;
    if (live && !(_ticker?.isActive ?? false)) _ticker?.start();
    if (!live && (_ticker?.isActive ?? false)) _ticker?.stop();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.beuiColors.foreground;
    return ColoredBox(
      color: context.beuiColors.muted,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = Size(constraints.maxWidth, constraints.maxHeight);
          if (_pointer == Offset.zero) {
            _pointer = Offset(_size.width / 2, _size.height / 2);
            _target = _pointer;
          }
          final pointer = _stepPointer();
          _pointer = pointer;
          return MouseRegion(
            onExit: (_) => _inside = false,
            child: Listener(
            onPointerHover: (e) {
              if (!widget.interactive ||
                  !beuiHoverCapable(context) ||
                  widget.reduce) {
                return;
              }
              _inside = true;
              _target = e.localPosition;
            },
            onPointerMove: (e) {
              if (!widget.interactive ||
                  !beuiHoverCapable(context) ||
                  widget.reduce) {
                return;
              }
              _inside = true;
              _target = e.localPosition;
            },
            child: CustomPaint(
              painter: _DitherPainter(
                color: color,
                reduce: widget.reduce,
                timeMs: _elapsed.inMilliseconds.toDouble(),
                pointer: pointer,
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  Offset _stepPointer() {
    final t = _elapsed.inMilliseconds.toDouble();
    var target = _target;
    if (!_inside) {
      target = Offset(
        _size.width / 2 +
            (widget.reduce ? 0 : math.sin(t / 1700) * _size.width * 0.12),
        _size.height / 2 +
            (widget.reduce ? 0 : math.cos(t / 2100) * _size.height * 0.1),
      );
    }
    final follow = widget.reduce ? 1.0 : (_inside ? 0.16 : 0.045);
    return Offset(
      _pointer.dx + (target.dx - _pointer.dx) * follow,
      _pointer.dy + (target.dy - _pointer.dy) * follow,
    );
  }
}

class _DitherPainter extends CustomPainter {
  _DitherPainter({
    required this.color,
    required this.reduce,
    required this.timeMs,
    required this.pointer,
  });

  final Color color;
  final bool reduce;
  final double timeMs;
  final Offset pointer;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 10.0;
    final paint = Paint()..style = PaintingStyle.fill;
    final radius = math.min(size.width, size.height) * 0.38;
    final cols = (size.width / gap).ceil() + 1;
    final rows = (size.height / gap).ceil() + 1;
    final ox = (size.width - (cols - 1) * gap) / 2;
    final oy = (size.height - (rows - 1) * gap) / 2;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final ax = ox + c * gap;
        final ay = oy + r * gap;
        final dx = ax - pointer.dx;
        final dy = ay - pointer.dy;
        final dist = math.sqrt(dx * dx + dy * dy);
        final proximity = math.max(0.0, 1 - dist / radius);
        final influence = proximity * proximity * (3 - 2 * proximity);
        final displacement = influence * influence * 9;
        final dirX = dist > 0 ? dx / dist : 0.0;
        final dirY = dist > 0 ? dy / dist : 0.0;
        paint.color = color.withValues(alpha: 0.17 + influence * 0.72);
        canvas.drawCircle(
          Offset(ax + dirX * displacement, ay + dirY * displacement),
          0.65 + influence * 0.85,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DitherPainter old) =>
      old.color != color ||
      old.timeMs != timeMs ||
      old.pointer != pointer ||
      old.reduce != reduce;
}
