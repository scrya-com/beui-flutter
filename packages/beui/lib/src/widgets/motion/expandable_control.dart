import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

/// Matches the Motion Patterns "Layout continuity" recipe
/// (`expandable-control.tsx` CONTINUITY_SPRING).
const _kContinuity = BeuiSpringSpec(
  stiffness: 220,
  damping: 17,
  mass: 0.85,
);

const _kPressScale = 0.97;

Widget _blur(Widget child, double sigma) {
  if (sigma <= 0.2) return child;
  return ImageFiltered(
    imageFilter: ImageFilter.blur(
      sigmaX: sigma.clamp(0.0, 10.0),
      sigmaY: sigma.clamp(0.0, 10.0),
    ),
    child: child,
  );
}

/// Click-to-expand button that reveals a label with layout continuity.
/// Port of `ExpandableButton` in `components/motion/expandable-control.tsx`.
class BeuiExpandableButton extends StatefulWidget {
  const BeuiExpandableButton({
    super.key,
    required this.icon,
    required this.label,
    this.expanded,
    this.initialExpanded = false,
    this.onExpandedChanged,
    this.onPressed,
    this.enabled = true,
    this.semanticLabel,
  });

  final Widget icon;
  final String label;
  final bool? expanded;
  final bool initialExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<BeuiExpandableButton> createState() => _BeuiExpandableButtonState();
}

class _BeuiExpandableButtonState extends State<BeuiExpandableButton>
    with TickerProviderStateMixin {
  late bool _internal;
  late final BeuiSpringValue _expand;
  late final BeuiSpringValue _press;
  bool _pressed = false;

  bool get _controlled => widget.expanded != null;
  bool get _expanded => widget.expanded ?? _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialExpanded;
    final t = (widget.expanded ?? _internal) ? 1.0 : 0.0;
    _expand = BeuiSpringValue(value: t, spec: _kContinuity)..attach(this);
    _press = BeuiSpringValue(value: 1, spec: _kContinuity)..attach(this);
    _expand.addListener(_tick);
    _press.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = beuiReduceMotion(context);
    _expand.reducedMotion = reduce;
    _press.reducedMotion = reduce;
  }

  @override
  void didUpdateWidget(BeuiExpandableButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != null && widget.expanded != oldWidget.expanded) {
      _expand.animateTo(widget.expanded! ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _expand
      ..removeListener(_tick)
      ..dispose();
    _press
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  void _toggle() {
    if (!widget.enabled) return;
    widget.onPressed?.call();
    final next = !_expanded;
    if (!_controlled) {
      setState(() => _internal = next);
      _expand.animateTo(next ? 1 : 0);
    }
    widget.onExpandedChanged?.call(next);
  }

  void _syncPress() {
    if (!mounted) return;
    if (beuiReduceMotion(context) || !widget.enabled) {
      _press.jump(1);
      return;
    }
    _press.animateTo(_pressed ? _kPressScale : 1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final t = _expand.value;
    final opacity = t.clamp(0.0, 1.0);
    final sigma = reduce ? 0.0 : 4 * (1 - opacity);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      expanded: _expanded,
      label: widget.semanticLabel ?? widget.label,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _toggle : null,
          onTapDown: widget.enabled
              ? (_) {
                  _pressed = true;
                  _syncPress();
                }
              : null,
          onTapUp: widget.enabled
              ? (_) {
                  _pressed = false;
                  _syncPress();
                }
              : null,
          onTapCancel: () {
            _pressed = false;
            _syncPress();
          },
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.5,
            child: Transform.scale(
              scale: _press.value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x00000000),
                  borderRadius: BorderRadius.circular(BeuiRadii.pill),
                  border: Border.all(color: colors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(BeuiRadii.pill),
                  child: SizedBox(
                    height: 44,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: IconTheme(
                                data: IconThemeData(
                                  color: colors.foreground,
                                  size: 16,
                                ),
                                child: widget.icon,
                              ),
                            ),
                          ),
                          ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: math.max(0.0, t),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Opacity(
                                  opacity: opacity,
                                  child: _blur(
                                    Text(
                                      widget.label,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colors.foreground,
                                        height: 1,
                                      ),
                                    ),
                                    sigma,
                                  ),
                                ),
                              ),
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
    );
  }
}

/// Chip that reveals a trailing action with layout continuity.
/// Port of `ExpandableChip` in `components/motion/expandable-control.tsx`.
class BeuiExpandableChip extends StatefulWidget {
  const BeuiExpandableChip({
    super.key,
    required this.label,
    required this.actionIcon,
    required this.actionLabel,
    this.onAction,
    this.collapseOnAction = true,
    this.expanded,
    this.initialExpanded = false,
    this.onExpandedChanged,
    this.enabled = true,
  });

  final String label;
  final Widget actionIcon;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool collapseOnAction;
  final bool? expanded;
  final bool initialExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final bool enabled;

  @override
  State<BeuiExpandableChip> createState() => _BeuiExpandableChipState();
}

class _BeuiExpandableChipState extends State<BeuiExpandableChip>
    with TickerProviderStateMixin {
  late bool _internal;
  late final BeuiSpringValue _expand;
  late final BeuiSpringValue _press;
  final FocusNode _triggerFocus = FocusNode();
  bool _pressed = false;

  bool get _controlled => widget.expanded != null;
  bool get _expanded => widget.expanded ?? _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialExpanded;
    final t = (widget.expanded ?? _internal) ? 1.0 : 0.0;
    _expand = BeuiSpringValue(value: t, spec: _kContinuity)..attach(this);
    _press = BeuiSpringValue(value: 1, spec: _kContinuity)..attach(this);
    _expand.addListener(_tick);
    _press.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = beuiReduceMotion(context);
    _expand.reducedMotion = reduce;
    _press.reducedMotion = reduce;
  }

  @override
  void didUpdateWidget(BeuiExpandableChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != null && widget.expanded != oldWidget.expanded) {
      _expand.animateTo(widget.expanded! ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _triggerFocus.dispose();
    _expand
      ..removeListener(_tick)
      ..dispose();
    _press
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  void _setExpanded(bool next) {
    if (!widget.enabled) return;
    if (!_controlled) {
      setState(() => _internal = next);
      _expand.animateTo(next ? 1 : 0);
    }
    widget.onExpandedChanged?.call(next);
  }

  void _onAction() {
    if (!widget.enabled || !_expanded) return;
    widget.onAction?.call();
    if (widget.collapseOnAction) {
      _setExpanded(false);
      _triggerFocus.requestFocus();
    }
  }

  void _syncPress() {
    if (!mounted) return;
    if (beuiReduceMotion(context) || !widget.enabled) {
      _press.jump(1);
      return;
    }
    _press.animateTo(_pressed ? _kPressScale : 1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final t = _expand.value;
    final opacity = t.clamp(0.0, 1.0);
    final sigma = reduce ? 0.0 : 4 * (1 - opacity);
    final labelRight = 12 - 8 * opacity;
    final actionOpen = _expanded && widget.enabled;

    return Focus(
      focusNode: _triggerFocus,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x00000000),
          borderRadius: BorderRadius.circular(BeuiRadii.pill),
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BeuiRadii.pill),
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MouseRegion(
                  cursor: widget.enabled
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.enabled
                        ? () => _setExpanded(!_expanded)
                        : null,
                    child: Opacity(
                      opacity: widget.enabled ? 1 : 0.5,
                      child: Padding(
                        padding: EdgeInsets.only(left: 12, right: labelRight),
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.foreground,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: math.max(0.0, t),
                    child: Opacity(
                      opacity: opacity,
                      child: _blur(
                        Transform.scale(
                          scale: _press.value,
                          child: MouseRegion(
                            cursor: actionOpen
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.basic,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: actionOpen ? _onAction : null,
                              onTapDown: actionOpen
                                  ? (_) {
                                      _pressed = true;
                                      _syncPress();
                                    }
                                  : null,
                              onTapUp: actionOpen
                                  ? (_) {
                                      _pressed = false;
                                      _syncPress();
                                    }
                                  : null,
                              onTapCancel: () {
                                _pressed = false;
                                _syncPress();
                              },
                              child: Semantics(
                                button: true,
                                enabled: actionOpen,
                                label: widget.actionLabel,
                                child: SizedBox(
                                  width: 32,
                                  height: 40,
                                  child: Center(
                                    child: IconTheme(
                                      data: IconThemeData(
                                        color: colors.mutedForeground,
                                        size: 14,
                                      ),
                                      child: widget.actionIcon,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        sigma,
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
