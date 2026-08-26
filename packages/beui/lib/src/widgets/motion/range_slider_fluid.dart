import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import 'range_slider.dart';

/// Thumbless pill slider with a clipped liquid fill.
/// Port of `range-slider-fluid.tsx`.
class BeuiFluidSlider extends StatefulWidget {
  const BeuiFluidSlider({
    super.key,
    this.value,
    this.initialValue = 0,
    this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.enabled = true,
    this.label,
    this.format = _defaultFormat,
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
  final String? label;
  final String Function(double value) format;
  final String? semanticLabel;
  final String? Function(double value)? formatValueText;

  static String _defaultFormat(double value) => '${beuiSliderNumber(value)}%';

  @override
  State<BeuiFluidSlider> createState() => _BeuiFluidSliderState();
}

class _BeuiFluidSliderState extends State<BeuiFluidSlider>
    with TickerProviderStateMixin, BeuiSliderBinding {
  late final BeuiFollowSpring _pos;
  late final BeuiSpringValue _scale;

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
  String? get sliderBoundLabel => widget.semanticLabel ?? widget.label;
  @override
  String? Function(double value)? get sliderBoundValueText =>
      widget.formatValueText ?? widget.format;

  @override
  void initState() {
    super.initState();
    initSlider();
    _pos = BeuiFollowSpring(
      value: sliderPercent,
      spec: BeuiSpringSpec.glide,
    )
      ..attach(this)
      ..addListener(_onTick);
    _scale = BeuiSpringValue(value: 1, spec: BeuiSpringSpec.press)
      ..attach(this)
      ..addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scale.reducedMotion = beuiReduceMotion(context);
    onSliderVisuals();
  }

  @override
  void didUpdateWidget(BeuiFluidSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    onSliderVisuals();
  }

  @override
  void onSliderVisuals() {
    final reduce = beuiReduceMotion(context);
    _pos.setTarget(sliderPercent, enabled: !reduce);
    _scale.animateTo(sliderDragging && !reduce ? 1.03 : 1);
  }

  @override
  void dispose() {
    _pos
      ..removeListener(_onTick)
      ..dispose();
    _scale
      ..removeListener(_onTick)
      ..dispose();
    disposeSlider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final t = (_pos.value / 100).clamp(0.0, 1.0);
    final focused = sliderFocus.hasFocus;
    final row = _FluidRow(
      label: widget.label,
      value: widget.format(sliderCurrent),
    );

    return wrapSliderSemantics(
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: IgnorePointer(
          ignoring: !widget.enabled,
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return wrapSliderTrack(
                  width: constraints.maxWidth,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(BeuiRadii.pill),
                      child: ColoredBox(
                        color: colors.muted,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DefaultTextStyle(
                              style: TextStyle(
                                color: colors.foreground,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                              child: row,
                            ),
                            ClipPath(
                              clipper: _FluidClip(t),
                              child: ColoredBox(
                                color: colors.foreground,
                                child: DefaultTextStyle(
                                  style: TextStyle(
                                    color: colors.background,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                  child: row,
                                ),
                              ),
                            ),
                            if (focused)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(BeuiRadii.pill),
                                  border: Border.all(
                                    color: colors.foreground
                                        .withValues(alpha: 0.4),
                                    width: 4,
                                  ),
                                ),
                              ),
                          ],
                        ),
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

class _FluidRow extends StatelessWidget {
  const _FluidRow({required this.label, required this.value});

  final String? label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _FluidClip extends CustomClipper<Path> {
  _FluidClip(this.t);

  final double t;

  @override
  Path getClip(Size size) {
    final width = size.width * t;
    if (width <= 0) return Path();
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, size.height),
          Radius.circular(size.height),
        ),
      );
  }

  @override
  bool shouldReclip(_FluidClip oldClipper) => oldClipper.t != t;
}
