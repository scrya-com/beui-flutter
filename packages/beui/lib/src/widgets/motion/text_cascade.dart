import 'package:flutter/widgets.dart';

import 'action_swap.dart';

/// Letter-by-letter slot roll for standalone text.
/// Port of `components/motion/text-cascade.tsx`.
class BeuiTextCascade extends StatelessWidget {
  const BeuiTextCascade({
    super.key,
    required this.text,
    this.style,
  });

  /// Current text. Changing it cascades the letters to the new value.
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    Widget child = BeuiActionSwapText(
      value: text,
      text: text,
      animation: BeuiActionSwapAnimation.cascade,
    );
    if (style != null) {
      child = DefaultTextStyle.merge(style: style!, child: child);
    }
    return child;
  }
}
