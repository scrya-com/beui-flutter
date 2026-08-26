import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

enum BeuiButtonVariant { primary, secondary, ghost, outline }

enum BeuiButtonSize { sm, md, lg, icon }

/// Spring-pressed button. Port of `components/motion/button/base.tsx`.
class BeuiButton extends StatefulWidget {
  const BeuiButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = BeuiButtonVariant.primary,
    this.size = BeuiButtonSize.md,
    this.pressScale = 0.93,
    this.ripple = false,
    this.enabled = true,
    this.busy = false,
    this.semanticLabel,
    this.surface,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final BeuiButtonVariant variant;
  final BeuiButtonSize size;
  final double pressScale;
  final bool ripple;
  final bool enabled;
  final bool busy;
  final String? semanticLabel;
  final Widget? surface;

  @override
  State<BeuiButton> createState() => _BeuiButtonState();
}

class _Ripple {
  _Ripple(this.id, this.origin, this.size);
  final int id;
  final Offset origin;
  final double size;
}

class _BeuiButtonState extends State<BeuiButton>
    with TickerProviderStateMixin {
  late final BeuiSpringValue _scale;
  bool _hovered = false;
  bool _pressed = false;
  int _rippleId = 0;
  final List<_Ripple> _ripples = [];

  bool get _canPress => widget.enabled && !widget.busy && widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _scale = BeuiSpringValue(value: 1, spec: BeuiSpringSpec.press)..attach(this);
    _scale.addListener(_onScale);
  }

  bool _scaleFrame = false;

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
      _scale.animateTo(widget.pressScale);
    } else if (_hovered && beuiHoverCapable(context)) {
      _scale.animateTo(1.02);
    } else {
      _scale.animateTo(1);
    }
  }

  void _addRipple(Offset local, Size size) {
    if (!widget.ripple || beuiReduceMotion(context)) return;
    final rippleSize = (size.longestSide) * 2;
    setState(() {
      _ripples.add(_Ripple(_rippleId++, local, rippleSize));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final metrics = _metrics(widget.size);

    final (bg, fg, border) = switch (widget.variant) {
      BeuiButtonVariant.primary => (
          colors.primary,
          colors.primaryForeground,
          colors.primary,
        ),
      BeuiButtonVariant.secondary => (
          colors.card,
          colors.foreground,
          colors.border,
        ),
      BeuiButtonVariant.ghost => (
          const Color(0x00000000),
          colors.mutedForeground,
          const Color(0x00000000),
        ),
      BeuiButtonVariant.outline => (
          const Color(0x00000000),
          colors.foreground,
          colors.border,
        ),
    };

    return Semantics(
      button: true,
      enabled: _canPress,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: _canPress ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          _hovered = true;
          beuiAfterPointer(_syncScale);
        },
        onExit: (_) {
          _hovered = false;
          _pressed = false;
          beuiAfterPointer(_syncScale);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _canPress
              ? (d) {
                  _pressed = true;
                  _syncScale();
                  _addRipple(d.localPosition, Size(metrics.width ?? metrics.minWidth, metrics.height));
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
          onTap: _canPress ? widget.onPressed : null,
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.5,
            child: Transform.scale(
              scale: _scale.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: BeuiCurves.easeOut,
                height: metrics.height,
                width: metrics.width,
                constraints: BoxConstraints(
                  minWidth: metrics.minWidth,
                  minHeight: metrics.height,
                ),
                padding: metrics.padding,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(metrics.radius),
                  border: Border.all(color: border),
                ),
                clipBehavior: widget.ripple ? Clip.antiAlias : Clip.none,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: fg,
                    fontSize: metrics.fontSize,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: fg, size: metrics.fontSize + 2),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (widget.surface != null)
                          Positioned.fill(child: widget.surface!),
                        if (widget.ripple && !reduce)
                          ..._ripples.map(
                            (r) => _RippleBurst(
                              key: ValueKey(r.id),
                              origin: r.origin,
                              size: r.size,
                              color: fg,
                              onDone: () {
                                setState(() {
                                  _ripples.removeWhere((x) => x.id == r.id);
                                });
                              },
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [_contentGap(widget.child, metrics.gap)],
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
    );
  }

  Widget _contentGap(Widget child, double gap) {
    if (child is Row) {
      return child;
    }
    return child;
  }
}

class _Size {
  const _Size({
    required this.height,
    this.width,
    required this.minWidth,
    required this.padding,
    required this.fontSize,
    required this.radius,
    required this.gap,
  });
  final double height;
  final double? width;
  final double minWidth;
  final EdgeInsets padding;
  final double fontSize;
  final double radius;
  final double gap;
}

_Size _metrics(BeuiButtonSize size) {
  switch (size) {
    case BeuiButtonSize.sm:
      return const _Size(
        height: 32,
        minWidth: 32,
        padding: EdgeInsets.symmetric(horizontal: 12),
        fontSize: 12,
        radius: BeuiRadii.pill,
        gap: 6,
      );
    case BeuiButtonSize.md:
      return const _Size(
        height: 40,
        minWidth: 40,
        padding: EdgeInsets.symmetric(horizontal: 20),
        fontSize: 14,
        radius: BeuiRadii.pill,
        gap: 8,
      );
    case BeuiButtonSize.lg:
      return const _Size(
        height: 48,
        minWidth: 48,
        padding: EdgeInsets.symmetric(horizontal: 24),
        fontSize: 16,
        radius: BeuiRadii.pill,
        gap: 8,
      );
    case BeuiButtonSize.icon:
      return const _Size(
        height: 32,
        width: 32,
        minWidth: 32,
        padding: EdgeInsets.zero,
        fontSize: 14,
        radius: BeuiRadii.icon,
        gap: 0,
      );
  }
}

class _RippleBurst extends StatefulWidget {
  const _RippleBurst({
    super.key,
    required this.origin,
    required this.size,
    required this.color,
    required this.onDone,
  });

  final Offset origin;
  final double size;
  final Color color;
  final VoidCallback onDone;

  @override
  State<_RippleBurst> createState() => _RippleBurstState();
}

class _RippleBurstState extends State<_RippleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = BeuiCurves.easeOut.transform(_c.value);
        final scale = 0.05 + (1 - 0.05) * t;
        final opacity = 0.3 * (1 - t);
        return Positioned(
          left: widget.origin.dx - widget.size / 2,
          top: widget.origin.dy - widget.size / 2,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
