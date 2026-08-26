import 'package:flutter/widgets.dart';

import '../motion/text_shimmer.dart';

/// Compact loading phrase. Port of `ThinkingShimmer`.
class BeuiThinkingShimmer extends StatelessWidget {
  const BeuiThinkingShimmer({
    super.key,
    this.text = 'Thinking…',
    this.duration = const Duration(milliseconds: 1800),
    this.style,
  });

  final String text;
  final Duration duration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return BeuiTextShimmer(text: text, duration: duration, style: style);
  }
}
