import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../gestures/slider.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import 'range_slider.dart';

/// Settle spring for the snap after a flick — quick, no overshoot past the tick.
const _snapSpring = BeuiSpringSpec(
  stiffness: 500,
  damping: 40,
  mass: 0.6,
);

const _inertiaPower = 0.22;
const _inertiaTau = 0.32;

/// Ruler whose scale scrolls under a fixed needle.
/// Port of `range-slider-ruler.tsx`.
class BeuiRulerSlider extends StatefulWidget {
  const BeuiRulerSlider({
    super.key,
    this.value,
    this.initialValue = 0,
    this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.enabled = true,
    this.gap = 14,
    this.majorEvery = 5,
    this.unit,
    this.semanticLabel,
    this.formatValueText,
  });

  final double? value;
  final double initialValue;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final double step;
  final bool enabled;
  final double gap;
  final int majorEvery;
  final String? unit;
  final String? semanticLabel;
  final String? Function(double value)? formatValueText;

  @override
  State<BeuiRulerSlider> createState() => _BeuiRulerSliderState();
}

class _BeuiRulerSliderState extends State<BeuiRulerSlider>
    with TickerProviderStateMixin, BeuiSliderBinding {
  late final BeuiSpringValue _x;
  Ticker? _momentum;
  Duration? _lastMomentum;
  double _vx = 0;
  bool _interacting = false;
  bool _holding = false;
  int _gesture = 0;

  @override
  double? get sliderBoundValue => widget.value;
  @override
  double get sliderBoundInitial => widget.initialValue;
  @override
  ValueChanged<double>? get sliderBoundOnChanged => widget.onChanged;
  @override
  double get sliderBoundMin => widget.min;
  @override
  double get sliderBoundMax => widget.max;
  @override
  double get sliderBoundStep => widget.step;
  @override
  bool get sliderBoundEnabled => widget.enabled;
  @override
  String? get sliderBoundLabel => widget.semanticLabel;
  @override
  String? Function(double value)? get sliderBoundValueText =>
      widget.formatValueText ??
      (widget.unit != null
          ? (v) => '${_readout(v)} ${widget.unit}'
          : null);

  double get _span => double.parse(
        ((sliderMax - sliderMin) / sliderStep).toStringAsFixed(6),
      );
  double get _maxOffset => _span * widget.gap;

  int get _decimals {
    if (sliderStep == sliderStep.roundToDouble()) return 0;
    final text = sliderStep.toString();
    if (text.contains('e') || text.contains('E')) return 0;
    final i = text.indexOf('.');
    return i < 0 ? 0 : text.length - i - 1;
  }

  String _readout(double value) => value.toStringAsFixed(_decimals);

  String _tickLabel(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return beuiSliderNumber(value);
  }

  double _xFor(double value) =>
      -((value - sliderMin) / sliderStep) * widget.gap;

  double _elastic(double x) {
    if (x > 0) return x * 0.03;
    if (x < -_maxOffset) return -_maxOffset + (x + _maxOffset) * 0.03;
    return x;
  }

  @override
  void initState() {
    super.initState();
    initSlider();
    _x = BeuiSpringValue(value: _xFor(sliderCurrent), spec: _snapSpring)
      ..attach(this)
      ..addListener(_onX);
    _momentum = createTicker(_onMomentum);
  }

  void _onX() {
    if (_interacting) {
      sliderCommit(sliderMin + (-_x.value / widget.gap) * sliderStep);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _x.reducedMotion = beuiReduceMotion(context);
  }

  @override
  void didUpdateWidget(BeuiRulerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interacting) {
      _x.jump(_xFor(sliderCurrent));
    }
  }

  @override
  void dispose() {
    _momentum?.dispose();
    _momentum = null;
    _x
      ..removeListener(_onX)
      ..dispose();
    disposeSlider();
    super.dispose();
  }

  void _stopCoast() {
    _momentum?.stop();
    _lastMomentum = null;
    _vx = 0;
  }

  void _snapToTick() {
    final target = snapSliderValue(
      sliderMin + (-_x.value / widget.gap) * sliderStep,
      sliderMin,
      sliderMax,
      sliderStep,
    );
    final snapped = _xFor(target);
    final id = ++_gesture;
    if (beuiReduceMotion(context)) {
      _x.jump(snapped);
      _interacting = false;
      return;
    }
    _x.animateTo(snapped);
    void check() {
      if (!mounted) return;
      if (_x.isAnimating) {
        WidgetsBinding.instance.addPostFrameCallback((_) => check());
        return;
      }
      if (_gesture == id) _interacting = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => check());
  }

  void _onMomentum(Duration elapsed) {
    final last = _lastMomentum ?? elapsed;
    _lastMomentum = elapsed;
    var dt = (elapsed - last).inMicroseconds / 1e6;
    if (dt <= 0) return;
    dt = dt.clamp(0.0, 1 / 30);
    _vx *= math.exp(-dt / _inertiaTau);
    var next = _x.value + _vx * dt;
    if (next > 0) {
      next = 0;
      _vx = 0;
    } else if (next < -_maxOffset) {
      next = -_maxOffset;
      _vx = 0;
    }
    _x.jump(next);
    if (_vx.abs() < 8) {
      _stopCoast();
      if (!_holding) _snapToTick();
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.enabled) return;
    _gesture++;
    _interacting = true;
    _holding = true;
    _stopCoast();
    sliderFocus.requestFocus();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !_holding) return;
    _x.jump(_elastic(_x.value + details.delta.dx));
    _vx = details.primaryDelta != null
        ? details.primaryDelta! / (1 / 60)
        : _vx;
  }

  void _onDragEnd(DragEndDetails details) {
    _holding = false;
    final reduce = beuiReduceMotion(context);
    if (reduce) {
      _snapToTick();
      return;
    }
    _vx = (details.primaryVelocity ?? 0) * _inertiaPower;
    _lastMomentum = null;
    if (!(_momentum?.isActive ?? false)) _momentum?.start();
  }

  @override
  KeyEventResult sliderOnKey(FocusNode node, KeyEvent event) {
    _x.jump(_x.value);
    _stopCoast();
    _gesture++;
    _interacting = false;
    _holding = false;
    final result = super.sliderOnKey(node, event);
    if (result == KeyEventResult.handled && !_interacting) {
      _x.jump(_xFor(sliderCurrent));
    }
    return result;
  }

  List<_Tick> get _ticks {
    final whole = _span.floor();
    final remainder = _span - whole;
    final ticks = <_Tick>[
      for (var i = 0; i <= whole; i++)
        _Tick(
          value: double.parse(
            (sliderMin + i * sliderStep).toStringAsFixed(6),
          ),
          major: widget.majorEvery == 0 ? i == 0 : i % widget.majorEvery == 0,
          offset: i * widget.gap,
        ),
    ];
    if (remainder > 0) {
      ticks.add(
        _Tick(value: sliderMax, major: true, offset: _maxOffset),
      );
    }
    return ticks;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final focused = sliderFocus.hasFocus;
    final ticks = _ticks;
    final gap = widget.gap;

    return wrapSliderSemantics(
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: IgnorePointer(
          ignoring: !widget.enabled,
          child: Focus(
            focusNode: sliderFocus,
            canRequestFocus: widget.enabled,
            skipTraversal: !widget.enabled,
            onKeyEvent: sliderOnKey,
            child: MouseRegion(
              cursor: widget.enabled
                  ? (sliderDragging || _holding
                      ? SystemMouseCursors.grabbing
                      : SystemMouseCursors.grab)
                  : SystemMouseCursors.basic,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: focused
                      ? Border.all(
                          color: colors.foreground.withValues(alpha: 0.3),
                          width: 4,
                        )
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          spacing: 4,
                          children: [
                            Text(
                              _readout(sliderCurrent),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                color: colors.foreground,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            if (widget.unit != null)
                              Text(
                                widget.unit!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.mutedForeground,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragStart: _onDragStart,
                              onHorizontalDragUpdate: _onDragUpdate,
                              onHorizontalDragEnd: _onDragEnd,
                              onHorizontalDragCancel: () {
                                _holding = false;
                                if (beuiReduceMotion(context)) {
                                  _snapToTick();
                                }
                              },
                              child: ShaderMask(
                                shaderCallback: (rect) {
                                  return const LinearGradient(
                                    colors: [
                                      Color(0x00000000),
                                      Color(0xFF000000),
                                      Color(0xFF000000),
                                      Color(0x00000000),
                                    ],
                                    stops: [0, 0.18, 0.82, 1],
                                  ).createShader(rect);
                                },
                                blendMode: BlendMode.dstIn,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      left: constraints.maxWidth / 2 +
                                          _x.value -
                                          gap / 2,
                                      top: 0,
                                      bottom: 0,
                                      width: _maxOffset + gap,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          for (final tick in ticks)
                                            Positioned(
                                              left: tick.offset + gap / 2,
                                              bottom: 0,
                                              child: FractionalTranslation(
                                                translation:
                                                    const Offset(-0.5, 0),
                                                child: SizedBox(
                                                  height: 48,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                        width: 1,
                                                        height: tick.major
                                                            ? 28
                                                            : 14,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: tick.major
                                                              ? colors
                                                                  .foreground
                                                                  .withValues(
                                                                  alpha: 0.7,
                                                                )
                                                              : colors
                                                                  .foreground
                                                                  .withValues(
                                                                  alpha: 0.45,
                                                                ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            BeuiRadii.pill,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 18,
                                                        child: tick.major
                                                            ? Text(
                                                                _tickLabel(
                                                                  tick.value,
                                                                ),
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 10,
                                                                  color: colors
                                                                      .mutedForeground,
                                                                  fontFeatures:
                                                                      const [
                                                                    FontFeature
                                                                        .tabularFigures(),
                                                                  ],
                                                                ),
                                                              )
                                                            : null,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      left: constraints.maxWidth / 2 - 1.5,
                                      bottom: 20,
                                      child: IgnorePointer(
                                        child: Container(
                                          width: 3,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: colors.foreground,
                                            borderRadius:
                                                BorderRadius.circular(
                                              BeuiRadii.pill,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
    );
  }
}

class _Tick {
  const _Tick({
    required this.value,
    required this.major,
    required this.offset,
  });

  final double value;
  final bool major;
  final double offset;
}
