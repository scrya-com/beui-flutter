import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../physics/spring.dart';
import '../../tokens/colors.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import 'button.dart';

enum BeuiActionSwapAnimation { blur, roll, cascade }

class BeuiActionSwapItem {
  const BeuiActionSwapItem({
    required this.id,
    required this.label,
    this.icon,
    this.semanticLabel,
  });

  final String id;
  final String label;
  final Widget? icon;
  final String? semanticLabel;
}

const _kSwapBlur = 8.0;
const _kRollBlur = 3.0;
const _kCascadeStagger = 0.025;
const _kBlurMs = 200;
const _kRollExitMs = 140;
const _kCascadeExitMs = 160;

/// Label slot that swaps with blur, roll, or a per-letter cascade.
/// Port of `ActionSwapText` in `components/motion/action-swap.tsx`.
class BeuiActionSwapText extends StatefulWidget {
  const BeuiActionSwapText({
    super.key,
    required this.value,
    required this.text,
    this.animation = BeuiActionSwapAnimation.blur,
    this.style,
  });

  final String value;
  final String text;
  final BeuiActionSwapAnimation animation;
  final TextStyle? style;

  @override
  State<BeuiActionSwapText> createState() => _BeuiActionSwapTextState();
}

class _BeuiActionSwapTextState extends State<BeuiActionSwapText>
    with TickerProviderStateMixin {
  late String _incoming;
  String? _outgoing;
  late final AnimationController _enter;
  late final AnimationController _exit;

  @override
  void initState() {
    super.initState();
    _incoming = widget.text;
    _enter = AnimationController(
      vsync: this,
      duration: _enterDuration(widget.animation, widget.text),
      value: 1,
    )..addListener(_onTick);
    _exit = AnimationController(
      vsync: this,
      duration: _exitDuration(widget.animation, widget.text),
    )
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _outgoing = null);
        }
      });
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(BeuiActionSwapText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value && oldWidget.text == widget.text) {
      return;
    }
    _enter.duration = _enterDuration(widget.animation, widget.text);
    _exit.duration = _exitDuration(widget.animation, oldWidget.text);
    if (!beuiReduceMotion(context)) {
      _outgoing = _incoming;
      _exit.forward(from: 0);
      _enter.forward(from: 0);
    } else {
      _outgoing = null;
      _enter.value = 1;
    }
    _incoming = widget.text;
  }

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    final reduce = beuiReduceMotion(context);
    final fontSize = style.fontSize ?? 14;
    final pad = fontSize * 0.08;
    final cascade = widget.animation == BeuiActionSwapAnimation.cascade &&
        !reduce;

    Widget sizer;
    if (cascade) {
      sizer = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final ch in _incoming.split(''))
            Text(ch, style: style, softWrap: false),
        ],
      );
    } else {
      sizer = Text(_incoming, style: style, softWrap: false);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: pad),
      child: ClipRect(
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Opacity(opacity: 0, child: sizer),
            if (_outgoing != null)
              Positioned(
                left: 0,
                top: 0,
                child: _SwapLayer(
                  text: _outgoing!,
                  style: style,
                  animation: widget.animation,
                  progress: _exit.value,
                  exiting: true,
                  elapsed: _elapsed(_exit),
                ),
              ),
            Positioned(
              left: 0,
              top: 0,
              child: _SwapLayer(
                text: _incoming,
                style: style,
                animation: widget.animation,
                progress: _enter.value,
                exiting: false,
                elapsed: _elapsed(_enter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon slot that swaps with blur or roll (cascade maps to roll).
/// Port of `ActionSwapIcon`.
class BeuiActionSwapIcon extends StatefulWidget {
  const BeuiActionSwapIcon({
    super.key,
    required this.value,
    required this.child,
    this.animation = BeuiActionSwapAnimation.blur,
    this.size = 16,
  });

  final String value;
  final Widget child;
  final BeuiActionSwapAnimation animation;
  final double size;

  @override
  State<BeuiActionSwapIcon> createState() => _BeuiActionSwapIconState();
}

class _BeuiActionSwapIconState extends State<BeuiActionSwapIcon>
    with TickerProviderStateMixin {
  late Widget _incoming;
  Widget? _outgoing;
  late final AnimationController _enter;
  late final AnimationController _exit;

  BeuiActionSwapAnimation get _core =>
      widget.animation == BeuiActionSwapAnimation.cascade
          ? BeuiActionSwapAnimation.roll
          : widget.animation;

  @override
  void initState() {
    super.initState();
    _incoming = widget.child;
    _enter = AnimationController(
      vsync: this,
      duration: _enterDuration(_core, ''),
      value: 1,
    )..addListener(_onTick);
    _exit = AnimationController(
      vsync: this,
      duration: _exitDuration(_core, ''),
    )
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _outgoing = null);
        }
      });
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(BeuiActionSwapIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    _enter.duration = _enterDuration(_core, '');
    _exit.duration = _exitDuration(_core, '');
    if (!beuiReduceMotion(context)) {
      _outgoing = _incoming;
      _exit.forward(from: 0);
      _enter.forward(from: 0);
    } else {
      _outgoing = null;
      _enter.value = 1;
    }
    _incoming = widget.child;
  }

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_outgoing != null)
              _IconLayer(
                animation: _core,
                progress: _exit.value,
                exiting: true,
                elapsed: _elapsed(_exit),
                child: _outgoing!,
              ),
            _IconLayer(
              animation: _core,
              progress: _enter.value,
              exiting: false,
              elapsed: _elapsed(_enter),
              child: _incoming,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cycling action control. Port of `ActionSwapButton`.
class BeuiActionSwapButton extends StatefulWidget {
  const BeuiActionSwapButton({
    super.key,
    required this.items,
    this.value,
    this.initialValue,
    this.onChanged,
    this.variant = BeuiButtonVariant.secondary,
    this.size = BeuiButtonSize.md,
    this.animation = BeuiActionSwapAnimation.blur,
    this.iconOnly,
    this.cycle = true,
    this.enabled = true,
    this.onPressed,
  });

  final List<BeuiActionSwapItem> items;
  final String? value;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final BeuiButtonVariant variant;
  final BeuiButtonSize size;
  final BeuiActionSwapAnimation animation;
  final bool? iconOnly;
  final bool cycle;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  State<BeuiActionSwapButton> createState() => _BeuiActionSwapButtonState();
}

class _BeuiActionSwapButtonState extends State<BeuiActionSwapButton>
    with SingleTickerProviderStateMixin {
  late String _internal;
  late final BeuiSpringValue _scale;
  bool _hovered = false;
  bool _pressed = false;
  bool _scaleFrame = false;

  bool get _controlled => widget.value != null;
  String get _current => widget.value ?? _internal;
  bool get _iconOnly =>
      widget.iconOnly ?? widget.size == BeuiButtonSize.icon;
  bool get _canPress => widget.enabled && (widget.onPressed != null || widget.cycle);

  @override
  void initState() {
    super.initState();
    _internal = widget.initialValue ??
        (widget.items.isEmpty ? '' : widget.items.first.id);
    _scale = BeuiSpringValue(value: 1, spec: BeuiSpringSpec.press)..attach(this);
    _scale.addListener(_onScale);
  }

  void _onScale() {
    if (_scaleFrame) return;
    _scaleFrame = true;
    beuiAfterPointer(() {
      _scaleFrame = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scale.reducedMotion = beuiReduceMotion(context);
  }

  @override
  void dispose() {
    _scale
      ..removeListener(_onScale)
      ..dispose();
    super.dispose();
  }

  void _syncScale() {
    if (!mounted) return;
    if (beuiReduceMotion(context) || !_canPress) {
      _scale.jump(1);
      return;
    }
    if (_pressed) {
      _scale.animateTo(0.97);
    } else if (_hovered && beuiHoverCapable(context)) {
      _scale.animateTo(1.02);
    } else {
      _scale.animateTo(1);
    }
  }

  void _tap() {
    widget.onPressed?.call();
    if (!widget.enabled || !widget.cycle || widget.items.isEmpty) return;
    final idx = math.max(0, widget.items.indexWhere((i) => i.id == _current));
    final next = widget.items[(idx + 1) % widget.items.length];
    if (!_controlled) setState(() => _internal = next.id);
    widget.onChanged?.call(next.id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final colors = context.beuiColors;
    final idx = widget.items.indexWhere((i) => i.id == _current);
    final active = widget.items[idx < 0 ? 0 : idx];
    final hasIcon = widget.items.any((i) => i.icon != null);
    final metrics = _swapMetrics(widget.size);
    final (bg, fg, border) = _swapColors(widget.variant, colors, _hovered);

    final label = active.semanticLabel ??
        (_iconOnly ? active.label : null);

    return Semantics(
      button: true,
      enabled: _canPress,
      label: label,
      child: MouseRegion(
        cursor: _canPress ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          _hovered = true;
          beuiAfterPointer(_syncScale);
          beuiAfterPointer(() {
            if (mounted) setState(() {});
          });
        },
        onExit: (_) {
          _hovered = false;
          _pressed = false;
          beuiAfterPointer(_syncScale);
          beuiAfterPointer(() {
            if (mounted) setState(() {});
          });
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _canPress
              ? (_) {
                  _pressed = true;
                  _syncScale();
                }
              : null,
          onTapUp: _canPress
              ? (_) {
                  _pressed = false;
                  _syncScale();
                }
              : null,
          onTapCancel: () {
            _pressed = false;
            _syncScale();
          },
          onTap: _canPress ? _tap : null,
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.5,
            child: Transform.scale(
              scale: _scale.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: BeuiCurves.easeOut,
                height: metrics.height,
                width: metrics.width,
                padding: metrics.padding,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(BeuiRadii.pill),
                  border: Border.all(color: border),
                ),
                clipBehavior: Clip.hardEdge,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: fg,
                    fontSize: metrics.fontSize,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: fg, size: 16),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: metrics.gap,
                        children: [
                          if (hasIcon)
                            BeuiActionSwapIcon(
                              value: active.id,
                              animation: widget.animation,
                              child: active.icon ?? const SizedBox.shrink(),
                            ),
                          if (!_iconOnly)
                            BeuiActionSwapText(
                              value: active.id,
                              text: active.label,
                              animation: widget.animation,
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

class BeuiActionSwapBlurButton extends BeuiActionSwapButton {
  const BeuiActionSwapBlurButton({
    super.key,
    required super.items,
    super.value,
    super.initialValue,
    super.onChanged,
    super.variant,
    super.size,
    super.iconOnly,
    super.cycle,
    super.enabled,
    super.onPressed,
  }) : super(animation: BeuiActionSwapAnimation.blur);
}

class BeuiActionSwapRollButton extends BeuiActionSwapButton {
  const BeuiActionSwapRollButton({
    super.key,
    required super.items,
    super.value,
    super.initialValue,
    super.onChanged,
    super.variant,
    super.size,
    super.iconOnly,
    super.cycle,
    super.enabled,
    super.onPressed,
  }) : super(animation: BeuiActionSwapAnimation.roll);
}

class BeuiActionSwapCascadeButton extends BeuiActionSwapButton {
  const BeuiActionSwapCascadeButton({
    super.key,
    required super.items,
    super.value,
    super.initialValue,
    super.onChanged,
    super.variant,
    super.size,
    super.iconOnly,
    super.cycle,
    super.enabled,
    super.onPressed,
  }) : super(animation: BeuiActionSwapAnimation.cascade);
}

class BeuiActionSwapBlurText extends BeuiActionSwapText {
  const BeuiActionSwapBlurText({
    super.key,
    required super.value,
    required super.text,
    super.style,
  }) : super(animation: BeuiActionSwapAnimation.blur);
}

class BeuiActionSwapRollText extends BeuiActionSwapText {
  const BeuiActionSwapRollText({
    super.key,
    required super.value,
    required super.text,
    super.style,
  }) : super(animation: BeuiActionSwapAnimation.roll);
}

class BeuiActionSwapCascadeText extends BeuiActionSwapText {
  const BeuiActionSwapCascadeText({
    super.key,
    required super.value,
    required super.text,
    super.style,
  }) : super(animation: BeuiActionSwapAnimation.cascade);
}

class BeuiActionSwapBlurIcon extends BeuiActionSwapIcon {
  const BeuiActionSwapBlurIcon({
    super.key,
    required super.value,
    required super.child,
    super.size,
  }) : super(animation: BeuiActionSwapAnimation.blur);
}

class BeuiActionSwapRollIcon extends BeuiActionSwapIcon {
  const BeuiActionSwapRollIcon({
    super.key,
    required super.value,
    required super.child,
    super.size,
  }) : super(animation: BeuiActionSwapAnimation.roll);
}

class BeuiActionSwapCascadeIcon extends BeuiActionSwapIcon {
  const BeuiActionSwapCascadeIcon({
    super.key,
    required super.value,
    required super.child,
    super.size,
  }) : super(animation: BeuiActionSwapAnimation.cascade);
}

class _SwapLayer extends StatelessWidget {
  const _SwapLayer({
    required this.text,
    required this.style,
    required this.animation,
    required this.progress,
    required this.exiting,
    required this.elapsed,
  });

  final String text;
  final TextStyle style;
  final BeuiActionSwapAnimation animation;
  final double progress;
  final bool exiting;
  final double elapsed;

  @override
  Widget build(BuildContext context) {
    final reduce = beuiReduceMotion(context);
    if (reduce) return Text(text, style: style, softWrap: false);

    if (animation == BeuiActionSwapAnimation.cascade) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < text.length; i++)
            _letter(text[i], i),
        ],
      );
    }

    final pose = _textPose(animation, exiting, elapsed, progress);
    Widget child = Text(text, style: style, softWrap: false);
    child = _applyBlur(pose.blur, child);
    return Opacity(
      opacity: pose.opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, pose.yFrac * (style.fontSize ?? 14)),
        child: Transform.scale(
          scale: pose.scale,
          child: child,
        ),
      ),
    );
  }

  Widget _letter(String char, int i) {
    final delay = i * _kCascadeStagger;
    double opacity;
    double yFrac;
    double blur;
    if (exiting) {
      final t = BeuiCurves.easeOut.transform(
        ((elapsed - delay * 0.5) / (_kCascadeExitMs / 1000)).clamp(0.0, 1.0),
      );
      opacity = 1 - t;
      yFrac = -1.05 * t;
      blur = _kRollBlur * t;
    } else {
      final local = (elapsed - delay).clamp(0.0, 10.0);
      final t = local <= 0 ? 0.0 : beuiSpringEaseSpec(local, BeuiSpringSpec.swap);
      opacity = t.clamp(0.0, 1.0);
      yFrac = 1.05 * (1 - t);
      blur = _kRollBlur * (1 - t.clamp(0.0, 1.0));
    }
    Widget child = Text(char, style: style, softWrap: false);
    child = _applyBlur(blur, child);
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: FractionalTranslation(
        translation: Offset(0, yFrac),
        child: child,
      ),
    );
  }
}

class _IconLayer extends StatelessWidget {
  const _IconLayer({
    required this.animation,
    required this.progress,
    required this.exiting,
    required this.elapsed,
    required this.child,
  });

  final BeuiActionSwapAnimation animation;
  final double progress;
  final bool exiting;
  final double elapsed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = beuiReduceMotion(context);
    if (reduce) return child;
    final pose = _iconPose(animation, exiting, elapsed, progress);
    Widget painted = _applyBlur(pose.blur, child);
    return Opacity(
      opacity: pose.opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, pose.yPx),
        child: Transform.scale(scale: pose.scale, child: painted),
      ),
    );
  }
}

class _Pose {
  const _Pose({
    required this.opacity,
    required this.scale,
    required this.blur,
    this.yFrac = 0,
    this.yPx = 0,
  });
  final double opacity;
  final double scale;
  final double blur;
  final double yFrac;
  final double yPx;
}

_Pose _textPose(
  BeuiActionSwapAnimation animation,
  bool exiting,
  double elapsed,
  double progress,
) {
  if (animation == BeuiActionSwapAnimation.blur) {
    final t = Curves.easeInOut.transform(progress.clamp(0.0, 1.0));
    if (exiting) {
      return _Pose(
        opacity: 1 - t,
        scale: 1 + (0.94 - 1) * t,
        blur: _kSwapBlur * t,
      );
    }
    return _Pose(
      opacity: t,
      scale: 0.94 + (1 - 0.94) * t,
      blur: _kSwapBlur * (1 - t),
    );
  }
  if (exiting) {
    final t = BeuiCurves.easeOut.transform(
      (elapsed / (_kRollExitMs / 1000)).clamp(0.0, 1.0),
    );
    return _Pose(
      opacity: 1 - t,
      scale: 1,
      yFrac: -0.9 * t,
      blur: _kRollBlur * t,
    );
  }
  final t = beuiSpringEaseSpec(elapsed, BeuiSpringSpec.swap);
  return _Pose(
    opacity: t.clamp(0.0, 1.0),
    scale: 1,
    yFrac: 0.9 * (1 - t),
    blur: _kRollBlur * (1 - t.clamp(0.0, 1.0)),
  );
}

_Pose _iconPose(
  BeuiActionSwapAnimation animation,
  bool exiting,
  double elapsed,
  double progress,
) {
  if (animation == BeuiActionSwapAnimation.blur) {
    final t = Curves.easeInOut.transform(progress.clamp(0.0, 1.0));
    if (exiting) {
      return _Pose(
        opacity: 1 - t,
        scale: 1 + (0.25 - 1) * t,
        blur: _kSwapBlur * t,
      );
    }
    return _Pose(
      opacity: t,
      scale: 0.25 + (1 - 0.25) * t,
      blur: _kSwapBlur * (1 - t),
    );
  }
  if (exiting) {
    final t = BeuiCurves.easeOut.transform(
      (elapsed / (_kRollExitMs / 1000)).clamp(0.0, 1.0),
    );
    return _Pose(
      opacity: 1 - t,
      scale: 1,
      yPx: -12 * t,
      blur: _kRollBlur * t,
    );
  }
  final t = beuiSpringEaseSpec(elapsed, BeuiSpringSpec.swap);
  return _Pose(
    opacity: t.clamp(0.0, 1.0),
    scale: 1,
    yPx: 12 * (1 - t),
    blur: _kRollBlur * (1 - t.clamp(0.0, 1.0)),
  );
}

Widget _applyBlur(double sigma, Widget child) {
  final s = sigma.clamp(0.0, 10.0);
  if (s < 0.2) return child;
  return ImageFiltered(
    imageFilter: ImageFilter.blur(
      sigmaX: s,
      sigmaY: s,
      tileMode: TileMode.decal,
    ),
    child: child,
  );
}

double _elapsed(AnimationController c) {
  final d = c.duration ?? Duration.zero;
  return c.value * (d.inMicroseconds / 1e6);
}

Duration _enterDuration(BeuiActionSwapAnimation animation, String text) {
  switch (animation) {
    case BeuiActionSwapAnimation.blur:
      return const Duration(milliseconds: _kBlurMs);
    case BeuiActionSwapAnimation.roll:
      return beuiSpringSettleDuration(BeuiSpringSpec.swap);
    case BeuiActionSwapAnimation.cascade:
      final last = math.max(0, text.length - 1) * _kCascadeStagger;
      return beuiSpringSettleDuration(BeuiSpringSpec.swap) +
          Duration(milliseconds: (last * 1000).round());
  }
}

Duration _exitDuration(BeuiActionSwapAnimation animation, String text) {
  switch (animation) {
    case BeuiActionSwapAnimation.blur:
      return const Duration(milliseconds: _kBlurMs);
    case BeuiActionSwapAnimation.roll:
      return const Duration(milliseconds: _kRollExitMs);
    case BeuiActionSwapAnimation.cascade:
      final last = math.max(0, text.length - 1) * _kCascadeStagger * 0.5;
      return Duration(
        milliseconds: (last * 1000).round() + _kCascadeExitMs,
      );
  }
}

class _SwapSize {
  const _SwapSize({
    required this.height,
    this.width,
    required this.padding,
    required this.fontSize,
    required this.gap,
  });
  final double height;
  final double? width;
  final EdgeInsets padding;
  final double fontSize;
  final double gap;
}

_SwapSize _swapMetrics(BeuiButtonSize size) {
  switch (size) {
    case BeuiButtonSize.sm:
      return const _SwapSize(
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: 12),
        fontSize: 12,
        gap: 6,
      );
    case BeuiButtonSize.md:
      return const _SwapSize(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: 16),
        fontSize: 14,
        gap: 8,
      );
    case BeuiButtonSize.lg:
      return const _SwapSize(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: 20),
        fontSize: 16,
        gap: 10,
      );
    case BeuiButtonSize.icon:
      return const _SwapSize(
        height: 40,
        width: 40,
        padding: EdgeInsets.zero,
        fontSize: 14,
        gap: 0,
      );
  }
}

(Color, Color, Color) _swapColors(
  BeuiButtonVariant variant,
  BeuiColors colors,
  bool hovered,
) {
  switch (variant) {
    case BeuiButtonVariant.primary:
      return (colors.primary, colors.primaryForeground, colors.primary);
    case BeuiButtonVariant.secondary:
      return (colors.card, colors.foreground, colors.border);
    case BeuiButtonVariant.outline:
      return (
        hovered ? colors.primary.withValues(alpha: 0.05) : const Color(0x00000000),
        colors.foreground,
        colors.border,
      );
    case BeuiButtonVariant.ghost:
      return (
        hovered ? colors.primary.withValues(alpha: 0.05) : const Color(0x00000000),
        hovered ? colors.foreground : colors.mutedForeground,
        const Color(0x00000000),
      );
  }
}
