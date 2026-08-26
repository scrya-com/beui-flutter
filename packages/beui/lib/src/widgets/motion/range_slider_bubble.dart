import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import 'range_slider.dart';

/// Loose enough that the bubble keeps leaning a beat after the pointer stops.
const _tiltSpring = BeuiSpringSpec(
  stiffness: 260,
  damping: 22,
  mass: 0.4,
);

/// Drag speed (percent/s) that maxes out lean and squash.
const _fullTilt = 320.0;

/// Value bubble that pops out of the thumb on grab.
/// Port of `range-slider-bubble.tsx`.
class BeuiBubbleSlider extends StatefulWidget {
  const BeuiBubbleSlider({
    super.key,
    this.value,
    this.initialValue = 0,
    this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.enabled = true,
    this.format,
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
  final String Function(double value)? format;
  final String? semanticLabel;
  final String? Function(double value)? formatValueText;

  @override
  State<BeuiBubbleSlider> createState() => _BeuiBubbleSliderState();
}

class _BeuiBubbleSliderState extends State<BeuiBubbleSlider>
    with TickerProviderStateMixin, BeuiSliderBinding {
  late final BeuiFollowSpring _pos;
  late final BeuiFollowSpring _lean;
  late final BeuiSpringValue _thumbScale;
  late final BeuiSpringValue _bubbleScale;
  late final BeuiSpringValue _bubbleY;
  late final AnimationController _bubbleOpacity;
  Duration? _stamp;
  double _lastPos = 0;
  bool _bubbleMounted = false;
  bool _wasDragging = false;

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
      widget.formatValueText ?? widget.format;

  @override
  void initState() {
    super.initState();
    initSlider();
    _lastPos = sliderPercent;
    _pos = BeuiFollowSpring(
      value: sliderPercent,
      spec: BeuiSpringSpec.glide,
    )
      ..attach(this)
      ..addListener(_onPos);
    _lean = BeuiFollowSpring(spec: _tiltSpring)
      ..attach(this)
      ..addListener(_onTick);
    _thumbScale = BeuiSpringValue(value: 1, spec: BeuiSpringSpec.press)
      ..attach(this)
      ..addListener(_onTick);
    _bubbleScale = BeuiSpringValue(value: 0.4, spec: BeuiSpringSpec.panel)
      ..attach(this)
      ..addListener(_onTick);
    _bubbleY = BeuiSpringValue(value: 10, spec: BeuiSpringSpec.panel)
      ..attach(this)
      ..addListener(_onTick);
    _bubbleOpacity = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _onPos() {
    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    if (_stamp != null) {
      final dt = (now - _stamp!).inMicroseconds / 1e6;
      if (dt > 1e-6) {
        final velocity = (_pos.value - _lastPos) / dt;
        final reduce = beuiReduceMotion(context);
        _lean.setTarget(
          (-velocity / _fullTilt).clamp(-1.0, 1.0),
          enabled: !reduce,
        );
      }
    }
    _stamp = now;
    _lastPos = _pos.value;
    _onTick();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = beuiReduceMotion(context);
    _thumbScale.reducedMotion = reduce;
    _bubbleScale.reducedMotion = reduce;
    _bubbleY.reducedMotion = reduce;
    onSliderVisuals();
  }

  @override
  void didUpdateWidget(BeuiBubbleSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    onSliderVisuals();
  }

  @override
  void onSliderVisuals() {
    final reduce = beuiReduceMotion(context);
    _pos.setTarget(sliderPercent, enabled: !reduce);
    _thumbScale.animateTo(sliderDragging && !reduce ? 1.25 : 1);
    if (sliderDragging == _wasDragging) return;
    _wasDragging = sliderDragging;
    if (sliderDragging) {
      _bubbleMounted = true;
      _bubbleOpacity.duration = const Duration(milliseconds: 120);
      _bubbleOpacity.forward();
      _bubbleScale.animateTo(1);
      _bubbleY.animateTo(0);
    } else {
      if (!reduce) {
        _lean.setTarget(0);
      } else {
        _lean.jump(0);
      }
      _bubbleScale.animateTo(0.5);
      _bubbleY.animateTo(8);
      _bubbleOpacity.duration = const Duration(milliseconds: 120);
      _bubbleOpacity.reverse().whenComplete(() {
        if (!mounted || sliderDragging) return;
        setState(() => _bubbleMounted = false);
      });
    }
  }

  @override
  void dispose() {
    _pos
      ..removeListener(_onPos)
      ..dispose();
    _lean
      ..removeListener(_onTick)
      ..dispose();
    _thumbScale
      ..removeListener(_onTick)
      ..dispose();
    _bubbleScale
      ..removeListener(_onTick)
      ..dispose();
    _bubbleY
      ..removeListener(_onTick)
      ..dispose();
    _bubbleOpacity
      ..removeListener(_onTick)
      ..dispose();
    disposeSlider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final focused = sliderFocus.hasFocus;
    final readout = widget.format != null
        ? widget.format!(sliderCurrent)
        : beuiSliderNumber(sliderCurrent);
    final lean = _lean.value;
    final tilt = lean * 16 * math.pi / 180;
    final squash = 1 + lean.abs() * 0.18;
    final stretch = 1 - lean.abs() * 0.12;

    return wrapSliderSemantics(
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: IgnorePointer(
          ignoring: !widget.enabled,
          child: SizedBox(
            height: 80,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 48,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final p = (_pos.value / 100).clamp(0.0, 1.0);
                      return wrapSliderTrack(
                        width: w,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 20,
                              height: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.muted,
                                  borderRadius:
                                      BorderRadius.circular(BeuiRadii.pill),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              bottom: 20,
                              height: 8,
                              width: w * p,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.foreground,
                                  borderRadius:
                                      BorderRadius.circular(BeuiRadii.pill),
                                ),
                              ),
                            ),
                            Positioned(
                              left: p * w - 10,
                              bottom: 14,
                              child: Transform.scale(
                                scale: _thumbScale.value,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: colors.background,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.foreground,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1A000000),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_bubbleMounted)
                              Positioned(
                                left: p * w,
                                bottom: 36,
                                child: FractionalTranslation(
                                  translation: const Offset(-0.5, 0),
                                  child: IgnorePointer(
                                    child: Opacity(
                                      opacity: _bubbleOpacity.value,
                                      child: Transform.translate(
                                        offset: Offset(
                                          0,
                                          reduce ? 0 : _bubbleY.value,
                                        ),
                                        child: Transform.rotate(
                                          angle: reduce ? 0 : tilt,
                                          alignment: Alignment.bottomCenter,
                                          child: Transform.scale(
                                            scaleX: reduce
                                                ? _bubbleScale.value
                                                : _bubbleScale.value * squash,
                                            scaleY: reduce
                                                ? _bubbleScale.value
                                                : _bubbleScale.value * stretch,
                                            alignment: Alignment.bottomCenter,
                                            child: _ValueBubble(
                                              text: readout,
                                              foreground: colors.foreground,
                                              background: colors.background,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (focused)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: -20,
                                bottom: -20,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(BeuiRadii.pill),
                                    border: Border.all(
                                      color: colors.foreground
                                          .withValues(alpha: 0.3),
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
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

class _ValueBubble extends StatelessWidget {
  const _ValueBubble({
    required this.text,
    required this.foreground,
    required this.background,
  });

  final String text;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: foreground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              text,
              style: TextStyle(
                color: background,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -4),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: foreground,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
