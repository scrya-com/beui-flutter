import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

enum BeuiImageGenerationStatus {
  queued,
  generating,
  refining,
  complete,
  error,
}

/// Stable generated-media canvas. Port of `ImageGeneration`.
class BeuiImageGeneration extends StatelessWidget {
  const BeuiImageGeneration({
    super.key,
    this.child,
    this.status = BeuiImageGenerationStatus.generating,
    this.label,
    this.prompt,
    this.resolution,
    this.aspectRatio = 4 / 3,
    this.onRetry,
    this.showStatus = true,
  });

  final Widget? child;
  final BeuiImageGenerationStatus status;
  final String? label;
  final String? prompt;
  final String? resolution;
  final double aspectRatio;
  final VoidCallback? onRetry;
  final bool showStatus;

  static const _statusText = {
    BeuiImageGenerationStatus.queued: 'Waiting to generate',
    BeuiImageGenerationStatus.generating: 'Generating image',
    BeuiImageGenerationStatus.refining: 'Refining details',
    BeuiImageGenerationStatus.complete: 'Image ready',
    BeuiImageGenerationStatus.error: 'Generation failed',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final media = switch (status) {
      BeuiImageGenerationStatus.queued => (0.0, 4.0, 1.02),
      BeuiImageGenerationStatus.generating => (0.0, 3.0, 1.015),
      BeuiImageGenerationStatus.refining => (0.62, 1.5, 1.005),
      BeuiImageGenerationStatus.complete => (1.0, 0.0, 1.0),
      BeuiImageGenerationStatus.error => (0.28, 2.0, 1.0),
    };
    final overlay = switch (status) {
      BeuiImageGenerationStatus.queued => 1.0,
      BeuiImageGenerationStatus.generating => 1.0,
      BeuiImageGenerationStatus.refining => 0.48,
      BeuiImageGenerationStatus.complete => 0.0,
      BeuiImageGenerationStatus.error => 0.0,
    };

    return Semantics(
      label: label ?? prompt ?? _statusText[status],
      liveRegion: status != BeuiImageGenerationStatus.complete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BeuiRadii.lg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (child != null)
                    Opacity(
                      opacity: media.$1,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: reduce ? 0 : media.$2,
                          sigmaY: reduce ? 0 : media.$2,
                        ),
                        child: Transform.scale(
                          scale: reduce ? 1 : media.$3,
                          child: child,
                        ),
                      ),
                    )
                  else
                    ColoredBox(color: colors.muted),
                  if (overlay > 0.01)
                    Opacity(
                      opacity: overlay,
                      child: ColoredBox(
                        color: colors.background.withValues(alpha: 0.35),
                        child: CustomPaint(
                          painter: _DitherPainter(
                            color: colors.foreground,
                            reduce: reduce,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showStatus)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  BeuiIcon(
                    switch (status) {
                      BeuiImageGenerationStatus.complete => BeuiIcons.check,
                      BeuiImageGenerationStatus.error => BeuiIcons.x,
                      _ => BeuiIcons.sparkles,
                    },
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusText[status]!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                  if (resolution != null)
                    Text(
                      resolution!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.mutedForeground,
                      ),
                    ),
                  if (status == BeuiImageGenerationStatus.error &&
                      onRetry != null)
                    GestureDetector(
                      onTap: onRetry,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: BeuiIcon(
                          BeuiIcons.rotateCcw,
                          size: 14,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DitherPainter extends CustomPainter {
  _DitherPainter({required this.color, required this.reduce});

  final Color color;
  final bool reduce;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 10.0;
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(size.width, size.height) * 0.38;
    final cols = (size.width / gap).ceil() + 1;
    final rows = (size.height / gap).ceil() + 1;
    final ox = (size.width - (cols - 1) * gap) / 2;
    final oy = (size.height - (rows - 1) * gap) / 2;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final ax = ox + c * gap;
        final ay = oy + r * gap;
        final dx = ax - cx;
        final dy = ay - cy;
        final dist = math.sqrt(dx * dx + dy * dy);
        final proximity = math.max(0.0, 1 - dist / radius);
        final influence = proximity * proximity * (3 - 2 * proximity);
        paint.color = color.withValues(alpha: 0.17 + influence * 0.72);
        canvas.drawCircle(
          Offset(ax, ay),
          reduce ? 0.65 : 0.65 + influence * 0.85,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DitherPainter old) =>
      old.color != color || old.reduce != reduce;
}
