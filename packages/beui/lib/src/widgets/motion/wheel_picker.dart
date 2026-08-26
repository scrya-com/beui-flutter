import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../physics/spring.dart';
import '../../tokens/colors.dart';
import '../../tokens/theme.dart';

class BeuiWheelPickerOption {
  const BeuiWheelPickerOption({required this.value, String? label})
      : label = label ?? value;

  final String value;
  final String label;
}

/// iOS-style picker drum with momentum coast and detent snap.
/// Port of `components/motion/wheel-picker.tsx`.
class BeuiWheelPicker extends StatefulWidget {
  const BeuiWheelPicker({
    super.key,
    required this.options,
    this.value,
    this.initialValue,
    this.onChanged,
    this.visibleCount = 5,
    this.itemHeight = 36,
    this.enabled = true,
    this.sound = false,
    this.framed = true,
    this.semanticLabel,
  });

  final List<BeuiWheelPickerOption> options;
  final String? value;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final int visibleCount;
  final double itemHeight;
  final bool enabled;
  final bool sound;
  final bool framed;
  final String? semanticLabel;

  @override
  State<BeuiWheelPicker> createState() => _BeuiWheelPickerState();
}

// Physics constants, tuned for an iOS-like flick. Named locally because the
// wheel coasts in whole-row units and springs to an integer detent.
const _deceleration = 0.00042; // rows per ms²
const _maxVelocity = 0.18; // rows per ms
const _velocityWindow = 90.0; // ms
const _wheelSens = 0.012; // rows per pixel of wheel delta
const _wheelSettleMs = 110.0;
const _back = 1.35;
const _perspective = 0.001; // 1 / CSS perspective 1000

class _BeuiWheelPickerState extends State<BeuiWheelPicker>
    with SingleTickerProviderStateMixin {
  late double _scroll;
  late String? _emitted;
  int _lastTick = 0;
  bool _grabbing = false;
  ScrollController? _reduceScroll;

  Ticker? _ticker;
  Duration _elapsed = Duration.zero;

  _Glide? _glide;
  _Drag? _drag;
  double? _latestY;
  double? _wheelSettleRemain;

  bool get _controlled => widget.value != null;
  String? get _current => _controlled ? widget.value : _emitted;

  int get _last => math.max(0, widget.options.length - 1);

  double get _itemAngleDeg {
    final rowsEachSide = math.max(1, (widget.visibleCount / 2).floor());
    return 90 / (rowsEachSide + 1);
  }

  double get _itemAngleRad => _itemAngleDeg * math.pi / 180;

  double get _radius => widget.itemHeight / math.tan(_itemAngleRad);

  int get _hideBeyond {
    final rowsEachSide = math.max(1, (widget.visibleCount / 2).floor());
    return rowsEachSide + 1;
  }

  double get _height {
    final rowsEachSide = math.max(1, (widget.visibleCount / 2).floor());
    return (2 * _radius * math.sin(rowsEachSide * _itemAngleRad) +
            widget.itemHeight)
        .roundToDouble();
  }

  int _indexOf(String? value) {
    final i = widget.options.indexWhere((o) => o.value == value);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    final start = widget.initialValue ?? widget.value;
    _emitted = start ??
        (widget.options.isEmpty ? null : widget.options.first.value);
    _scroll = _indexOf(_emitted).toDouble();
    _lastTick = _scroll.round();
    _ticker = createTicker(_onTick);
    _reduceScroll = ScrollController(
      initialScrollOffset: _scroll * widget.itemHeight,
    );
  }

  @override
  void didUpdateWidget(BeuiWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_drag != null) return;
    final target = _indexOf(_current);
    _emitted = _current;
    if ((_scroll.round() - target).abs() < 0.001) return;
    _startGlide(target.toDouble(), 260);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _reduceScroll?.dispose();
    super.dispose();
  }

  void _ensureTicking() {
    final ticker = _ticker;
    if (ticker == null) return;
    if (!ticker.isActive) {
      _elapsed = Duration.zero;
      ticker.start();
    }
  }

  void _stopTickerIfIdle() {
    if (_glide == null && _drag == null && _wheelSettleRemain == null) {
      _ticker?.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final last = _elapsed;
    _elapsed = elapsed;
    final dt = (elapsed - last).inMicroseconds / 1e6;
    var dirty = false;

    final glide = _glide;
    if (glide != null) {
      final t = (elapsed.inMicroseconds / 1e6) - glide.startSec;
      final p = glide.durationSec <= 0 ? 1.0 : t / glide.durationSec;
      if (p >= 1) {
        _scroll = glide.to;
        _glide = null;
        _maybeTick(_scroll);
        _emit(_scroll.round());
      } else {
        _scroll = glide.from + (glide.to - glide.from) * glide.ease(p);
        _maybeTick(_scroll);
      }
      dirty = true;
    }

    final remain = _wheelSettleRemain;
    if (remain != null) {
      final next = remain - dt;
      if (next <= 0) {
        _wheelSettleRemain = null;
        _startGlide(
          _clamp(_scroll.roundToDouble(), 0, _last.toDouble()),
          240,
          ease: (p) => beuiBackEase(p, _back),
        );
      } else {
        _wheelSettleRemain = next;
      }
      dirty = true;
    }

    if (dirty && mounted) setState(() {});
    _stopTickerIfIdle();
  }

  void _startGlide(
    double to,
    double durationMs, {
    double Function(double p)? ease,
  }) {
    _ticker?.stop();
    _elapsed = Duration.zero;
    final from = _scroll;
    final dist = to - from;
    if (dist.abs() < 1e-6 || durationMs <= 0) {
      _scroll = to;
      _glide = null;
      _maybeTick(to);
      _emit(to.round());
      if (mounted) setState(() {});
      return;
    }
    _glide = _Glide(
      from: from,
      to: to,
      durationSec: durationMs / 1000,
      startSec: 0,
      ease: ease ?? (p) => 1 - math.pow(1 - p, 3).toDouble(),
    );
    _ensureTicking();
  }

  void _fling(double velocity) {
    final from = _scroll;
    if (from < 0 || from > _last) {
      _startGlide(_clamp(from.roundToDouble(), 0, _last.toDouble()), 260);
      return;
    }
    final dir = velocity == 0 ? 0.0 : velocity.sign;
    final coast = ((velocity * velocity) / (2 * _deceleration)) * dir;
    final to = _clamp((from + coast).roundToDouble(), 0, _last.toDouble());
    final duration = _clamp(
      math.sqrt((to - from).abs()) * 300 + 240,
      280,
      1700,
    );
    _startGlide(to, duration, ease: (p) => beuiBackEase(p, _back));
  }

  void _step(int by) {
    _startGlide(
      _clamp((_scroll.round() + by).toDouble(), 0, _last.toDouble()),
      300,
      ease: (p) => beuiBackEase(p, _back),
    );
  }

  void _emit(int i) {
    if (widget.options.isEmpty) return;
    final v = widget.options[_clamp(i, 0, _last).toInt()].value;
    if (v == _emitted) return;
    _emitted = v;
    if (widget.sound && beuiReduceMotion(context)) _playTick();
    widget.onChanged?.call(v);
    if (mounted) setState(() {});
  }

  void _maybeTick(double pos) {
    final row = _clamp(pos.round(), 0, _last).toInt();
    if (!widget.sound || beuiReduceMotion(context)) {
      _lastTick = row;
      return;
    }
    if (row == _lastTick) return;
    _lastTick = row;
    _playTick();
  }

  void _playTick() {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  void _beginDrag(double y) {
    _glide = null;
    _wheelSettleRemain = null;
    _ticker?.stop();
    _grabbing = true;
    _drag = _Drag(y: y, scroll: _scroll, pts: [(y, _nowMs())]);
    _latestY = y;
    if (mounted) setState(() {});
  }

  void _moveDrag(double y) {
    if (_drag == null) return;
    _latestY = y;
    _drag!.pts.add((y, _nowMs()));
    if (_drag!.pts.length > 8) _drag!.pts.removeAt(0);
    _applyDragY(y);
    if (mounted) setState(() {});
  }

  void _applyDragY(double y) {
    final drag = _drag;
    if (drag == null) return;
    var next = drag.scroll + (drag.y - y) / widget.itemHeight;
    if (next < 0) {
      next *= 0.3;
    } else if (next > _last) {
      next = _last + (next - _last) * 0.3;
    }
    _scroll = next;
    _maybeTick(next);
    _emit(_clamp(next, 0, _last.toDouble()).round());
  }

  void _endDrag() {
    final drag = _drag;
    if (drag == null) return;
    if (_latestY != null) _applyDragY(_latestY!);
    _drag = null;
    _latestY = null;
    _grabbing = false;
    var v = 0.0;
    final pts = drag.pts;
    if (pts.length > 1) {
      final latest = pts.last;
      var ref = pts.first;
      for (final p in pts) {
        if (latest.$2 - p.$2 <= _velocityWindow) {
          ref = p;
          break;
        }
      }
      final dt = latest.$2 - ref.$2;
      if (dt > 0) {
        final raw = (ref.$1 - latest.$1) / widget.itemHeight / dt;
        v = _clamp(raw, -_maxVelocity, _maxVelocity);
      }
    }
    _fling(v);
    if (mounted) setState(() {});
  }

  double _nowMs() => DateTime.now().millisecondsSinceEpoch.toDouble();

  void _onWheel(double deltaY, int deltaMode) {
    if (!widget.enabled || beuiReduceMotion(context)) return;
    _glide = null;
    final px = deltaMode == 1 ? deltaY * 16 : deltaY;
    _scroll = _clamp(_scroll + px * _wheelSens, 0, _last.toDouble());
    _maybeTick(_scroll);
    _emit(_scroll.round());
    _wheelSettleRemain = _wheelSettleMs / 1000;
    _ensureTicking();
    if (mounted) setState(() {});
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final at = _scroll.round();
    final map = <LogicalKeyboardKey, int>{
      LogicalKeyboardKey.arrowUp: -1,
      LogicalKeyboardKey.arrowDown: 1,
      LogicalKeyboardKey.home: -at,
      LogicalKeyboardKey.end: _last - at,
    };
    final by = map[event.logicalKey];
    if (by == null) return KeyEventResult.ignored;
    _step(by);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    if (reduce) return _buildReduced(colors);

    final fade = widget.framed ? colors.card : colors.background;
    final height = _height;

    Widget drum = SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BeuiRadii.card),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.framed ? colors.card : null,
            border: widget.framed ? Border.all(color: colors.border) : null,
            borderRadius: BorderRadius.circular(BeuiRadii.card),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _DrumLayer(
                options: widget.options,
                scroll: _scroll,
                itemHeight: widget.itemHeight,
                itemAngleRad: _itemAngleRad,
                radius: _radius,
                hideBeyond: _hideBeyond,
                color: colors.mutedForeground,
              ),
              Center(
                child: IgnorePointer(
                  child: SizedBox(
                    height: widget.itemHeight,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.foreground.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(BeuiRadii.md),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(BeuiRadii.md),
                        child: OverflowBox(
                          maxHeight: height,
                          minHeight: height,
                          alignment: Alignment.center,
                          child: _DrumLayer(
                            options: widget.options,
                            scroll: _scroll,
                            itemHeight: widget.itemHeight,
                            itemAngleRad: _itemAngleRad,
                            radius: _radius,
                            hideBeyond: _hideBeyond,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.22,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [fade, fade.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: height * 0.22,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [fade, fade.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!widget.enabled) {
      drum = Opacity(opacity: 0.5, child: drum);
    }

    return Focus(
      onKeyEvent: _onKey,
      child: Semantics(
        label: widget.semanticLabel,
        enabled: widget.enabled,
        value: _current,
        child: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: widget.enabled
              ? <Type, GestureRecognizerFactory>{
                  _ClaimVerticalDrag: GestureRecognizerFactoryWithHandlers<
                      _ClaimVerticalDrag>(
                    () => _ClaimVerticalDrag(
                      supportedDevices: const {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.invertedStylus,
                      },
                    ),
                    (instance) {
                      instance.dragStartBehavior = DragStartBehavior.down;
                      instance.onStart =
                          (d) => _beginDrag(d.globalPosition.dy);
                      instance.onUpdate =
                          (d) => _moveDrag(d.globalPosition.dy);
                      instance.onEnd = (_) => _endDrag();
                      instance.onCancel = _endDrag;
                    },
                  ),
                }
              : const <Type, GestureRecognizerFactory>{},
          child: Listener(
            onPointerSignal: (event) {
              if (event is! PointerScrollEvent) return;
              GestureBinding.instance.pointerSignalResolver.register(
                event,
                (resolved) {
                  final scroll = resolved as PointerScrollEvent;
                  _onWheel(scroll.scrollDelta.dy, 0);
                },
              );
            },
            child: MouseRegion(
              cursor: !widget.enabled
                  ? SystemMouseCursors.basic
                  : _grabbing
                      ? SystemMouseCursors.grabbing
                      : SystemMouseCursors.grab,
              child: drum,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReduced(BeuiColors colors) {
    final pad = (_height - widget.itemHeight) / 2;
    final controller = _reduceScroll;
    return Opacity(
      opacity: widget.enabled ? 1 : 0.5,
      child: SizedBox(
        height: _height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BeuiRadii.card),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.framed ? colors.card : null,
              border: widget.framed ? Border.all(color: colors.border) : null,
              borderRadius: BorderRadius.circular(BeuiRadii.card),
            ),
            child: Stack(
              children: [
                ListView.builder(
                  controller: controller,
                  padding: EdgeInsets.symmetric(vertical: pad),
                  itemExtent: widget.itemHeight,
                  itemCount: widget.options.length,
                  itemBuilder: (context, i) {
                    final option = widget.options[i];
                    final selected = option.value == _current;
                    return GestureDetector(
                      onTap: widget.enabled
                          ? () {
                              _emit(i);
                              controller?.jumpTo(i * widget.itemHeight);
                            }
                          : null,
                      child: Center(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? colors.foreground
                                : colors.mutedForeground,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      height: widget.itemHeight,
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(color: colors.border),
                        ),
                        color: colors.foreground.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Glide {
  _Glide({
    required this.from,
    required this.to,
    required this.durationSec,
    required this.startSec,
    required this.ease,
  });

  final double from;
  final double to;
  final double durationSec;
  final double startSec;
  final double Function(double p) ease;
}

class _Drag {
  _Drag({required this.y, required this.scroll, required this.pts});

  final double y;
  final double scroll;
  final List<(double, double)> pts;
}

/// Claims the pointer on down so a parent [Scrollable] cannot steal the flick.
/// React binds non-passive `touchmove` + `preventDefault` for the same reason.
class _ClaimVerticalDrag extends VerticalDragGestureRecognizer {
  _ClaimVerticalDrag({super.supportedDevices});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

/// Per-item cylinder using Flutter's cylindrical projection.
/// CSS is `perspective(1000) · T(0,0,-r) · Rx(angle·(s-i)) · T(0,0,r)`;
/// nested Transform layers flatten, so each row gets the composed matrix.
class _DrumLayer extends StatelessWidget {
  const _DrumLayer({
    required this.options,
    required this.scroll,
    required this.itemHeight,
    required this.itemAngleRad,
    required this.radius,
    required this.hideBeyond,
    required this.color,
  });

  final List<BeuiWheelPickerOption> options;
  final double scroll;
  final double itemHeight;
  final double itemAngleRad;
  final double radius;
  final int hideBeyond;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < options.length; i++)
          if ((i - scroll).abs() <= hideBeyond)
            Transform(
              alignment: Alignment.center,
              transformHitTests: false,
              transform: MatrixUtils.createCylindricalProjectionTransform(
                radius: radius,
                angle: itemAngleRad * (scroll - i),
                perspective: _perspective,
              ),
              child: SizedBox(
                height: itemHeight,
                width: double.infinity,
                child: Center(
                  child: Text(
                    options[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

double _clamp(num v, num lo, num hi) =>
    math.max(lo, math.min(v, hi)).toDouble();
