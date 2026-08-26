import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/colors.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

const _arrowOpacity = [1.0, 0.78, 0.54, 0.32, 0.16];

/// Hover/focus expands a lime accent into a trail of dotted chevrons.
/// Port of `expanding-arrow-button.tsx`.
class BeuiExpandingArrowButton extends StatefulWidget {
  const BeuiExpandingArrowButton({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<BeuiExpandingArrowButton> createState() =>
      _BeuiExpandingArrowButtonState();
}

class _BeuiExpandingArrowButtonState extends State<BeuiExpandingArrowButton>
    with TickerProviderStateMixin {
  late final BeuiSpringValue _width;
  late final BeuiSpringValue _press;
  late final AnimationController _reveal;
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _canPress => widget.enabled && widget.onPressed != null;
  bool get _active =>
      widget.enabled &&
      ((_hovered && beuiHoverCapable(context)) || _focused);

  @override
  void initState() {
    super.initState();
    _width = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)
      ..attach(this)
      ..addListener(_onTick);
    _press = BeuiSpringValue(value: 1, spec: BeuiSpringSpec.press)
      ..attach(this)
      ..addListener(_onTick);
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = beuiReduceMotion(context);
    _width.reducedMotion = reduce;
    _press.reducedMotion = reduce;
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    final reduce = beuiReduceMotion(context);
    _width.animateTo(_active ? 1 : 0);
    if (_pressed && _canPress && !reduce) {
      _press.animateTo(0.97);
    } else {
      _press.animateTo(1);
    }
    if (_active) {
      _reveal.duration = Duration(milliseconds: reduce ? 0 : 280);
      _reveal.forward();
    } else {
      _reveal.duration = Duration(milliseconds: reduce ? 0 : 180);
      _reveal.reverse();
    }
  }

  @override
  void dispose() {
    _width
      ..removeListener(_onTick)
      ..dispose();
    _press
      ..removeListener(_onTick)
      ..dispose();
    _reveal
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final shell = BeuiColors.light.primary;
    final onShell = BeuiColors.light.primaryForeground;
    final lime = colors.neon;
    final t = _width.value.clamp(0.0, 1.0);
    final idleOpacity = reduce
        ? (_active ? 0.0 : 1.0)
        : (1 - _reveal.value).clamp(0.0, 1.0);
    final labelOpacity = reduce
        ? (_active ? 0.0 : 1.0)
        : (1 - _reveal.value).clamp(0.0, 1.0);
    final labelShift = reduce || !_active ? 0.0 : 6.0 * _reveal.value;

    return Semantics(
      button: true,
      enabled: _canPress,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor:
            _canPress ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          _hovered = true;
          beuiAfterPointer(_sync);
        },
        onExit: (_) {
          _hovered = false;
          _pressed = false;
          beuiAfterPointer(_sync);
        },
        child: Focus(
          canRequestFocus: widget.enabled,
          onFocusChange: (focused) {
            _focused = focused;
            _sync();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _canPress
                ? (_) {
                    _pressed = true;
                    _sync();
                  }
                : null,
            onTapUp: _canPress
                ? (_) {
                    _pressed = false;
                    _sync();
                  }
                : null,
            onTapCancel: () {
              _pressed = false;
              _sync();
            },
            onTap: _canPress ? widget.onPressed : null,
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final accentWidth =
                            52 + (constraints.maxWidth - 12 - 52) * t;
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: shell,
                            borderRadius: BorderRadius.circular(22),
                            border: _focused
                                ? Border.all(color: lime, width: 2)
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 6,
                                  top: 6,
                                  bottom: 6,
                                  width: accentWidth,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: ColoredBox(
                                      color: lime,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Opacity(
                                            opacity: idleOpacity,
                                            child: Center(
                                              child: IconTheme(
                                                data: IconThemeData(color: shell),
                                                child: const _DottedChevron(),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                for (var i = 0;
                                                    i < _arrowOpacity.length;
                                                    i++)
                                                  _StaggerChevron(
                                                    index: i,
                                                    active: _active,
                                                    progress: _reveal.value,
                                                    reduce: reduce,
                                                    color: shell.withValues(
                                                      alpha: _arrowOpacity[i],
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
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    76,
                                    0,
                                    20,
                                    0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Opacity(
                                      opacity: labelOpacity,
                                      child: Transform.translate(
                                        offset: Offset(labelShift, 0),
                                        child: DefaultTextStyle(
                                          style: TextStyle(
                                            color: onShell,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.36,
                                            height: 1,
                                          ),
                                          child: widget.child,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggerChevron extends StatelessWidget {
  const _StaggerChevron({
    required this.index,
    required this.active,
    required this.progress,
    required this.reduce,
    required this.color,
  });

  final int index;
  final bool active;
  final double progress;
  final bool reduce;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final delay = 0.04 + index * 0.025;
    double t;
    if (reduce) {
      t = active ? 1 : 0;
    } else if (active) {
      final start = delay / 0.28;
      final end = (delay + 0.18) / 0.28;
      t = end == start ? progress : ((progress - start) / (end - start)).clamp(0.0, 1.0);
      t = BeuiCurves.easeOut.transform(t);
    } else {
      t = BeuiCurves.easeOut.transform(progress);
    }
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(-6 * (1 - t), 0),
        child: IconTheme(
          data: IconThemeData(color: color),
          child: const _DottedChevron(),
        ),
      ),
    );
  }
}

class _DottedChevron extends StatelessWidget {
  const _DottedChevron();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ??
        DefaultTextStyle.of(context).style.color ??
        BeuiColors.light.primary;
    return CustomPaint(
      size: const Size(20, 28),
      painter: _DotsPainter(color),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const dots = [
      Offset(4, 4),
      Offset(10, 9),
      Offset(16, 14),
      Offset(10, 19),
      Offset(4, 24),
    ];
    final sx = size.width / 20;
    final sy = size.height / 28;
    for (final d in dots) {
      canvas.drawCircle(Offset(d.dx * sx, d.dy * sy), 2 * sx, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) => oldDelegate.color != color;
}
