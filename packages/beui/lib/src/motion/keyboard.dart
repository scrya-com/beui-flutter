import 'package:flutter/widgets.dart';

import '../tokens/ease.dart';

/// Extra padding [EditableText] keeps above the keyboard inside a [Scrollable].
const beuiKeyboardScrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 72);

/// Pads [child] by the current IME inset so a bottom composer stays visible.
///
/// Use this around a page column when there is no Material [Scaffold].
/// Do not wrap a field that is already inside a padded scaffold.
class BeuiKeyboardAvoid extends StatelessWidget {
  const BeuiKeyboardAvoid({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    );
  }
}

/// After the current frame, scroll the nearest [Scrollable] so [context]
/// sits just above the keyboard.
void beuiRevealFocused(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    if (Scrollable.maybeOf(context) == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 1,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      duration: const Duration(milliseconds: 220),
      curve: BeuiCurves.easeOut,
    );
  });
}
