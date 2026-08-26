import 'dart:math' as math;

import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

/// Shrinks a preview to fit the card frame. Port of `PreviewFit`.
class CatalogPreviewFit extends StatelessWidget {
  const CatalogPreviewFit({
    super.key,
    required this.child,
    this.hover = false,
    this.maxScale = 0.82,
  });

  final Widget child;
  final bool hover;
  final double maxScale;

  static const stageWidth = 460.0;
  static const hoverLift = 1.05;
  static const minScale = 0.22;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final outerW = math.max(constraints.maxWidth, 1);
        final outerH = math.max(constraints.maxHeight, 1);
        final scale = math
                .min((outerW * 0.94) / stageWidth, (outerH * 0.94) / 260)
                .clamp(minScale, maxScale) *
            (hover ? hoverLift : 1);

        return ColoredBox(
          color: colors.background,
          child: ClipRect(
            child: Center(
              child: Transform.scale(
                scale: scale,
                child: IgnorePointer(
                  child: TickerMode(
                    enabled: false,
                    child: SizedBox(
                      width: stageWidth,
                      child: child,
                    ),
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
