import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

enum BeuiHoldActionType { vertical, horizontal }

/// Hold-to-confirm control whose fill rises or sweeps across the surface.
/// Port of `hold-action-button.tsx`.
class BeuiHoldActionButton extends StatefulWidget {
  const BeuiHoldActionButton({
    super.key,
    required this.child,
    this.type = BeuiHoldActionType.vertical,
    this.holdingLabel = const Text('Keep holding'),
    this.completeLabel = const Text('Done'),
    this.holdDuration = const Duration(milliseconds: 1600),
    this.onHoldComplete,
    this.enabled = true,
    this.semanticLabel,
  });

  final Widget child;
  final BeuiHoldActionType type;
  final Widget holdingLabel;
  final Widget completeLabel;
  final Duration holdDuration;
  final VoidCallback? onHoldComplete;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<BeuiHoldActionButton> createState() => _BeuiHoldActionButtonState();
}

class _BeuiHoldActionButtonState extends State<BeuiHoldActionButton>
    with TickerProviderStateMixin {
  late final AnimationController _fill;
  late final AnimationController _wave;
  late final BeuiSpringValue _press;
  final FocusNode _focus = FocusNode();
  bool _holding = false;
  bool _completed = false;
  bool _completedOnce = false;
  bool _pressed = false;

  bool get _canHold => widget.enabled;
  bool get _active => _holding || _completed;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(vsync: this)
      ..addListener(_onTick)
      ..addStatusListener(_onFillStatus);
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addListener(_onTick);
    _press = BeuiSpringValue(value: 1, spec: BeuiSpringSpec.press)
      ..attach(this)
      ..addListener(_onTick);
    _focus.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _onFillStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _onFillComplete();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _press.reducedMotion = beuiReduceMotion(context);
  }

  @override
  void dispose() {
    _fill
      ..removeListener(_onTick)
      ..removeStatusListener(_onFillStatus)
      ..dispose();
    _wave
      ..removeListener(_onTick)
      ..dispose();
    _press
      ..removeListener(_onTick)
      ..dispose();
    _focus
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _syncPress() {
    if (!mounted) return;
    final reduce = beuiReduceMotion(context);
    if (_pressed && _canHold && !reduce) {
      _press.animateTo(0.98);
    } else {
      _press.animateTo(1);
    }
  }

  void _startHold() {
    if (!mounted || !_canHold || _holding) return;
    _completedOnce = false;
    setState(() {
      _completed = false;
      _holding = true;
    });
    final reduce = beuiReduceMotion(context);
    _fill.animateTo(
      1,
      duration: widget.holdDuration,
      curve: Curves.linear,
    );
    if (!reduce) {
      _wave.repeat();
    }
  }

  void _cancelHold() {
    if (!mounted) return;
    if (!_holding && !_completed) return;
    setState(() {
      _holding = false;
      _completed = false;
    });
    final reduce = beuiReduceMotion(context);
    _fill.animateTo(
      0,
      duration: Duration(milliseconds: reduce ? 150 : 240),
      curve: BeuiCurves.easeOut,
    );
    _wave
      ..stop()
      ..value = 0;
  }

  void _onFillComplete() {
    if (!_holding || _completedOnce) return;
    _completedOnce = true;
    setState(() => _completed = true);
    widget.onHoldComplete?.call();
  }

  void _onPointerMove(Offset global) {
    if (!_holding) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(global);
    final size = box.size;
    final outside = local.dx < 0 ||
        local.dx > size.width ||
        local.dy < 0 ||
        local.dy > size.height;
    if (outside) _cancelHold();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_canHold) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.space && key != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent && !HardwareKeyboard.instance.isMetaPressed) {
      if (event is! KeyRepeatEvent) {
        _startHold();
        _pressed = true;
        _syncPress();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      _cancelHold();
      _pressed = false;
      _syncPress();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final fillColor = colors.accent;
    final t = _fill.value;
    final focused = _focus.hasFocus;

    return Semantics(
      button: true,
      enabled: _canHold,
      label: widget.semanticLabel,
      child: Focus(
        focusNode: _focus,
        canRequestFocus: widget.enabled,
        onKeyEvent: _onKey,
        child: MouseRegion(
          cursor:
              _canHold ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Listener(
            onPointerMove: _canHold
                ? (e) => _onPointerMove(e.position)
                : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _canHold
                  ? (_) {
                      _pressed = true;
                      _syncPress();
                      _startHold();
                    }
                  : null,
              onTapUp: (_) {
                _pressed = false;
                _syncPress();
                _cancelHold();
              },
              onTapCancel: () {
                _pressed = false;
                _syncPress();
                _cancelHold();
              },
              child: Opacity(
                opacity: widget.enabled ? 1 : 0.5,
                child: Transform.scale(
                  scale: _press.value,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 288,
                      minHeight: 64,
                    ),
                    child: SizedBox(
                      height: 64,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(22),
                            border: focused
                                ? Border.all(color: colors.primary, width: 2)
                                : null,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (reduce)
                                Opacity(
                                  opacity: _active ? 1 : 0,
                                  child: ColoredBox(color: fillColor),
                                )
                              else
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final w = constraints.maxWidth;
                                    final h = constraints.maxHeight;
                                    final offset =
                                        widget.type ==
                                                BeuiHoldActionType.horizontal
                                            ? Offset((t - 1) * w, 0)
                                            : Offset(0, (1 - t) * h * 1.15);
                                    return Transform.translate(
                                      offset: offset,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        clipBehavior: Clip.none,
                                        children: [
                                          ColoredBox(color: fillColor),
                                          if (widget.type ==
                                              BeuiHoldActionType.horizontal)
                                            Positioned(
                                              right: -20,
                                              top: -h * _wave.value,
                                              width: 24,
                                              height: h * 2,
                                              child: CustomPaint(
                                                painter: _HoldWavePainter(
                                                  color: fillColor,
                                                  horizontal: true,
                                                ),
                                              ),
                                            )
                                          else
                                            Positioned(
                                              left: -w * _wave.value,
                                              top: -20,
                                              width: w * 2,
                                              height: 24,
                                              child: CustomPaint(
                                                painter: _HoldWavePainter(
                                                  color: fillColor,
                                                  horizontal: false,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              DefaultTextStyle(
                                style: TextStyle(
                                  color: colors.primaryForeground,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.16,
                                  height: 1,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedOpacity(
                                      opacity: _active ? 0 : 1,
                                      duration: Duration(
                                        milliseconds: reduce ? 0 : 120,
                                      ),
                                      curve: BeuiCurves.easeOut,
                                      child: widget.child,
                                    ),
                                    AnimatedOpacity(
                                      opacity:
                                          _holding && !_completed ? 1 : 0,
                                      duration: Duration(
                                        milliseconds: reduce ? 0 : 120,
                                      ),
                                      curve: BeuiCurves.easeOut,
                                      child: ExcludeSemantics(
                                        excluding: !_holding || _completed,
                                        child: widget.holdingLabel,
                                      ),
                                    ),
                                    AnimatedOpacity(
                                      opacity: _completed ? 1 : 0,
                                      duration: Duration(
                                        milliseconds: reduce ? 0 : 120,
                                      ),
                                      curve: BeuiCurves.easeOut,
                                      child: ExcludeSemantics(
                                        excluding: !_completed,
                                        child: widget.completeLabel,
                                      ),
                                    ),
                                  ],
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
}

class _HoldWavePainter extends CustomPainter {
  _HoldWavePainter({required this.color, required this.horizontal});

  final Color color;
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (horizontal) {
      // viewBox 0 0 24 240 — wave on the right edge.
      final sx = size.width / 24;
      final sy = size.height / 240;
      canvas.save();
      canvas.scale(sx, sy);
      path
        ..moveTo(0, 0)
        ..lineTo(12, 0)
        ..cubicTo(2, 20, 2, 40, 12, 60)
        ..cubicTo(22, 80, 22, 100, 12, 120)
        ..cubicTo(2, 140, 2, 160, 12, 180)
        ..cubicTo(22, 200, 22, 220, 12, 240)
        ..lineTo(0, 240)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    } else {
      // viewBox 0 0 240 24 — wave on the top edge.
      final sx = size.width / 240;
      final sy = size.height / 24;
      canvas.save();
      canvas.scale(sx, sy);
      path
        ..moveTo(0, 12)
        ..cubicTo(20, 2, 40, 2, 60, 12)
        ..cubicTo(80, 22, 100, 22, 120, 12)
        ..cubicTo(140, 2, 160, 2, 180, 12)
        ..cubicTo(200, 22, 220, 22, 240, 12)
        ..lineTo(240, 24)
        ..lineTo(0, 24)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_HoldWavePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.horizontal != horizontal;
}
