import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/presence.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

enum BeuiDrawerSide { left, right }

/// Side panel that slides in from the left or right.
/// Port of `components/motion/drawer.tsx`.
class BeuiDrawer extends StatefulWidget {
  const BeuiDrawer({
    super.key,
    required this.open,
    required this.onOpenChange,
    required this.child,
    this.side = BeuiDrawerSide.right,
    this.dismissable = true,
    this.semanticLabel,
    this.width = 320,
  });

  final bool open;
  final ValueChanged<bool> onOpenChange;
  final Widget child;
  final BeuiDrawerSide side;
  final bool dismissable;
  final String? semanticLabel;
  final double width;

  @override
  State<BeuiDrawer> createState() => _BeuiDrawerState();
}

class _BeuiDrawerState extends State<BeuiDrawer> with TickerProviderStateMixin {
  OverlayState? _overlay;
  OverlayEntry? _backdrop;
  OverlayEntry? _panel;
  late final BeuiSpringValue _slide;
  late final AnimationController _scrim;
  bool _present = false;

  @override
  void initState() {
    super.initState();
    _slide = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.panel)
      ..attach(this)
      ..addListener(_mark);
    _scrim =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 250),
          )
          ..addListener(_mark)
          ..addStatusListener(_onScrimStatus);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void _mark() {
    _backdrop?.markNeedsBuild();
    _panel?.markNeedsBuild();
    if (!_present &&
        !_slide.isAnimating &&
        _scrim.status == AnimationStatus.dismissed) {
      _tearDown();
    }
  }

  void _onScrimStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _mark();
  }

  bool _onKey(KeyEvent event) {
    if (!_present) return false;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onOpenChange(false);
      return true;
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    _slide.reducedMotion = beuiReduceMotion(context);
    if (widget.open && _backdrop == null) _show();
  }

  @override
  void didUpdateWidget(BeuiDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      if (widget.open) {
        _show();
      } else {
        _hide();
      }
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _tearDown();
    _slide
      ..removeListener(_mark)
      ..dispose();
    _scrim
      ..removeListener(_mark)
      ..removeStatusListener(_onScrimStatus)
      ..dispose();
    super.dispose();
  }

  void _show() {
    _present = true;
    _insert();
    final reduce = beuiReduceMotion(context);
    _scrim.duration = reduce
        ? const Duration(milliseconds: 200)
        : const Duration(milliseconds: 250);
    _scrim.forward();
    _slide.animateTo(1);
    _mark();
  }

  void _hide() {
    _present = false;
    final reduce = beuiReduceMotion(context);
    _scrim.duration = reduce
        ? const Duration(milliseconds: 200)
        : const Duration(milliseconds: 250);
    _scrim.reverse();
    _slide.animateTo(0);
    _mark();
  }

  void _insert() {
    if (_backdrop != null) return;
    final overlay = _overlay;
    if (overlay == null) return;
    _backdrop = OverlayEntry(builder: _buildBackdrop);
    _panel = OverlayEntry(builder: _buildPanel);
    overlay.insert(_backdrop!);
    overlay.insert(_panel!, above: _backdrop);
  }

  void _tearDown() {
    _backdrop?.remove();
    _panel?.remove();
    _backdrop = null;
    _panel = null;
  }

  Widget _buildBackdrop(BuildContext overlayContext) {
    final reduce = beuiReduceMotion(context);
    return Positioned.fill(
      child: BeuiPresence(
        present: _present,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.dismissable ? () => widget.onOpenChange(false) : null,
          child: Semantics(
            button: true,
            label: 'Close',
            child: BackdropFilter(
              filter: reduce
                  ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                  : ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ColoredBox(
                color: Color.fromRGBO(0, 0, 0, 0.4 * _scrim.value),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext overlayContext) {
    final colors = BeuiTheme.of(context).colors;
    final reduce = beuiReduceMotion(context);
    final view = MediaQuery.sizeOf(overlayContext);
    final width = math.min(widget.width, view.width * 0.85);
    final t = _slide.value.clamp(0.0, 1.0);
    final sign = widget.side == BeuiDrawerSide.right ? 1.0 : -1.0;
    final dx = reduce ? 0.0 : (1 - t) * width * sign;
    final opacity = reduce ? _scrim.value.clamp(0.0, 1.0) : 1.0;

    return Positioned(
      top: 0,
      bottom: 0,
      left: widget.side == BeuiDrawerSide.left ? 0 : null,
      right: widget.side == BeuiDrawerSide.right ? 0 : null,
      width: width,
      child: BeuiPresence(
        present: _present,
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Semantics(
              namesRoute: true,
              scopesRoute: true,
              label: widget.semanticLabel ?? 'Drawer',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.background,
                  border: Border(
                    left: widget.side == BeuiDrawerSide.right
                        ? BorderSide(color: colors.border)
                        : BorderSide.none,
                    right: widget.side == BeuiDrawerSide.left
                        ? BorderSide(color: colors.border)
                        : BorderSide.none,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 40,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: 14,
                    height: 1.45,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
