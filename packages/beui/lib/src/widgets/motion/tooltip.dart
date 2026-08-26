import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

/// Placement of the floating label relative to the trigger.
enum BeuiTooltipSide { top, right, bottom, left }

/// Spawn of `tooltip.tsx` (stiffness 380 / damping 30 / mass 0.7).
const _kSpawn = BeuiSpringSpec(stiffness: 380, damping: 30, mass: 0.7);

const _kGap = 8.0;
const _kWarm = Duration(milliseconds: 300);
const _kEnterFade = Duration(milliseconds: 140);
const _kEnterBlur = Duration(milliseconds: 180);
const _kExit = Duration(milliseconds: 120);
const _kExitReduced = Duration(milliseconds: 100);

/// Once any tooltip has just closed, neighbouring ones skip the open delay.
DateTime _beuiTooltipHiddenAt = DateTime.fromMillisecondsSinceEpoch(0);

/// Hover/focus/tap label that portals through [Overlay].
///
/// Port of `components/motion/tooltip.tsx`.
class BeuiTooltip extends StatefulWidget {
  const BeuiTooltip({
    super.key,
    required this.content,
    required this.child,
    this.side = BeuiTooltipSide.top,
    this.delay = const Duration(milliseconds: 120),
    this.semanticLabel,
  });

  final Widget content;
  final Widget child;
  final BeuiTooltipSide side;
  final Duration delay;
  final String? semanticLabel;

  @override
  State<BeuiTooltip> createState() => _BeuiTooltipState();
}

class _BeuiTooltipState extends State<BeuiTooltip>
    with TickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  OverlayState? _overlay;

  late final BeuiSpringValue _enter;
  late final AnimationController _delay;
  late final AnimationController _exit;
  late final AnimationController _fade;
  late final AnimationController _blur;

  bool _open = false;
  bool _hovered = false;
  bool _focused = false;
  bool _exiting = false;
  bool _listening = false;
  PointerDeviceKind? _downKind;

  @override
  void initState() {
    super.initState();
    _enter = BeuiSpringValue(value: 0, spec: _kSpawn)..attach(this);
    _enter.addListener(_paint);
    _delay = AnimationController(vsync: this, duration: widget.delay)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _reveal();
      });
    _exit = AnimationController(vsync: this, duration: _kExit)
      ..addListener(_paint)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _dropOverlay();
      });
    _fade = AnimationController(vsync: this, duration: _kEnterFade)
      ..addListener(_paint)
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && !_open) _dropOverlay();
      });
    _blur = AnimationController(vsync: this, duration: _kEnterBlur)
      ..addListener(_paint);
  }

  void _paint() => _entry?.markNeedsBuild();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    _enter.reducedMotion = beuiReduceMotion(context);
  }

  @override
  void didUpdateWidget(BeuiTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delay != widget.delay) {
      _delay.duration = widget.delay;
    }
    if (_open) _entry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _listenDismiss(false);
    _delay.dispose();
    _exit.dispose();
    _fade.dispose();
    _blur.dispose();
    _enter
      ..removeListener(_paint)
      ..dispose();
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  bool get _warm => DateTime.now().difference(_beuiTooltipHiddenAt) < _kWarm;

  void _scheduleShow() {
    if (!mounted) return;
    _delay.stop();
    if (_warm || widget.delay == Duration.zero) {
      _reveal();
      return;
    }
    _delay.duration = widget.delay;
    _delay.forward(from: 0);
  }

  void _reveal() {
    if (!mounted) return;
    if (_open && !_exiting) return;
    _delay.stop();
    _delay.value = 0;
    _exiting = false;
    _exit.stop();
    _exit.value = 0;
    _open = true;
    _ensureOverlay();
    final reduce = beuiReduceMotion(context);
    if (reduce) {
      _enter.jump(1);
      _blur.value = 1;
      _fade.duration = _kEnterFade;
      _fade.forward(from: _fade.value);
    } else {
      _enter.jump(0);
      _enter.animateTo(1);
      _fade
        ..duration = _kEnterFade
        ..forward(from: 0);
      _blur
        ..duration = _kEnterBlur
        ..forward(from: 0);
    }
    _entry?.markNeedsBuild();
    beuiAfterPointer(() {
      if (mounted && _open) _listenDismiss(true);
    });
  }

  void _hide() {
    if (!mounted) return;
    _delay.stop();
    _delay.value = 0;
    if (!_open && !_exiting) return;
    if (_open) _beuiTooltipHiddenAt = DateTime.now();
    _open = false;
    _listenDismiss(false);
    final reduce = beuiReduceMotion(context);
    if (reduce) {
      _exiting = true;
      _fade.duration = _kExitReduced;
      if (_fade.value <= 0) {
        _dropOverlay();
      } else {
        _fade.reverse();
      }
      return;
    }
    _exiting = true;
    _exit.duration = _kExit;
    _exit.forward(from: 0);
  }

  void _dropOverlay() {
    _exiting = false;
    _entry?.remove();
    _entry = null;
    _enter.jump(0);
    _fade.value = 0;
    _blur.value = 0;
    _exit.value = 0;
  }

  void _ensureOverlay() {
    if (_entry != null) return;
    final overlay = _overlay;
    if (overlay == null) return;
    _entry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_entry!);
  }

  void _listenDismiss(bool on) {
    if (on == _listening) return;
    _listening = on;
    if (on) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointer);
      HardwareKeyboard.instance.addHandler(_onKey);
    } else {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobalPointer);
      HardwareKeyboard.instance.removeHandler(_onKey);
    }
  }

  void _onGlobalPointer(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    if (!mounted || !_open) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      _hide();
      return;
    }
    final local = box.globalToLocal(event.position);
    if ((Offset.zero & box.size).contains(local)) return;
    _hide();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _open) {
      _hide();
    }
    return false;
  }

  void _onTapUp(PointerUpEvent event) {
    if (_downKind == null || _downKind == PointerDeviceKind.mouse) return;
    if (_open) {
      _hide();
      return;
    }
    _delay.stop();
    _reveal();
  }

  Alignment get _targetAnchor => switch (widget.side) {
        BeuiTooltipSide.top => Alignment.topCenter,
        BeuiTooltipSide.bottom => Alignment.bottomCenter,
        BeuiTooltipSide.left => Alignment.centerLeft,
        BeuiTooltipSide.right => Alignment.centerRight,
      };

  Alignment get _followerAnchor => switch (widget.side) {
        BeuiTooltipSide.top => Alignment.bottomCenter,
        BeuiTooltipSide.bottom => Alignment.topCenter,
        BeuiTooltipSide.left => Alignment.centerRight,
        BeuiTooltipSide.right => Alignment.centerLeft,
      };

  Offset get _gapOffset => switch (widget.side) {
        BeuiTooltipSide.top => const Offset(0, -_kGap),
        BeuiTooltipSide.bottom => const Offset(0, _kGap),
        BeuiTooltipSide.left => const Offset(-_kGap, 0),
        BeuiTooltipSide.right => const Offset(_kGap, 0),
      };

  Offset get _spawnOffset => switch (widget.side) {
        BeuiTooltipSide.top => const Offset(0, _kGap),
        BeuiTooltipSide.bottom => const Offset(0, -_kGap),
        BeuiTooltipSide.left => const Offset(_kGap, 0),
        BeuiTooltipSide.right => const Offset(-_kGap, 0),
      };

  Widget _buildOverlay(BuildContext overlayContext) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final spawn = _spawnOffset;

    double opacity;
    double scale;
    double blur;
    Offset travel;

    if (_exiting && !reduce) {
      final u = BeuiCurves.easeOut.transform(_exit.value.clamp(0.0, 1.0));
      opacity = 1 - u;
      scale = lerpDouble(1, 0.94, u)!;
      blur = lerpDouble(0, 3, u)!;
      travel = spawn * 0.6 * u;
    } else if (reduce) {
      opacity = _fade.value.clamp(0.0, 1.0);
      scale = 1;
      blur = 0;
      travel = Offset.zero;
    } else {
      final t = _enter.value;
      opacity = BeuiCurves.easeOut.transform(_fade.value.clamp(0.0, 1.0));
      scale = lerpDouble(0.9, 1, t)!;
      blur = 5 * (1 - BeuiCurves.easeOut.transform(_blur.value.clamp(0.0, 1.0)));
      travel = spawn * (1 - t);
    }

    Widget chrome = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BeuiRadii.md),
        border: Border.all(color: colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 15,
            spreadRadius: -3,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            spreadRadius: -4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: DefaultTextStyle(
          style: TextStyle(
            color: colors.foreground,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
          child: widget.content,
        ),
      ),
    );

    if (blur > 0.2) {
      chrome = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blur.clamp(0.0, 10.0),
          sigmaY: blur.clamp(0.0, 10.0),
        ),
        child: chrome,
      );
    }

    return IgnorePointer(
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: _targetAnchor,
        followerAnchor: _followerAnchor,
        offset: _gapOffset,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: travel,
            child: Transform.scale(
              alignment: _followerAnchor,
              scale: scale,
              child: Semantics(
                container: true,
                role: SemanticsRole.tooltip,
                child: chrome,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      tooltip: widget.semanticLabel,
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          onEnter: (_) {
            beuiAfterPointer(() {
              if (!mounted) return;
              if (!beuiHoverCapable(context)) return;
              _hovered = true;
              _scheduleShow();
            });
          },
          onExit: (_) {
            beuiAfterPointer(() {
              if (!mounted) return;
              if (!_hovered) return;
              _hovered = false;
              if (!_focused) _hide();
            });
          },
          child: Focus(
            onFocusChange: (v) {
              _focused = v;
              beuiAfterPointer(() {
                if (!mounted) return;
                if (v) {
                  _scheduleShow();
                } else if (!_hovered) {
                  _hide();
                }
              });
            },
            child: Listener(
              onPointerDown: (e) => _downKind = e.kind,
              onPointerUp: _onTapUp,
              onPointerCancel: (_) => _downKind = null,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
