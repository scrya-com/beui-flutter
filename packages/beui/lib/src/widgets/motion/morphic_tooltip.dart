import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

/// Shared-layout tooltip: one surface morphs between triggers in a [BeuiMorphicTooltipScope].
///
/// Visual port of beUI Pro Morphic Tooltip (`pro.beui.dev/components/morphic-tooltip`).
class BeuiMorphicTooltipScope extends StatefulWidget {
  const BeuiMorphicTooltipScope({
    super.key,
    required this.child,
    this.side = BeuiMorphicTooltipSide.top,
    this.delay = const Duration(milliseconds: 120),
  });

  final Widget child;
  final BeuiMorphicTooltipSide side;
  final Duration delay;

  @override
  State<BeuiMorphicTooltipScope> createState() =>
      _BeuiMorphicTooltipScopeState();
}

_BeuiMorphicTooltipScopeState? _morphicScopeOf(BuildContext context) =>
    context.findAncestorStateOfType<_BeuiMorphicTooltipScopeState>();

enum BeuiMorphicTooltipSide { top, bottom, left, right }

/// Spawn of the free `Tooltip` (stiffness 380 / damping 30 / mass 0.7).
const _kSpawn = BeuiSpringSpec(stiffness: 380, damping: 30, mass: 0.7);

const _kGap = 10.0;
const _kPad = EdgeInsets.symmetric(horizontal: 8, vertical: 8);
const _kMaxContent = 18.0 * 16;
const _kWarm = Duration(milliseconds: 300);
const _kHideGrace = Duration(milliseconds: 80);

class _BeuiMorphicTooltipScopeState extends State<BeuiMorphicTooltipScope>
    with TickerProviderStateMixin {
  OverlayEntry? _entry;
  OverlayState? _overlay;
  Timer? _showTimer;
  Timer? _hideTimer;
  DateTime _hiddenAt = DateTime.fromMillisecondsSinceEpoch(0);

  Object? _activeId;
  Widget? _content;
  Widget? _prevContent;
  Rect? _trigger;

  late final BeuiSpringValue _x;
  late final BeuiSpringValue _y;
  late final BeuiSpringValue _w;
  late final BeuiSpringValue _h;
  late final BeuiSpringValue _show;
  late final BeuiSpringValue _swap;

  final GlobalKey _measureKey = GlobalKey();
  Widget? _measureChild;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    _x = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _y = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _w = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _h = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _show = BeuiSpringValue(value: 0, spec: _kSpawn)..attach(this);
    _swap = BeuiSpringValue(value: 1, spec: BeuiSpringSpec.swap)..attach(this);
    for (final s in [_x, _y, _w, _h, _show, _swap]) {
      s.addListener(_paint);
    }
  }

  void _paint() => _entry?.markNeedsBuild();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);
    final reduce = beuiReduceMotion(context);
    for (final s in [_x, _y, _w, _h, _show, _swap]) {
      s.reducedMotion = reduce;
    }
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _entry?.remove();
    _entry = null;
    for (final s in [_x, _y, _w, _h, _show, _swap]) {
      s
        ..removeListener(_paint)
        ..dispose();
    }
    super.dispose();
  }

  void show({
    required Object id,
    required Rect trigger,
    required Widget content,
  }) {
    _hideTimer?.cancel();
    _hideTimer = null;
    final already = _activeId != null && _show.value > 0.05;
    final warm =
        DateTime.now().difference(_hiddenAt) < _kWarm;
    _activeId = id;
    _trigger = trigger;
    if (_content != null && !identical(_content, content)) {
      _prevContent = _content;
      _swap.jump(0);
      _swap.animateTo(1);
    }
    _content = content;
    _measureChild = content;
    final wait = (already || warm) ? Duration.zero : widget.delay;
    _showTimer?.cancel();
    void open() {
      if (!mounted || _activeId != id) return;
      _ensureOverlay();
      _entry?.markNeedsBuild();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _commitPlacement(id);
      });
    }

    if (wait == Duration.zero) {
      open();
    } else {
      _showTimer = Timer(wait, open);
    }
  }

  void hide(Object id) {
    if (_activeId != id) return;
    _showTimer?.cancel();
    _showTimer = null;
    _hideTimer?.cancel();
    _hideTimer = Timer(_kHideGrace, () {
      if (!mounted || _activeId != id) return;
      _activeId = null;
      _hiddenAt = DateTime.now();
      _show.animateTo(0);
    });
  }

  void _ensureOverlay() {
    if (_entry != null) return;
    final overlay = _overlay;
    if (overlay == null) return;
    _entry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_entry!);
  }

  void _commitPlacement(Object id) {
    if (_activeId != id || _trigger == null) return;
    final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final size = box.size;
    final view = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    var w = size.width.clamp(32.0, view.width - 24);
    var h = size.height.clamp(24.0, 160.0);
    var cx = _trigger!.center.dx;
    var top = widget.side == BeuiMorphicTooltipSide.bottom
        ? _trigger!.bottom + _kGap
        : _trigger!.top - _kGap - h;
    cx = cx.clamp(pad.left + w / 2 + 12, view.width - pad.right - w / 2 - 12);
    top = top.clamp(pad.top + 8, view.height - pad.bottom - h - 8);

    if (!_placed || _show.value < 0.05) {
      _x.jump(cx);
      _y.jump(top);
      _w.jump(w);
      _h.jump(h);
      _placed = true;
    } else {
      _x.animateTo(cx);
      _y.animateTo(top);
      _w.animateTo(w);
      _h.animateTo(h);
    }
    _show.animateTo(1);
    _entry?.markNeedsBuild();
  }

  Widget _contentBox(Widget child) {
    final colors = context.beuiColors;
    return Padding(
      padding: _kPad,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxContent),
        child: DefaultTextStyle(
          style: TextStyle(
            color: colors.background,
            fontSize: 12,
            height: 4 / 3,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
          child: child,
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final colors = context.beuiColors;
    final t = _show.value.clamp(0.0, 1.0);
    final reduce = beuiReduceMotion(context);
    final scale = reduce ? 1.0 : 0.92 + 0.08 * t;
    final blur = reduce ? 0.0 : (5.0 * (1 - t)).clamp(0.0, 10.0);
    final swap = _swap.value.clamp(0.0, 1.0);

    Widget chrome = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.foreground,
        borderRadius: BorderRadius.circular(BeuiRadii.lg),
        border: Border.all(color: colors.background.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xBF000000),
            blurRadius: 50,
            spreadRadius: -26,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: colors.background.withValues(alpha: 0.18),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BeuiRadii.lg),
        child: SizedBox(
          width: _w.value,
          height: _h.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_prevContent != null && swap < 0.99)
                Opacity(
                  opacity: 1 - swap,
                  child: _contentBox(_prevContent!),
                ),
              if (_content != null)
                Opacity(
                  opacity: swap,
                  child: _contentBox(_content!),
                ),
            ],
          ),
        ),
      ),
    );

    if (blur > 0.2) {
      chrome = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: chrome,
      );
    }

    return IgnorePointer(
      child: Stack(
        children: [
          if (_measureChild != null)
            Positioned(
              left: -4000,
              top: 0,
              child: KeyedSubtree(
                key: _measureKey,
                child: _contentBox(_measureChild!),
              ),
            ),
          if (t > 0.001 && _placed)
            Transform.translate(
              offset: Offset(_x.value - _w.value / 2, _y.value),
              child: Semantics(
                container: true,
                liveRegion: true,
                child: Opacity(
                  opacity: t,
                  child: Transform.scale(
                    alignment: widget.side == BeuiMorphicTooltipSide.bottom
                        ? Alignment.topCenter
                        : Alignment.bottomCenter,
                    scale: scale,
                    child: chrome,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A trigger that reports hover/focus into the nearest [BeuiMorphicTooltipScope].
class BeuiMorphicTooltip extends StatefulWidget {
  const BeuiMorphicTooltip({
    super.key,
    required this.content,
    required this.child,
    this.semanticLabel,
  });

  final Widget content;
  final Widget child;
  final String? semanticLabel;

  @override
  State<BeuiMorphicTooltip> createState() => _BeuiMorphicTooltipState();
}

class _BeuiMorphicTooltipState extends State<BeuiMorphicTooltip> {
  bool _hovered = false;
  bool _focused = false;
  _BeuiMorphicTooltipScopeState? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = _morphicScopeOf(context);
  }

  void _sync() {
    if (!mounted) return;
    final scope = _scope ?? _morphicScopeOf(context);
    if (scope == null) return;
    final open = _hovered || _focused;
    if (!open) {
      scope.hide(this);
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    scope.show(
      id: this,
      trigger: origin & box.size,
      content: widget.content,
    );
  }

  @override
  void didUpdateWidget(BeuiMorphicTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hovered || _focused) {
      beuiAfterPointer(_sync);
    }
  }

  @override
  void dispose() {
    _scope?.hide(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: MouseRegion(
        onEnter: (_) {
          _hovered = true;
          beuiAfterPointer(_sync);
        },
        onExit: (_) {
          _hovered = false;
          beuiAfterPointer(_sync);
        },
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          descendantsAreFocusable: true,
          onFocusChange: (v) {
            _focused = v;
            beuiAfterPointer(_sync);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _hovered = true;
              _sync();
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
