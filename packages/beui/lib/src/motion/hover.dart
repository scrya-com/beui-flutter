import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Schedule a rebuild after the current mouse-tracker phase.
///
/// `MouseRegion.onEnter` / `Listener.onPointerHover` run inside
/// `_deviceUpdatePhase`. Calling `setState` there recursively re-enters the
/// tracker (Flutter `mouse_tracker.dart:199`).
void beuiAfterPointer(VoidCallback fn) {
  WidgetsBinding.instance.addPostFrameCallback((_) => fn());
}

/// True only on devices with a real hover (mouse / trackpad).
///
/// Touch fires phantom hover on tap that sticks until tap-elsewhere —
/// gate hover-only effects (scale lifts, magnetic pulls) behind this.
/// Mirrors `useHoverCapable` (`(hover: hover) and (pointer: fine)`).
/// Flutter web reports `defaultTargetPlatform` as Android, so [kIsWeb] is
/// treated as hover-capable.
bool beuiHoverCapable(BuildContext context) {
  if (kIsWeb) return true;
  final kind = BeuiPointerKind.maybeOf(context);
  if (kind != null) return kind == PointerDeviceKind.mouse;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
      return false;
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return true;
  }
}

/// Records the last pointer device so hover-capable gating is live, not
/// guessed from the OS.
class BeuiPointerKind extends InheritedWidget {
  const BeuiPointerKind({
    super.key,
    required this.kind,
    required super.child,
  });

  final PointerDeviceKind kind;

  static PointerDeviceKind? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BeuiPointerKind>()?.kind;

  @override
  bool updateShouldNotify(BeuiPointerKind oldWidget) => kind != oldWidget.kind;
}

class BeuiPointerScope extends StatefulWidget {
  const BeuiPointerScope({super.key, required this.child});

  final Widget child;

  @override
  State<BeuiPointerScope> createState() => _BeuiPointerScopeState();
}

class _BeuiPointerScopeState extends State<BeuiPointerScope> {
  PointerDeviceKind _kind = PointerDeviceKind.touch;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: (e) => _set(e.kind),
      onPointerDown: (e) => _set(e.kind),
      child: BeuiPointerKind(kind: _kind, child: widget.child),
    );
  }

  void _set(PointerDeviceKind kind) {
    if (kind == _kind) return;
    _kind = kind;
    beuiAfterPointer(() {
      if (mounted) setState(() {});
    });
  }
}
