import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Full-size overlay catcher that closes a popover when the pointer lands
/// outside [hole] (global coordinates of the trigger).
///
/// Returning false from [hitTest] inside the hole lets the trigger below the
/// overlay keep receiving taps. Unarmed, every hit passes through so the
/// opening pointer cannot dismiss on the same gesture.
class BeuiOverlayDismiss extends LeafRenderObjectWidget {
  const BeuiOverlayDismiss({
    super.key,
    required this.armed,
    required this.onDismiss,
    this.hole,
  });

  final bool armed;
  final Rect? hole;
  final VoidCallback onDismiss;

  @override
  RenderBeuiOverlayDismiss createRenderObject(BuildContext context) {
    return RenderBeuiOverlayDismiss(
      armed: armed,
      hole: hole,
      onDismiss: onDismiss,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBeuiOverlayDismiss renderObject,
  ) {
    renderObject
      ..armed = armed
      ..hole = hole
      ..onDismiss = onDismiss;
  }
}

class RenderBeuiOverlayDismiss extends RenderBox {
  RenderBeuiOverlayDismiss({
    required bool armed,
    required Rect? hole,
    required VoidCallback onDismiss,
  })  : _armed = armed,
        _hole = hole,
        _onDismiss = onDismiss;

  bool _armed;
  Rect? _hole;
  VoidCallback _onDismiss;

  set armed(bool value) {
    if (_armed == value) return;
    _armed = value;
  }

  set hole(Rect? value) {
    if (_hole == value) return;
    _hole = value;
  }

  set onDismiss(VoidCallback value) {
    _onDismiss = value;
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_armed) return false;
    final global = localToGlobal(position);
    final hole = _hole;
    if (hole != null && hole.inflate(1).contains(global)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) _onDismiss();
  }
}

/// Arms overlay dismiss after the gesture that opened the panel has ended.
class BeuiDismissArm {
  bool armed = false;
  PointerRoute? _route;

  void cancel() {
    armed = false;
    final route = _route;
    if (route == null) return;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(route);
    _route = null;
  }

  void armAfterOpen(VoidCallback tick) {
    armed = false;
    final existing = _route;
    if (existing != null) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(existing);
      _route = null;
    }
    var done = false;
    void finish() {
      if (done) return;
      done = true;
      final route = _route;
      if (route != null) {
        GestureBinding.instance.pointerRouter.removeGlobalRoute(route);
        _route = null;
      }
      armed = true;
      tick();
    }

    void route(PointerEvent event) {
      if (event is PointerUpEvent || event is PointerCancelEvent) finish();
    }

    GestureBinding.instance.pointerRouter.addGlobalRoute(route);
    _route = route;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // onTap opens after pointer-up, so no up will follow. Arm this frame.
      // pointer-down focus opens while the finger is down; the route finishes.
      if (!done && _route != null) finish();
    });
  }
}
