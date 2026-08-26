import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/colors.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

/// Animation used by [BeuiThemeToggle]. Port of `ThemeVariant`.
enum BeuiThemeToggleVariant { rectangle, circle, circleBlur, blinds }

/// Clip origin for rectangle / circle reveals. Port of `RectStart`.
enum BeuiThemeToggleStart {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
  bottomUp,
}

/// Material standard curve used by the circle view-transition variants.
const _kCircleReveal = Cubic(0.4, 0.0, 0.2, 1.0);

/// Blinds tile width (`mask-size: 72px`) and the 20px feather in `theme-toggle.tsx`.
const _kSlat = 72.0;
const _kSlatFeather = 20.0;

class _ThemeToggleScope extends InheritedWidget {
  const _ThemeToggleScope({
    required this.brightness,
    required this.requestToggle,
    required super.child,
  });

  final Brightness brightness;
  final void Function({
    required BeuiThemeToggleVariant variant,
    required BeuiThemeToggleStart start,
    required Offset origin,
  })
  requestToggle;

  static _ThemeToggleScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ThemeToggleScope>();

  @override
  bool updateShouldNotify(_ThemeToggleScope oldWidget) =>
      brightness != oldWidget.brightness;
}

/// Local surface whose brightness is flipped with a clip-path reveal overlay.
///
/// Flutter has no View Transition API; the incoming theme is clipped in from
/// [BeuiThemeToggle] via [Overlay] (or an in-tree stack if none exists).
class BeuiThemeToggleScope extends StatefulWidget {
  const BeuiThemeToggleScope({
    super.key,
    required this.child,
    this.brightness,
    this.initialBrightness = Brightness.dark,
    this.onChanged,
  });

  final Widget child;
  final Brightness? brightness;
  final Brightness initialBrightness;
  final ValueChanged<Brightness>? onChanged;

  @override
  State<BeuiThemeToggleScope> createState() => _BeuiThemeToggleScopeState();
}

class _BeuiThemeToggleScopeState extends State<BeuiThemeToggleScope>
    with SingleTickerProviderStateMixin {
  late Brightness _internal;
  late final AnimationController _reveal;
  OverlayEntry? _entry;
  OverlayState? _overlay;
  final GlobalKey _boxKey = GlobalKey();

  bool _revealing = false;
  Brightness _incoming = Brightness.light;
  BeuiThemeToggleVariant _variant = BeuiThemeToggleVariant.rectangle;
  BeuiThemeToggleStart _start = BeuiThemeToggleStart.bottomUp;
  Offset _originFrac = const Offset(0.5, 1);

  bool get _controlled => widget.brightness != null;
  Brightness get _shown => _controlled ? widget.brightness! : _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialBrightness;
    _reveal = AnimationController(vsync: this)
      ..addListener(_paintReveal)
      ..addStatusListener(_onRevealStatus);
  }

  void _paintReveal() {
    if (!mounted) return;
    if (_entry != null) {
      _entry!.markNeedsBuild();
    } else if (_revealing) {
      setState(() {});
    }
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!mounted || !_revealing) return;
    widget.onChanged?.call(_incoming);
    setState(() {
      if (!_controlled) _internal = _incoming;
      _revealing = false;
    });
    _entry?.remove();
    _entry = null;
    _reveal.value = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
  }

  @override
  void didUpdateWidget(BeuiThemeToggleScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.brightness != oldWidget.brightness && _controlled) {
      _internal = widget.brightness!;
    }
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _reveal
      ..removeListener(_paintReveal)
      ..removeStatusListener(_onRevealStatus)
      ..dispose();
    super.dispose();
  }

  void _toggle({
    required BeuiThemeToggleVariant variant,
    required BeuiThemeToggleStart start,
    required Offset origin,
  }) {
    if (_revealing) return;
    final next = _shown == Brightness.dark ? Brightness.light : Brightness.dark;
    if (beuiReduceMotion(context)) {
      if (!_controlled) setState(() => _internal = next);
      widget.onChanged?.call(next);
      return;
    }

    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    Offset frac = const Offset(0.5, 1);
    if (box != null && box.hasSize && box.size.longestSide > 0) {
      final local = box.globalToLocal(origin);
      frac = Offset(
        (local.dx / box.size.width).clamp(0.0, 1.0),
        (local.dy / box.size.height).clamp(0.0, 1.0),
      );
    }

    _incoming = next;
    _variant = variant;
    _start = start;
    _originFrac = frac;
    _revealing = true;
    _reveal.duration = switch (variant) {
      BeuiThemeToggleVariant.rectangle => const Duration(milliseconds: 400),
      BeuiThemeToggleVariant.circle ||
      BeuiThemeToggleVariant.circleBlur ||
      BeuiThemeToggleVariant.blinds => const Duration(milliseconds: 700),
    };
    _insertReveal();
    _reveal.forward(from: 0);
  }

  void _insertReveal() {
    _entry?.remove();
    _entry = null;
    final overlay = _overlay;
    if (overlay != null) {
      _entry = OverlayEntry(builder: _buildReveal);
      overlay.insert(_entry!);
    } else {
      setState(() {});
    }
  }

  Widget _themed(Brightness brightness, Widget child) {
    final parent = BeuiTheme.of(context);
    final colors = BeuiColors.resolve(
      brightness: brightness,
      theme: parent.colorTheme,
    );
    return BeuiTheme(
      brightness: brightness,
      colorTheme: parent.colorTheme,
      colors: colors,
      child: DefaultTextStyle(
        style: TextStyle(color: colors.foreground, fontSize: 14, height: 1.45),
        child: IconTheme(
          data: IconThemeData(color: colors.foreground, size: 16),
          child: child,
        ),
      ),
    );
  }

  double get _revealT {
    final raw = _reveal.value.clamp(0.0, 1.0);
    final curve = switch (_variant) {
      BeuiThemeToggleVariant.rectangle ||
      BeuiThemeToggleVariant.blinds => BeuiCurves.easeOut,
      BeuiThemeToggleVariant.circle ||
      BeuiThemeToggleVariant.circleBlur => _kCircleReveal,
    };
    return curve.transform(raw);
  }

  Widget _buildReveal(BuildContext overlayContext) {
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const SizedBox.shrink();
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final t = _revealT;
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: size.width,
      height: size.height,
      child: IgnorePointer(
        child: ExcludeSemantics(child: _clipReveal(t, _incomingSurface())),
      ),
    );
  }

  Widget _incomingSurface() {
    final parent = BeuiTheme.of(context);
    final colors = BeuiColors.resolve(
      brightness: _incoming,
      theme: parent.colorTheme,
    );
    return ColoredBox(
      color: colors.background,
      child: _themed(
        _incoming,
        _ThemeToggleScope(
          brightness: _incoming,
          requestToggle: _toggle,
          child: widget.child,
        ),
      ),
    );
  }

  Widget _clipReveal(double t, Widget child) {
    switch (_variant) {
      case BeuiThemeToggleVariant.rectangle:
        return ClipRect(
          clipper: _RectRevealClipper(t: t, start: _start),
          child: child,
        );
      case BeuiThemeToggleVariant.circle:
      case BeuiThemeToggleVariant.circleBlur:
        Widget clipped = ClipPath(
          clipper: _CircleRevealClipper(t: t, origin: _originFrac),
          child: child,
        );
        if (_variant == BeuiThemeToggleVariant.circleBlur) {
          final blur = (8 * (1 - t)).clamp(0.0, 10.0);
          if (blur > 0.2) {
            clipped = ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: clipped,
            );
          }
        }
        return clipped;
      case BeuiThemeToggleVariant.blinds:
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) {
            final slat = -_kSlatFeather + (_kSlat + _kSlatFeather) * t;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: [
                0,
                (slat / _kSlat).clamp(0.0, 1.0),
                ((slat + _kSlatFeather) / _kSlat).clamp(0.0, 1.0),
              ],
              tileMode: TileMode.repeated,
            ).createShader(Rect.fromLTWH(0, 0, _kSlat, rect.height));
          },
          child: child,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = _themed(
      _shown,
      _ThemeToggleScope(
        brightness: _shown,
        requestToggle: _toggle,
        child: widget.child,
      ),
    );
    final overlayMissing = _overlay == null && _revealing;
    return KeyedSubtree(
      key: _boxKey,
      child: overlayMissing
          ? Stack(
              children: [
                live,
                Positioned.fill(
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: _clipReveal(_revealT, _incomingSurface()),
                    ),
                  ),
                ),
              ],
            )
          : live,
    );
  }
}

/// Theme toggle button. Port of `components/motion/theme-toggle.tsx`.
class BeuiThemeToggle extends StatefulWidget {
  const BeuiThemeToggle({
    super.key,
    this.variant = BeuiThemeToggleVariant.rectangle,
    this.start = BeuiThemeToggleStart.bottomUp,
    this.brightness,
    this.initialBrightness,
    this.onChanged,
    this.iconSize = 20,
    this.semanticLabel,
  });

  final BeuiThemeToggleVariant variant;
  final BeuiThemeToggleStart start;
  final Brightness? brightness;
  final Brightness? initialBrightness;
  final ValueChanged<Brightness>? onChanged;
  final double iconSize;
  final String? semanticLabel;

  @override
  State<BeuiThemeToggle> createState() => _BeuiThemeToggleState();
}

class _BeuiThemeToggleState extends State<BeuiThemeToggle> {
  late Brightness _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialBrightness ?? Brightness.dark;
  }

  Brightness _resolved(BuildContext context) {
    final scope = _ThemeToggleScope.maybeOf(context);
    if (scope != null) return scope.brightness;
    if (widget.brightness != null) return widget.brightness!;
    return _internal;
  }

  void _handleTap(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(box.size.center(Offset.zero))
        : Offset.zero;
    final scope = _ThemeToggleScope.maybeOf(context);
    if (scope != null) {
      scope.requestToggle(
        variant: widget.variant,
        start: widget.start,
        origin: origin,
      );
      return;
    }
    final next = _resolved(context) == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    if (widget.brightness == null) setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final isDark = _resolved(context) == Brightness.dark;
    final label =
        widget.semanticLabel ??
        (isDark ? 'Switch to light mode' : 'Switch to dark mode');

    return Semantics(
      button: true,
      toggled: isDark,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(context),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(BeuiRadii.lg),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox.square(
                dimension: widget.iconSize,
                child: BeuiSpringBuilder(
                  value: isDark ? 1 : 0,
                  spec: BeuiSpringSpec.swap,
                  builder: (context, t) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        _SwapIcon(
                          t: t,
                          child: BeuiIcon(
                            _sun,
                            size: widget.iconSize,
                            color: colors.foreground,
                          ),
                        ),
                        _SwapIcon(
                          t: 1 - t,
                          child: BeuiIcon(
                            _moon,
                            size: widget.iconSize,
                            color: colors.foreground,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwapIcon extends StatelessWidget {
  const _SwapIcon({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final opacity = t.clamp(0.0, 1.0);
    if (opacity <= 0.001) return const SizedBox.shrink();
    final blur = beuiReduceMotion(context)
        ? 0.0
        : (8 * (1 - opacity)).clamp(0.0, 10.0);
    Widget icon = Opacity(opacity: opacity, child: child);
    if (blur > 0.2) {
      icon = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: icon,
      );
    }
    return icon;
  }
}

void _sun(Canvas canvas, Size size, Paint stroke) {
  canvas.drawCircle(const Offset(12, 12), 4, stroke);
  canvas.drawLine(const Offset(12, 2), const Offset(12, 4), stroke);
  canvas.drawLine(const Offset(12, 20), const Offset(12, 22), stroke);
  canvas.drawLine(const Offset(2, 12), const Offset(4, 12), stroke);
  canvas.drawLine(const Offset(20, 12), const Offset(22, 12), stroke);
  canvas.drawLine(const Offset(4.93, 4.93), const Offset(6.34, 6.34), stroke);
  canvas.drawLine(
    const Offset(17.66, 17.66),
    const Offset(19.07, 19.07),
    stroke,
  );
  canvas.drawLine(const Offset(4.93, 19.07), const Offset(6.34, 17.66), stroke);
  canvas.drawLine(const Offset(17.66, 6.34), const Offset(19.07, 4.93), stroke);
}

void _moon(Canvas canvas, Size size, Paint stroke) {
  final path = Path()
    ..moveTo(12, 3)
    ..arcToPoint(
      const Offset(21, 12),
      radius: const Radius.circular(6),
      clockwise: false,
    )
    ..arcToPoint(
      const Offset(12, 3),
      radius: const Radius.circular(9),
      clockwise: true,
      largeArc: true,
    );
  canvas.drawPath(path, stroke);
}

class _RectRevealClipper extends CustomClipper<Rect> {
  _RectRevealClipper({required this.t, required this.start});

  final double t;
  final BeuiThemeToggleStart start;

  @override
  Rect getClip(Size size) {
    final (top, right, bottom, left) = switch (start) {
      BeuiThemeToggleStart.topLeft => (0.0, 1.0, 1.0, 0.0),
      BeuiThemeToggleStart.topRight => (0.0, 0.0, 1.0, 1.0),
      BeuiThemeToggleStart.bottomLeft => (1.0, 1.0, 0.0, 0.0),
      BeuiThemeToggleStart.bottomRight => (1.0, 0.0, 0.0, 1.0),
      BeuiThemeToggleStart.center => (0.5, 0.5, 0.5, 0.5),
      BeuiThemeToggleStart.bottomUp => (1.0, 0.0, 0.0, 0.0),
    };
    final u = 1 - t;
    return Rect.fromLTRB(
      size.width * left * u,
      size.height * top * u,
      size.width * (1 - right * u),
      size.height * (1 - bottom * u),
    );
  }

  @override
  bool shouldReclip(covariant _RectRevealClipper oldClipper) =>
      oldClipper.t != t || oldClipper.start != start;
}

class _CircleRevealClipper extends CustomClipper<Path> {
  _CircleRevealClipper({required this.t, required this.origin});

  final double t;
  final Offset origin;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width * origin.dx, size.height * origin.dy);
    final hypot = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final radius = hypot * 1.5 * t;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _CircleRevealClipper oldClipper) =>
      oldClipper.t != t || oldClipper.origin != origin;
}
