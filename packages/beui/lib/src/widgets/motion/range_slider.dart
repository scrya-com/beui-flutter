import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../gestures/slider.dart';
import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

/// Bouncy grab feedback for the thumb scale only (`range-slider.tsx`).
const _thumbBounce = BeuiSpringSpec(
  stiffness: 500,
  damping: 14,
  mass: 0.7,
);

String beuiSliderNumber(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toString();
}

/// Shared value + drag/keyboard plumbing. Port of `useSlider`.
mixin BeuiSliderBinding<T extends StatefulWidget> on State<T> {
  double? get sliderBoundValue;
  double get sliderBoundInitial;
  ValueChanged<double>? get sliderBoundOnChanged;
  double get sliderBoundMin;
  double get sliderBoundMax;
  double get sliderBoundStep;
  bool get sliderBoundEnabled;
  String? get sliderBoundLabel;
  String? Function(double value)? get sliderBoundValueText;

  late double sliderInternal;
  bool sliderDragging = false;
  final FocusNode sliderFocus = FocusNode();

  bool get sliderControlled => sliderBoundValue != null;
  double get sliderMin => sliderBoundMin;
  double get sliderMax =>
      sliderBoundMax > sliderBoundMin ? sliderBoundMax : sliderBoundMin;
  double get sliderStep => sliderBoundStep > 0 ? sliderBoundStep : 1.0;
  double get sliderCurrent =>
      (sliderControlled ? sliderBoundValue! : sliderInternal)
          .clamp(sliderMin, sliderMax);
  double get sliderPercent => sliderMax > sliderMin
      ? ((sliderCurrent - sliderMin) / (sliderMax - sliderMin)) * 100
      : 0;

  void initSlider() {
    sliderInternal = sliderBoundInitial;
    sliderFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void disposeSlider() {
    sliderFocus.dispose();
  }

  /// Hook for fill/thumb springs after the number changes.
  void onSliderVisuals() {}

  void sliderCommit(double next) {
    final clean = snapSliderValue(next, sliderMin, sliderMax, sliderStep);
    if (!sliderControlled) sliderInternal = clean;
    if (mounted) setState(() {});
    sliderBoundOnChanged?.call(clean);
    onSliderVisuals();
  }

  void sliderCommitFromLocalX(double localX, double width) {
    if (width <= 0) return;
    final ratio = (localX / width).clamp(0.0, 1.0);
    sliderCommit(sliderMin + ratio * (sliderMax - sliderMin));
  }

  void sliderPointerDown(Offset local, double width) {
    if (!sliderBoundEnabled) return;
    sliderDragging = true;
    sliderFocus.requestFocus();
    sliderCommitFromLocalX(local.dx, width);
  }

  void sliderPointerMove(Offset local, double width) {
    if (!sliderDragging || !sliderBoundEnabled) return;
    sliderCommitFromLocalX(local.dx, width);
  }

  void sliderPointerUp() {
    if (!sliderDragging) return;
    sliderDragging = false;
    if (mounted) setState(() {});
    onSliderVisuals();
  }

  KeyEventResult sliderOnKey(FocusNode node, KeyEvent event) {
    if (!sliderBoundEnabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final current = sliderCurrent;
    final stride = sliderStep;
    final double? next = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight ||
      LogicalKeyboardKey.arrowUp =>
        current + stride,
      LogicalKeyboardKey.arrowLeft ||
      LogicalKeyboardKey.arrowDown =>
        current - stride,
      LogicalKeyboardKey.pageUp => current + stride * 10,
      LogicalKeyboardKey.pageDown => current - stride * 10,
      LogicalKeyboardKey.home => sliderMin,
      LogicalKeyboardKey.end => sliderMax,
      _ => null,
    };
    if (next == null) return KeyEventResult.ignored;
    sliderCommit(next);
    return KeyEventResult.handled;
  }

  Widget wrapSliderTrack({
    required double width,
    required Widget child,
    MouseCursor? cursor,
  }) {
    return Focus(
      focusNode: sliderFocus,
      canRequestFocus: sliderBoundEnabled,
      skipTraversal: !sliderBoundEnabled,
      onKeyEvent: sliderOnKey,
      child: MouseRegion(
        cursor: cursor ??
            (sliderBoundEnabled
                ? (sliderDragging
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.grab)
                : SystemMouseCursors.basic),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: sliderBoundEnabled
              ? (e) => sliderPointerDown(e.localPosition, width)
              : null,
          onPointerMove: sliderBoundEnabled
              ? (e) => sliderPointerMove(e.localPosition, width)
              : null,
          onPointerUp: sliderBoundEnabled ? (_) => sliderPointerUp() : null,
          onPointerCancel:
              sliderBoundEnabled ? (_) => sliderPointerUp() : null,
          child: child,
        ),
      ),
    );
  }

  Widget wrapSliderSemantics({required Widget child}) {
    final announced = sliderBoundValueText?.call(sliderCurrent);
    return Semantics(
      slider: true,
      enabled: sliderBoundEnabled,
      focusable: sliderBoundEnabled,
      focused: sliderFocus.hasFocus,
      label: sliderBoundLabel,
      value: announced ?? beuiSliderNumber(sliderCurrent),
      increasedValue: beuiSliderNumber(
        snapSliderValue(
          sliderCurrent + sliderStep,
          sliderMin,
          sliderMax,
          sliderStep,
        ),
      ),
      decreasedValue: beuiSliderNumber(
        snapSliderValue(
          sliderCurrent - sliderStep,
          sliderMin,
          sliderMax,
          sliderStep,
        ),
      ),
      onIncrease: sliderBoundEnabled
          ? () => sliderCommit(sliderCurrent + sliderStep)
          : null,
      onDecrease: sliderBoundEnabled
          ? () => sliderCommit(sliderCurrent - sliderStep)
          : null,
      child: child,
    );
  }
}

/// Tick-dotted track with a vertical-bar thumb. Port of `range-slider.tsx`.
class BeuiRangeSlider extends StatefulWidget {
  const BeuiRangeSlider({
    super.key,
    this.value,
    this.initialValue = 0,
    this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.enabled = true,
    this.showTicks = true,
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
  final bool showTicks;
  final String? semanticLabel;
  final String? Function(double value)? formatValueText;

  @override
  State<BeuiRangeSlider> createState() => _BeuiRangeSliderState();
}

class _BeuiRangeSliderState extends State<BeuiRangeSlider>
    with TickerProviderStateMixin, BeuiSliderBinding {
  late final BeuiFollowSpring _pos;
  late final BeuiSpringValue _thumbScale;
  bool _frame = false;

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
    _thumbScale = BeuiSpringValue(value: 1, spec: _thumbBounce)
      ..attach(this)
      ..addListener(_onTick);
  }

  void _onTick() {
    if (_frame) return;
    _frame = true;
    beuiAfterPointer(() {
      _frame = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _thumbScale.reducedMotion = beuiReduceMotion(context);
    onSliderVisuals();
  }

  @override
  void didUpdateWidget(BeuiRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    onSliderVisuals();
  }

  @override
  void onSliderVisuals() {
    final reduce = beuiReduceMotion(context);
    _pos.setTarget(sliderPercent, enabled: !reduce);
    _thumbScale.animateTo(sliderDragging && !reduce ? 1.35 : 1);
  }

  @override
  void dispose() {
    _pos
      ..removeListener(_onTick)
      ..dispose();
    _thumbScale
      ..removeListener(_onTick)
      ..dispose();
    disposeSlider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final steps = double.parse(
      ((sliderMax - sliderMin) / sliderStep).toStringAsFixed(6),
    ).floor();
    final ticks = widget.showTicks && steps > 0 && steps <= 50
        ? [
            for (var i = 0; i <= steps; i++)
              double.parse((sliderMin + i * sliderStep).toStringAsFixed(6)),
          ]
        : const <double>[];
    final focused = sliderFocus.hasFocus;

    return wrapSliderSemantics(
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: IgnorePointer(
          ignoring: !widget.enabled,
          child: SizedBox(
            height: 40,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final p = (_pos.value / 100).clamp(0.0, 1.0);
                return wrapSliderTrack(
                  width: w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(BeuiRadii.md),
                    child: ColoredBox(
                      color: colors.muted,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: w * p,
                            child: ColoredBox(
                              color: colors.foreground.withValues(alpha: 0.15),
                            ),
                          ),
                          Positioned(
                            left: 3,
                            right: 3,
                            top: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Stack(
                                children: [
                                  for (final tick in ticks)
                                    if (sliderMax > sliderMin)
                                      Positioned(
                                        left: ((tick - sliderMin) /
                                                (sliderMax - sliderMin)) *
                                            (w - 6) -
                                            2,
                                        top: 0,
                                        bottom: 0,
                                        child: Align(
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: colors.foreground
                                                  .withValues(alpha: 0.25),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: p * (w - 6),
                            top: 0,
                            bottom: 0,
                            child: Align(
                              child: Transform.scale(
                                scaleY: _thumbScale.value,
                                child: Container(
                                  width: 6,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: colors.foreground,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      const BoxShadow(
                                        color: Color(0x1A000000),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                      if (focused)
                                        BoxShadow(
                                          color: colors.foreground
                                              .withValues(alpha: 0.3),
                                          spreadRadius: 4,
                                        ),
                                    ],
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
              },
            ),
          ),
        ),
      ),
    );
  }
}
