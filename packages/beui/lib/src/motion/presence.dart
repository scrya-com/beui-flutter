import 'package:flutter/widgets.dart';

/// Overlay presence, port of `PresenceGate`.
///
/// While [present] is true the child is interactive. The moment the close
/// path starts, pointer events and semantics drop in the same frame; the
/// visual exit can keep playing until [onExitComplete] unmounts.
class BeuiPresence extends StatelessWidget {
  const BeuiPresence({
    super.key,
    required this.present,
    required this.child,
  });

  final bool present;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !present,
      child: ExcludeSemantics(
        excluding: !present,
        child: child,
      ),
    );
  }
}
