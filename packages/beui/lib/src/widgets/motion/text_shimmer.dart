import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/theme.dart';

/// Gradient sweep across text. Port of `components/motion/text-shimmer.tsx`.
class BeuiTextShimmer extends StatefulWidget {
  const BeuiTextShimmer({
    super.key,
    required this.text,
    this.duration = const Duration(milliseconds: 2500),
    this.style,
  });

  final String text;
  final Duration duration;
  final TextStyle? style;

  @override
  State<BeuiTextShimmer> createState() => _BeuiTextShimmerState();
}

class _BeuiTextShimmerState extends State<BeuiTextShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void didUpdateWidget(BeuiTextShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _c.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final style = (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
      fontWeight: widget.style?.fontWeight ?? FontWeight.w500,
    );
    if (beuiReduceMotion(context)) {
      return Text(widget.text, style: style.copyWith(color: colors.foreground));
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-2 + 4 * t, 0),
              end: Alignment(0 + 4 * t, 0),
              colors: [
                colors.mutedForeground,
                colors.foreground,
                colors.mutedForeground,
              ],
              stops: const [0.3, 0.5, 0.7],
            ).createShader(rect);
          },
          child: Text(widget.text, style: style.copyWith(color: const Color(0xFFFFFFFF))),
        );
      },
    );
  }
}
