import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/colors.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

/// Local spring on `animated-toast-stack.tsx` (`stiffness: 420, damping: 34, mass: 0.75`).
const _kStackSpring = BeuiSpringSpec(stiffness: 420, damping: 34, mass: 0.75);

enum BeuiToastStatus { neutral, info, loading, success, error }

enum BeuiToastPosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

enum BeuiToastPlacement { stat, fixed, absolute }

class BeuiToastAction {
  const BeuiToastAction({required this.label, required this.onClick});

  final String label;
  final void Function(BeuiAnimatedToast toast) onClick;
}

class BeuiToastInput {
  const BeuiToastInput({
    this.id,
    required this.title,
    this.description,
    this.status,
    this.icon,
    this.action,
    this.duration,
    this.dismissible,
  });

  final String? id;
  final String title;
  final String? description;
  final BeuiToastStatus? status;
  final Widget? icon;
  final BeuiToastAction? action;
  final Duration? duration;
  final bool? dismissible;
}

class BeuiAnimatedToast {
  const BeuiAnimatedToast({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.icon,
    this.action,
    this.duration,
    this.dismissible = true,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final BeuiToastStatus? status;
  final Widget? icon;
  final BeuiToastAction? action;
  final Duration? duration;
  final bool dismissible;
  final DateTime createdAt;

  BeuiAnimatedToast copyWith({
    String? title,
    String? description,
    BeuiToastStatus? status,
    Widget? icon,
    BeuiToastAction? action,
    Duration? duration,
    bool? dismissible,
    DateTime? createdAt,
  }) {
    return BeuiAnimatedToast(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      action: action ?? this.action,
      duration: duration ?? this.duration,
      dismissible: dismissible ?? this.dismissible,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

int _toastSeed = 0;

BeuiAnimatedToast _createToast(BeuiToastInput input, Duration defaultDuration) {
  return BeuiAnimatedToast(
    duration: input.duration ?? defaultDuration,
    dismissible: input.dismissible ?? true,
    id: input.id ??
        'toast-${DateTime.now().millisecondsSinceEpoch}-${_toastSeed++}',
    title: input.title,
    description: input.description,
    status: input.status,
    icon: input.icon,
    action: input.action,
    createdAt: DateTime.now(),
  );
}

/// Port of `useAnimatedToastStack`. Auto-dismiss uses tickers, not `Timer`.
class BeuiAnimatedToastController extends ChangeNotifier {
  BeuiAnimatedToastController({
    required TickerProvider vsync,
    this.defaultDuration = const Duration(milliseconds: 4200),
    this.limit,
    List<BeuiToastInput> initialToasts = const [],
  }) : _vsync = vsync {
    _toasts = [
      for (final input in initialToasts) _createToast(input, defaultDuration),
    ];
    for (final toast in _toasts) {
      _armTimer(toast);
    }
  }

  final TickerProvider _vsync;
  final Duration defaultDuration;
  final int? limit;

  late List<BeuiAnimatedToast> _toasts;
  final Map<String, AnimationController> _timers = {};
  final Map<String, String> _signatures = {};

  List<BeuiAnimatedToast> get toasts => List.unmodifiable(_toasts);

  String showToast(BeuiToastInput input) {
    final toast = _createToast(input, defaultDuration);
    var next = [..._toasts, toast];
    if (limit != null) next = next.sublist(next.length > limit! ? next.length - limit! : 0);
    final dropped = _toasts.where((t) => next.every((n) => n.id != t.id));
    for (final t in dropped) {
      _cancelTimer(t.id);
    }
    _toasts = next;
    _armTimer(toast);
    notifyListeners();
    return toast.id;
  }

  void updateToast(
    String id, {
    String? title,
    String? description,
    BeuiToastStatus? status,
    Widget? icon,
    BeuiToastAction? action,
    Duration? duration,
    bool? dismissible,
  }) {
    _toasts = [
      for (final toast in _toasts)
        if (toast.id == id)
          toast.copyWith(
            title: title,
            description: description,
            status: status,
            icon: icon,
            action: action,
            duration: duration,
            dismissible: dismissible,
            createdAt: duration == null ? toast.createdAt : DateTime.now(),
          )
        else
          toast,
    ];
    final updated = _toasts.where((t) => t.id == id);
    if (updated.isNotEmpty) _armTimer(updated.first);
    notifyListeners();
  }

  void dismissToast(String id) {
    _cancelTimer(id);
    final next = _toasts.where((t) => t.id != id).toList();
    if (next.length == _toasts.length) return;
    _toasts = next;
    notifyListeners();
  }

  void clearToasts() {
    for (final id in _timers.keys.toList()) {
      _cancelTimer(id);
    }
    _toasts = [];
    notifyListeners();
  }

  void _armTimer(BeuiAnimatedToast toast) {
    final duration = toast.duration ?? defaultDuration;
    if (duration <= Duration.zero) {
      _cancelTimer(toast.id);
      return;
    }
    final signature = '${toast.createdAt.millisecondsSinceEpoch}:${duration.inMilliseconds}';
    if (_signatures[toast.id] == signature) return;
    _cancelTimer(toast.id);
    final elapsed = DateTime.now().difference(toast.createdAt);
    final remaining = duration - elapsed;
    if (remaining <= Duration.zero) {
      dismissToast(toast.id);
      return;
    }
    final controller = AnimationController(vsync: _vsync, duration: remaining)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _cancelTimer(toast.id);
          dismissToast(toast.id);
        }
      })
      ..forward();
    _timers[toast.id] = controller;
    _signatures[toast.id] = signature;
  }

  void _cancelTimer(String id) {
    _timers.remove(id)?.dispose();
    _signatures.remove(id);
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.dispose();
    }
    _timers.clear();
    super.dispose();
  }
}

/// Stacked toasts with status morphs, swipe dismissal and layout-aware motion.
/// Port of `components/motion/animated-toast-stack.tsx`.
class BeuiAnimatedToastStack extends StatefulWidget {
  const BeuiAnimatedToastStack({
    super.key,
    required this.toasts,
    this.onDismiss,
    this.position = BeuiToastPosition.bottomRight,
    this.placement,
    this.fixed = false,
    this.portal,
    this.maxVisible = 4,
    this.icons = const {},
    this.renderToast,
  });

  final List<BeuiAnimatedToast> toasts;
  final ValueChanged<String>? onDismiss;
  final BeuiToastPosition position;
  final BeuiToastPlacement? placement;
  final bool fixed;
  final bool? portal;
  final int maxVisible;
  final Map<BeuiToastStatus, Widget> icons;
  final Widget Function(BeuiAnimatedToast toast)? renderToast;

  @override
  State<BeuiAnimatedToastStack> createState() => _BeuiAnimatedToastStackState();
}

class _PresentToast {
  _PresentToast(this.toast);
  BeuiAnimatedToast toast;
  bool exiting = false;
}

class _BeuiAnimatedToastStackState extends State<BeuiAnimatedToastStack> {
  final List<_PresentToast> _present = [];
  final OverlayPortalController _portal = OverlayPortalController();

  BeuiToastPlacement get _placement =>
      widget.placement ??
      (widget.fixed ? BeuiToastPlacement.fixed : BeuiToastPlacement.stat);

  bool get _shouldPortal =>
      widget.portal ?? _placement == BeuiToastPlacement.fixed;

  @override
  void initState() {
    super.initState();
    _syncPresent();
    // Safe before OverlayPortal attaches. Overlay.insert during Overlay.build
    // throws, which hid gallery toasts with `placement: fixed`.
    if (_shouldPortal) _portal.show();
  }

  @override
  void didUpdateWidget(BeuiAnimatedToastStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPresent();
    _syncPortal();
  }

  void _syncPresent() {
    final nextIds = widget.toasts.map((t) => t.id).toSet();
    for (final item in _present) {
      if (!nextIds.contains(item.toast.id)) item.exiting = true;
    }
    for (final toast in widget.toasts) {
      _PresentToast? existing;
      for (final item in _present) {
        if (item.toast.id == toast.id) {
          existing = item;
          break;
        }
      }
      if (existing == null) {
        _present.add(_PresentToast(toast));
      } else if (!existing.exiting) {
        existing.toast = toast;
      }
    }
  }

  void _finishExit(String id) {
    _present.removeWhere((e) => e.toast.id == id && e.exiting);
    if (mounted) setState(() {});
  }

  /// [OverlayPortalController.show]/[hide] must not run during build.
  void _syncPortal() {
    final want = _shouldPortal;
    if (want == _portal.isShowing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_shouldPortal && !_portal.isShowing) _portal.show();
      if (!_shouldPortal && _portal.isShowing) _portal.hide();
    });
  }

  Widget _positioned(BuildContext context, Widget child) {
    final pos = widget.position;
    final isTop = pos == BeuiToastPosition.topLeft ||
        pos == BeuiToastPosition.topCenter ||
        pos == BeuiToastPosition.topRight;
    final isLeft = pos == BeuiToastPosition.topLeft ||
        pos == BeuiToastPosition.bottomLeft;
    final isCenter = pos == BeuiToastPosition.topCenter ||
        pos == BeuiToastPosition.bottomCenter;
    final mq = MediaQuery.maybeOf(context);
    final pad = mq?.padding ?? EdgeInsets.zero;
    final Alignment alignment;
    if (isCenter) {
      alignment = isTop ? Alignment.topCenter : Alignment.bottomCenter;
    } else if (isLeft) {
      alignment = isTop ? Alignment.topLeft : Alignment.bottomLeft;
    } else {
      alignment = isTop ? Alignment.topRight : Alignment.bottomRight;
    }
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          isTop ? pad.top + 16 : 16,
          16,
          isTop ? 16 : pad.bottom + 24,
        ),
        child: child,
      ),
    );
  }

  Widget _stack() {
    final live = widget.toasts;
    final visibleLive = live.length > widget.maxVisible
        ? live.sublist(live.length - widget.maxVisible)
        : live;
    final visibleIds = visibleLive.map((t) => t.id).toSet();
    final shown = _present
        .where((p) => visibleIds.contains(p.toast.id) || p.exiting)
        .toList();
    final isBottom = widget.position.name.startsWith('bottom');

    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 384),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          verticalDirection:
              isBottom ? VerticalDirection.up : VerticalDirection.down,
          children: [
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _ToastItem(
                key: ValueKey(shown[i].toast.id),
                toast: shown[i].toast,
                exiting: shown[i].exiting,
                onDismiss: widget.onDismiss,
                onExitComplete: () => _finishExit(shown[i].toast.id),
                icons: widget.icons,
                renderToast: widget.renderToast,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);
    if (_shouldPortal && overlay != null) {
      return OverlayPortal(
        controller: _portal,
        overlayLocation: OverlayChildLocation.rootOverlay,
        overlayChildBuilder: (overlayContext) {
          return _positioned(overlayContext, _stack());
        },
        child: const SizedBox.shrink(),
      );
    }
    if (_placement == BeuiToastPlacement.absolute || _shouldPortal) {
      return _positioned(context, _stack());
    }
    return _stack();
  }
}

class _ToastItem extends StatefulWidget {
  const _ToastItem({
    super.key,
    required this.toast,
    required this.exiting,
    required this.onDismiss,
    required this.onExitComplete,
    required this.icons,
    required this.renderToast,
  });

  final BeuiAnimatedToast toast;
  final bool exiting;
  final ValueChanged<String>? onDismiss;
  final VoidCallback onExitComplete;
  final Map<BeuiToastStatus, Widget> icons;
  final Widget Function(BeuiAnimatedToast toast)? renderToast;

  @override
  State<_ToastItem> createState() => _ToastItemState();
}

class _ToastItemState extends State<_ToastItem>
    with TickerProviderStateMixin {
  late final BeuiSpringValue _enter;
  late final AnimationController _exit;
  late final AnimationController _spin;
  double _drag = 0;
  double _velocity = 0;
  DateTime? _lastMove;

  bool get _canDismiss =>
      widget.toast.dismissible && widget.onDismiss != null;

  @override
  void initState() {
    super.initState();
    _enter = BeuiSpringValue(value: 0, spec: _kStackSpring)
      ..attach(this)
      ..addListener(_tick);
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(_tick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onExitComplete();
      });
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enter.reducedMotion = beuiReduceMotion(context);
      _enter.animateTo(1);
      _syncSpin();
    });
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enter.reducedMotion = beuiReduceMotion(context);
  }

  @override
  void didUpdateWidget(_ToastItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exiting && !oldWidget.exiting) {
      _exit.forward();
    }
    _syncSpin();
  }

  void _syncSpin() {
    final loading = (widget.toast.status ?? BeuiToastStatus.neutral) ==
        BeuiToastStatus.loading;
    if (loading) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _enter
      ..removeListener(_tick)
      ..dispose();
    _exit
      ..removeListener(_tick)
      ..dispose();
    _spin.dispose();
    super.dispose();
  }

  void _onDragEnd() {
    if (_canDismiss &&
        (_drag.abs() > 72 || _velocity.abs() > 520)) {
      widget.onDismiss?.call(widget.toast.id);
      return;
    }
    _drag = 0;
    _velocity = 0;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final t = _enter.value.clamp(0.0, 1.0);
    final exitT = BeuiCurves.easeOut.transform(_exit.value);
    final status = widget.toast.status ?? BeuiToastStatus.neutral;

    var opacity = reduce ? t : t;
    var y = reduce ? 0.0 : 22 * (1 - t);
    var scale = reduce ? 1.0 : 0.96 + 0.04 * t;
    var blur = reduce ? 0.0 : 10 * (1 - t);
    var x = _drag;

    if (_exit.value > 0) {
      opacity = reduce ? 1 - exitT : 1 - exitT;
      if (!reduce) {
        x = x + 32 * exitT;
        scale = 1 - 0.04 * exitT;
        blur = 8 * exitT;
        y = 0;
      }
    }

    Widget surface = widget.renderToast != null
        ? widget.renderToast!(widget.toast)
        : _DefaultToastBody(
            toast: widget.toast,
            status: status,
            icons: widget.icons,
            spin: _spin,
            canDismiss: _canDismiss,
            onDismiss: () => widget.onDismiss?.call(widget.toast.id),
          );

    surface = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(BeuiRadii.card),
        border: Border.all(color: colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BeuiRadii.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: surface,
          ),
        ),
      ),
    );

    Widget painted = Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(x, y),
        child: Transform.scale(
          scale: scale,
          child: blur <= 0.05
              ? surface
              : ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blur,
                    sigmaY: blur,
                  ),
                  child: surface,
                ),
        ),
      ),
    );

    if (_canDismiss && !reduce) {
      painted = GestureDetector(
        onHorizontalDragStart: (_) {
          _lastMove = DateTime.now();
        },
        onHorizontalDragUpdate: (d) {
          final now = DateTime.now();
          final dt = _lastMove == null
              ? 0.016
              : now.difference(_lastMove!).inMicroseconds / 1e6;
          if (dt > 0.0004) _velocity = d.delta.dx / dt;
          _lastMove = now;
          _drag += d.delta.dx;
          setState(() {});
        },
        onHorizontalDragEnd: (_) => _onDragEnd(),
        onHorizontalDragCancel: _onDragEnd,
        child: painted,
      );
    }

    return painted;
  }
}

class _DefaultToastBody extends StatefulWidget {
  const _DefaultToastBody({
    required this.toast,
    required this.status,
    required this.icons,
    required this.spin,
    required this.canDismiss,
    required this.onDismiss,
  });

  final BeuiAnimatedToast toast;
  final BeuiToastStatus status;
  final Map<BeuiToastStatus, Widget> icons;
  final AnimationController spin;
  final bool canDismiss;
  final VoidCallback onDismiss;

  @override
  State<_DefaultToastBody> createState() => _DefaultToastBodyState();
}

class _DefaultToastBodyState extends State<_DefaultToastBody> {
  bool _closeHover = false;
  bool _actionHover = false;

  (Color fg, Color bg) _statusColors(BeuiColors colors) {
    switch (widget.status) {
      case BeuiToastStatus.neutral:
        return (colors.mutedForeground, colors.primary.withValues(alpha: 0.05));
      case BeuiToastStatus.info:
      case BeuiToastStatus.loading:
        return (colors.primary, colors.primary.withValues(alpha: 0.1));
      case BeuiToastStatus.success:
        return (colors.success, colors.success.withValues(alpha: 0.1));
      case BeuiToastStatus.error:
        return (colors.destructive, colors.destructive.withValues(alpha: 0.1));
    }
  }

  BeuiIconPainter _statusPainter() {
    return switch (widget.status) {
      BeuiToastStatus.neutral => BeuiIcons.bell,
      BeuiToastStatus.info => BeuiIcons.info,
      BeuiToastStatus.loading => BeuiIcons.loader,
      BeuiToastStatus.success => BeuiIcons.check,
      BeuiToastStatus.error => BeuiIcons.alertCircle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final tone = _statusColors(colors);
    Widget icon = widget.icons[widget.status] ??
        widget.toast.icon ??
        BeuiIcon(_statusPainter(), size: 14, color: tone.$1);
    if (widget.status == BeuiToastStatus.loading) {
      icon = RotationTransition(turns: widget.spin, child: icon);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tone.$2,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: _Swap(
                  swapKey: widget.status,
                  child: icon,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Swap(
            swapKey: '${widget.toast.id}-${widget.status}-${widget.toast.title}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.toast.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: colors.foreground,
                  ),
                ),
                if (widget.toast.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.toast.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                if (widget.toast.action != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => beuiAfterPointer(() {
                        if (mounted) setState(() => _actionHover = true);
                      }),
                      onExit: (_) => beuiAfterPointer(() {
                        if (mounted) setState(() => _actionHover = false);
                      }),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            widget.toast.action!.onClick(widget.toast),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(
                              alpha: _actionHover ? 0.1 : 0.06,
                            ),
                            borderRadius: BorderRadius.circular(BeuiRadii.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Text(
                              widget.toast.action!.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.foreground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.canDismiss) ...[
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => beuiAfterPointer(() {
              if (mounted) setState(() => _closeHover = true);
            }),
            onExit: (_) => beuiAfterPointer(() {
              if (mounted) setState(() => _closeHover = false);
            }),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              child: Semantics(
                button: true,
                label: 'Dismiss toast',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _closeHover
                        ? colors.primary.withValues(alpha: 0.06)
                        : const Color(0x00000000),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: BeuiIcon(
                        BeuiIcons.x,
                        size: 14,
                        color: _closeHover
                            ? colors.foreground
                            : colors.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Content swap: 280ms EASE_OUT, y 8, blur 6.
class _Swap extends StatefulWidget {
  const _Swap({required this.swapKey, required this.child});

  final Object swapKey;
  final Widget child;

  @override
  State<_Swap> createState() => _SwapState();
}

class _SwapState extends State<_Swap> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Widget _child;
  late Object _key;

  @override
  void initState() {
    super.initState();
    _key = widget.swapKey;
    _child = widget.child;
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void didUpdateWidget(_Swap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.swapKey != _key) {
      _key = widget.swapKey;
      _child = widget.child;
      _c.forward(from: 0);
    } else {
      _child = widget.child;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = beuiReduceMotion(context);
    final t = BeuiCurves.easeOut.transform(_c.value);
    final y = reduce ? 0.0 : 8 * (1 - t);
    final blur = reduce ? 0.0 : 6 * (1 - t);
    Widget child = Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, y),
        child: _child,
      ),
    );
    if (blur > 0.05) {
      child = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      );
    }
    return child;
  }
}
