import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../physics/spring.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import 'range_slider.dart';

/// Per-bar spring: soft enough that the crest wobbles as it travels.
const _barSpring = BeuiSpringSpec(
  stiffness: 420,
  damping: 20,
  mass: 0.5,
);

const _spread = 2.6;

/// Equalizer bars that peak around the handle. Port of `range-slider-wave.tsx`.
class BeuiWaveSlider extends StatefulWidget {
  const BeuiWaveSlider({
    super.key,
    this.value,
    this.initialValue = 0,
    this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.enabled = true,
    this.bars = 32,
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
  final int bars;
  final String? semanticLabel;
  final String? Function(double value)? formatValueText;

  @override
  State<BeuiWaveSlider> createState() => _BeuiWaveSliderState();
}

class _BeuiWaveSliderState extends State<BeuiWaveSlider>
    with TickerProviderStateMixin, BeuiSliderBinding {
  late List<double> _heights;
  late List<double> _velocities;
  Ticker? _ticker;
  Duration? _last;

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
      widget.formatValueText;

  int get _n => math.max(widget.bars, 1);

  @override
  void initState() {
    super.initState();
    initSlider();
    _heights = List<double>.filled(_n, 0.22);
    _velocities = List<double>.filled(_n, 0);
    _ticker = createTicker(_tick);
    _ticker!.start();
  }

  @override
  void didUpdateWidget(BeuiWaveSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bars != widget.bars) {
      _heights = List<double>.filled(_n, 0.22);
      _velocities = List<double>.filled(_n, 0);
    }
    onSliderVisuals();
  }

  List<double> _targets(bool reduce) {
    final head = (sliderPercent / 100) * (_n - 1);
    return [
      for (var i = 0; i < _n; i++)
        reduce
            ? 0.4
            : 0.22 +
                math.exp(
                      -math.pow(i - head, 2) / (2 * _spread * _spread),
                    ) *
                    (sliderDragging ? 0.78 : 0.6),
    ];
  }

  void _tick(Duration elapsed) {
    final last = _last ?? elapsed;
    _last = elapsed;
    var dt = (elapsed - last).inMicroseconds / 1e6;
    if (dt <= 0) return;
    dt = dt.clamp(0.0, 1 / 30);
    final reduce = beuiReduceMotion(context);
    final targets = _targets(reduce);
    var moving = false;
    for (var i = 0; i < _n; i++) {
      if (reduce) {
        _heights[i] = targets[i];
        _velocities[i] = 0;
        continue;
      }
      final step = beuiSpringStep(
        value: _heights[i],
        velocity: _velocities[i],
        target: targets[i],
        spec: _barSpring,
        dt: dt,
      );
      _heights[i] = step.value;
      _velocities[i] = step.velocity;
      if ((step.value - targets[i]).abs() > 0.002 ||
          step.velocity.abs() > 0.01) {
        moving = true;
      }
    }
    if (mounted) setState(() {});
    if (!moving && !sliderDragging) {
      _ticker?.stop();
      _last = null;
    }
  }

  @override
  void onSliderVisuals() {
    if (!(_ticker?.isActive ?? false)) {
      _last = null;
      _ticker?.start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    disposeSlider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final focused = sliderFocus.hasFocus;
    final head = (sliderPercent / 100) * (_n - 1);

    return wrapSliderSemantics(
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: IgnorePointer(
          ignoring: !widget.enabled,
          child: SizedBox(
            height: 80,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return wrapSliderTrack(
                  width: constraints.maxWidth,
                  child: DecoratedBox(
                    decoration: focused
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.foreground.withValues(alpha: 0.3),
                              width: 4,
                            ),
                          )
                        : const BoxDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _n; i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            Expanded(
                              child: Align(
                                child: Transform.scale(
                                  scaleY: _heights[i].clamp(0.05, 1.2),
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: i <= head.round()
                                          ? colors.foreground
                                          : colors.foreground
                                              .withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(
                                        BeuiRadii.pill,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
