import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/presence.dart';
import '../../motion/reduce.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

/// Draggable bottom sheet with snap points, inertia and a glass surface.
/// Port of `components/motion/bottom-sheet.tsx`.
class BeuiBottomSheet extends StatefulWidget {
  const BeuiBottomSheet({
    super.key,
    required this.open,
    required this.onOpenChange,
    this.snapPoints = const [0.5, 0.92],
    this.initialSnap = 0,
    this.title,
    this.description,
    this.child,
    this.dismissThreshold = 120,
    this.semanticLabel,
  });

  final bool open;
  final ValueChanged<bool> onOpenChange;

  /// Heights 0–1 as a fraction of the viewport. First entry is the default.
  final List<double> snapPoints;
  final int initialSnap;
  final String? title;
  final String? description;
  final Widget? child;

  /// Min visual drag (px) past the current snap to dismiss.
  final double dismissThreshold;
  final String? semanticLabel;

  @override
  State<BeuiBottomSheet> createState() => _BeuiBottomSheetState();
}

class _BeuiBottomSheetState extends State<BeuiBottomSheet>
    with TickerProviderStateMixin {
  OverlayState? _overlay;
  OverlayEntry? _backdrop;
  OverlayEntry? _sheet;

  late final AnimationController _move;
  late final AnimationController _scrim;
  Animation<double>? _moveAnim;

  bool _present = false;
  int _snap = 0;
  double _y = 0;
  double _finger = 0;
  double _height = 0;

  static const _openDuration = Duration(milliseconds: 500);
  static const _reduceDuration = Duration(milliseconds: 180);

  @override
  void initState() {
    super.initState();
    _snap = widget.initialSnap;
    _move = AnimationController(vsync: this, duration: _openDuration)
      ..addListener(_onMove)
      ..addStatusListener(_onMoveStatus);
    _scrim = AnimationController(vsync: this, duration: _openDuration)
      ..addListener(_mark)
      ..addStatusListener(_onScrimStatus);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void _mark() {
    _backdrop?.markNeedsBuild();
    _sheet?.markNeedsBuild();
  }

  void _onMove() {
    final anim = _moveAnim;
    if (anim != null) _y = anim.value;
    _mark();
  }

  void _onMoveStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _maybeTearDown();
  }

  void _onScrimStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _maybeTearDown();
  }

  void _maybeTearDown() {
    if (_present) return;
    if (_move.isAnimating || _scrim.isAnimating) return;
    _tearDown();
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
    if (widget.open && _backdrop == null) _show();
  }

  @override
  void didUpdateWidget(BeuiBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open && !oldWidget.open) {
      _snap = widget.initialSnap;
      _show();
    } else if (!widget.open && oldWidget.open) {
      _hide();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _tearDown();
    _move
      ..removeListener(_onMove)
      ..removeStatusListener(_onMoveStatus)
      ..dispose();
    _scrim
      ..removeListener(_mark)
      ..removeStatusListener(_onScrimStatus)
      ..dispose();
    super.dispose();
  }

  Duration get _duration =>
      beuiReduceMotion(context) ? _reduceDuration : _openDuration;

  double _snapHeight(double viewHeight) {
    if (widget.snapPoints.isEmpty) return viewHeight * 0.5;
    final index = _snap.clamp(0, widget.snapPoints.length - 1);
    return viewHeight * widget.snapPoints[index].clamp(0.0, 1.0);
  }

  void _animateY(double target) {
    _move.stop();
    _move.duration = _duration;
    _moveAnim = Tween<double>(
      begin: _y,
      end: target,
    ).animate(CurvedAnimation(parent: _move, curve: BeuiCurves.easeDrawer));
    _move.forward(from: 0);
  }

  void _show() {
    _present = true;
    _insert();
    final viewH = MediaQuery.sizeOf(context).height;
    _height = _snapHeight(viewH);
    final reduce = beuiReduceMotion(context);
    _scrim.duration = _duration;
    _scrim.forward();
    if (reduce) {
      _y = 0;
      _mark();
    } else {
      _y = _height;
      _animateY(0);
    }
  }

  void _hide() {
    _present = false;
    _finger = 0;
    _scrim.duration = _duration;
    _scrim.reverse();
    if (beuiReduceMotion(context)) {
      _mark();
      if (_scrim.status == AnimationStatus.dismissed) _tearDown();
    } else {
      _animateY(_height);
    }
  }

  void _insert() {
    if (_backdrop != null) return;
    final overlay = _overlay;
    if (overlay == null) return;
    _backdrop = OverlayEntry(builder: _buildBackdrop);
    _sheet = OverlayEntry(builder: _buildSheet);
    overlay.insert(_backdrop!);
    overlay.insert(_sheet!, above: _backdrop);
  }

  void _tearDown() {
    _backdrop?.remove();
    _sheet?.remove();
    _backdrop = null;
    _sheet = null;
  }

  void _onDragStart(DragStartDetails details) {
    _move.stop();
    _finger = _y / 0.4;
    if (_y < 0) _finger = _y / 0.02;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _finger += details.delta.dy;
    _y = _finger < 0 ? _finger * 0.02 : _finger * 0.4;
    _mark();
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final offset = _y;
    final last = widget.snapPoints.length - 1;

    if (velocity > 600 || offset > widget.dismissThreshold) {
      final canStepDown =
          _snap > 0 && velocity < 800 && offset < widget.dismissThreshold * 1.6;
      if (canStepDown) {
        _snap -= 1;
        _height = _snapHeight(MediaQuery.sizeOf(context).height);
        _finger = 0;
        _animateY(0);
      } else {
        widget.onOpenChange(false);
      }
      return;
    }

    if (velocity < -500) {
      _snap = math.min(last, _snap + 1);
      _height = _snapHeight(MediaQuery.sizeOf(context).height);
      _finger = 0;
      _animateY(0);
      return;
    }

    if (offset > 80 && _snap > 0) {
      _snap -= 1;
    } else if (offset < -80 && _snap < last) {
      _snap += 1;
    }
    _height = _snapHeight(MediaQuery.sizeOf(context).height);
    _finger = 0;
    _animateY(0);
  }

  Widget _buildBackdrop(BuildContext overlayContext) {
    final colors = BeuiTheme.of(context).colors;
    final reduce = beuiReduceMotion(context);
    return Positioned.fill(
      child: BeuiPresence(
        present: _present,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onOpenChange(false),
          child: Semantics(
            button: true,
            label: 'Close bottom sheet',
            child: BackdropFilter(
              filter: reduce
                  ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                  : ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ColoredBox(
                color: colors.background.withValues(alpha: 0.4 * _scrim.value),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheet(BuildContext overlayContext) {
    final colors = BeuiTheme.of(context).colors;
    final reduce = beuiReduceMotion(context);
    final view = MediaQuery.sizeOf(overlayContext);
    _height = _snapHeight(view.height);
    final opacity = reduce ? _scrim.value.clamp(0.0, 1.0) : 1.0;
    final ty = reduce ? 0.0 : _y;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: BeuiPresence(
        present: _present,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, ty),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 672),
                child: SizedBox(
                  height: _height,
                  width: double.infinity,
                  child: Semantics(
                    namesRoute: true,
                    scopesRoute: true,
                    label:
                        widget.semanticLabel ?? widget.title ?? 'Bottom sheet',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(BeuiRadii.sheet),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(BeuiRadii.sheet),
                          ),
                          border: Border(
                            top: BorderSide(color: colors.border),
                            left: BorderSide(color: colors.border),
                            right: BorderSide(color: colors.border),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 24,
                              offset: Offset(0, -8),
                            ),
                          ],
                        ),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: colors.foreground,
                            fontSize: 14,
                            height: 1.45,
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onVerticalDragStart: _onDragStart,
                                onVerticalDragUpdate: _onDragUpdate,
                                onVerticalDragEnd: _onDragEnd,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    8,
                                  ),
                                  child: Column(
                                    children: [
                                      Center(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: colors.mutedForeground
                                                .withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(
                                              BeuiRadii.pill,
                                            ),
                                          ),
                                          child: const SizedBox(
                                            width: 40,
                                            height: 6,
                                          ),
                                        ),
                                      ),
                                      if (widget.title != null ||
                                          widget.description != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (widget.title != null)
                                                  Text(
                                                    widget.title!,
                                                    style: TextStyle(
                                                      color: colors.foreground,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                if (widget.description != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 2,
                                                        ),
                                                    child: Text(
                                                      widget.description!,
                                                      style: TextStyle(
                                                        color: colors
                                                            .mutedForeground,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    24,
                                  ),
                                  child:
                                      widget.child ?? const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
