import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../gestures/row_cursor.dart';
import '../../motion/hover.dart';
import '../../motion/overlay_dismiss.dart';
import '../../motion/presence.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

enum BeuiSelectPlacement { bottom, top }

class _SelectScope extends InheritedWidget {
  const _SelectScope({
    required this.state,
    required this.open,
    required this.value,
    required this.activeValue,
    required this.placement,
    required this.enabled,
    required super.child,
  });

  final _BeuiSelectState state;
  final bool open;
  final String? value;
  final String? activeValue;
  final BeuiSelectPlacement placement;
  final bool enabled;

  static _SelectScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SelectScope>();
    assert(scope != null, 'Select parts must be used within BeuiSelect');
    return scope!;
  }

  @override
  bool updateShouldNotify(_SelectScope oldWidget) =>
      open != oldWidget.open ||
      value != oldWidget.value ||
      enabled != oldWidget.enabled ||
      placement != oldWidget.placement ||
      activeValue != oldWidget.activeValue ||
      !identical(state.labels, oldWidget.state.labels);
}

/// Composable select whose panel unfolds from the trigger.
/// Port of `components/motion/select.tsx`.
class BeuiSelect extends StatefulWidget {
  const BeuiSelect({
    super.key,
    this.value,
    this.initialValue,
    this.onChanged,
    this.open,
    this.initialOpen = false,
    this.onOpenChanged,
    this.enabled = true,
    required this.child,
  });

  final String? value;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;
  final bool enabled;
  final Widget child;

  @override
  State<BeuiSelect> createState() => _BeuiSelectState();
}

class _BeuiSelectState extends State<BeuiSelect> {
  late String? _internal;
  late bool _internalOpen;
  final Map<String, String> labels = {};
  final List<String> _order = [];
  final Set<String> _disabled = {};
  final BeuiRowCursor cursor = BeuiRowCursor();
  final LayerLink link = LayerLink();
  final GlobalKey triggerKey = GlobalKey();
  final GlobalKey innerKey = GlobalKey();
  BeuiSelectPlacement placement = BeuiSelectPlacement.bottom;
  String? activeValue;
  final BeuiDismissArm dismiss = BeuiDismissArm();

  bool get _valueControlled => widget.value != null;
  bool get _openControlled => widget.open != null;
  String? get value => _valueControlled ? widget.value : _internal;
  bool get open => _openControlled ? widget.open! : _internalOpen;
  bool get enabled => widget.enabled;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialValue ?? widget.value;
    _internalOpen = widget.initialOpen;
  }

  List<String> get enabledRows =>
      _order.where((id) => !_disabled.contains(id)).toList(growable: false);

  void _resolveActive() {
    final rows = enabledRows;
    final at = cursor.activeIndex(rows, '');
    activeValue = at < 0 || rows.isEmpty ? null : rows[at];
  }

  void setOpen(bool next) {
    if (!enabled && next) return;
    if (open == next) return;
    if (next) {
      final rows = enabledRows;
      final selected = value;
      if (selected != null && rows.contains(selected)) {
        cursor.moveTo(selected, '');
      } else if (rows.isNotEmpty) {
        cursor.moveTo(rows.first, '');
      }
    }
    if (!_openControlled) setState(() => _internalOpen = next);
    widget.onOpenChanged?.call(next);
    if (next) {
      dismiss.armAfterOpen(() {
        if (mounted) setState(() {});
      });
    } else {
      dismiss.cancel();
    }
    if (_openControlled) setState(() {});
  }

  void select(String next) {
    if (_disabled.contains(next)) return;
    if (!_valueControlled) setState(() => _internal = next);
    widget.onChanged?.call(next);
    setOpen(false);
  }

  void register(String value, String label, {required bool enabled}) {
    final sameLabel = labels[value] == label;
    final known = _order.contains(value);
    final currentlyEnabled = !_disabled.contains(value);
    if (sameLabel && known && currentlyEnabled == enabled) return;
    labels[value] = label;
    if (!known) _order.add(value);
    if (enabled) {
      _disabled.remove(value);
    } else {
      _disabled.add(value);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void unregister(String value) {
    if (!labels.containsKey(value)) return;
    labels.remove(value);
    _order.remove(value);
    _disabled.remove(value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void moveActive(int direction) {
    final rows = enabledRows;
    cursor.moveActive(rows, '', direction);
    setState(() {});
  }

  void setActive(String? id) {
    beuiAfterPointer(() {
      if (!mounted) return;
      cursor.moveTo(id, '');
      setState(() {});
    });
  }

  void measurePlacement() {
    if (!open) return;
    final triggerBox =
        triggerKey.currentContext?.findRenderObject() as RenderBox?;
    final innerBox = innerKey.currentContext?.findRenderObject() as RenderBox?;
    if (triggerBox == null ||
        innerBox == null ||
        !triggerBox.hasSize ||
        !innerBox.hasSize) {
      return;
    }
    final origin = triggerBox.localToGlobal(Offset.zero);
    final view = MediaQuery.sizeOf(context);
    final h = innerBox.size.height;
    final below = view.height - (origin.dy + triggerBox.size.height);
    final above = origin.dy;
    final next = below < h + 16 && above > below
        ? BeuiSelectPlacement.top
        : BeuiSelectPlacement.bottom;
    if (next != placement) setState(() => placement = next);
  }

  bool handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && open) {
      setOpen(false);
      return true;
    }
    if (!enabled) return false;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (!open) {
        setOpen(true);
      } else {
        moveActive(1);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (!open) {
        setOpen(true);
      } else {
        moveActive(-1);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.home && open) {
      final rows = enabledRows;
      if (rows.isNotEmpty) {
        cursor.moveTo(rows.first, '');
        setState(() {});
      }
      return true;
    }
    if (key == LogicalKeyboardKey.end && open) {
      final rows = enabledRows;
      if (rows.isNotEmpty) {
        cursor.moveTo(rows.last, '');
        setState(() {});
      }
      return true;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (!open) {
        setOpen(true);
      } else if (activeValue != null) {
        select(activeValue!);
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _resolveActive();
    return _SelectScope(
      state: this,
      open: open,
      value: value,
      activeValue: activeValue,
      placement: placement,
      enabled: enabled,
      child: Focus(
        onKeyEvent: (node, event) =>
            handleKey(event) ? KeyEventResult.handled : KeyEventResult.ignored,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    dismiss.cancel();
    super.dispose();
  }
}

class BeuiSelectTrigger extends StatefulWidget {
  const BeuiSelectTrigger({super.key, required this.child});

  final Widget child;

  @override
  State<BeuiSelectTrigger> createState() => _BeuiSelectTriggerState();
}

class _BeuiSelectTriggerState extends State<BeuiSelectTrigger> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scope = _SelectScope.of(context);
    final state = scope.state;
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final open = state.open;
    final isTop = state.placement == BeuiSelectPlacement.top;
    final ring = _focused
        ? colors.ring.withValues(alpha: 0.4)
        : const Color(0x00000000);
    final border = _hovered || _focused
        ? colors.borderStrong
        : colors.border;

    return CompositedTransformTarget(
      link: state.link,
      child: KeyedSubtree(
        key: state.triggerKey,
        child: MouseRegion(
          cursor: state.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) {
            _hovered = true;
            beuiAfterPointer(() {
              if (mounted) setState(() {});
            });
          },
          onExit: (_) {
            _hovered = false;
            beuiAfterPointer(() {
              if (mounted) setState(() {});
            });
          },
          child: Focus(
            onFocusChange: (v) {
              _focused = v;
              beuiAfterPointer(() {
                if (mounted) setState(() {});
              });
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: state.enabled ? () => state.setOpen(!open) : null,
              child: Semantics(
                button: true,
                enabled: state.enabled,
                expanded: open,
                child: BeuiSpringBuilder(
                  value: open ? 1 : 0,
                  spec: BeuiSpringSpec.panel,
                  builder: (context, t) {
                    final facing = reduce
                        ? (open ? 12.0 : 12.0)
                        : (open
                            ? (t < 0.4 ? 0.0 : 12.0 * ((t - 0.4) / 0.6).clamp(0.0, 1.0))
                            : 12.0);
                    final far = 12.0;
                    final radius = BorderRadius.only(
                      topLeft: Radius.circular(isTop ? facing : far),
                      topRight: Radius.circular(isTop ? facing : far),
                      bottomLeft: Radius.circular(isTop ? far : facing),
                      bottomRight: Radius.circular(isTop ? far : facing),
                    );
                    return Opacity(
                      opacity: state.enabled ? 1 : 0.5,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: radius,
                          border: Border.all(color: border),
                          boxShadow: _focused
                              ? [
                                  BoxShadow(
                                    color: ring,
                                    blurRadius: 0,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: widget.child),
                            const SizedBox(width: 8),
                            Transform.rotate(
                              angle: (reduce ? (open ? 1.0 : 0.0) : t) * math.pi,
                              child: BeuiIcon(
                                BeuiIcons.chevronDown,
                                size: 16,
                                color: colors.mutedForeground,
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
    );
  }
}

class BeuiSelectValue extends StatelessWidget {
  const BeuiSelectValue({
    super.key,
    this.placeholder = 'Select',
  });

  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final state = _SelectScope.of(context).state;
    final colors = context.beuiColors;
    final value = state.value;
    final label = value == null ? null : state.labels[value];
    final filled = label != null;
    return Text(
      label ?? placeholder,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: filled ? colors.foreground : colors.mutedForeground,
      ),
    );
  }
}

class BeuiSelectContent extends StatefulWidget {
  const BeuiSelectContent({super.key, required this.children});

  final List<Widget> children;

  @override
  State<BeuiSelectContent> createState() => _BeuiSelectContentState();
}

class _BeuiSelectContentState extends State<BeuiSelectContent>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  late final BeuiSpringValue _open;
  _BeuiSelectState? _host;

  @override
  void initState() {
    super.initState();
    _open = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.panel)
      ..attach(this)
      ..addListener(_onSpring);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Overlay.maybeOf(context) != null && !_portal.isShowing) {
        _portal.show();
      }
      _syncSpring(jump: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _host = _SelectScope.of(context).state;
    _open.reducedMotion = beuiReduceMotion(context);
    _syncSpring();
  }

  @override
  void didUpdateWidget(BeuiSelectContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpring();
  }

  void _onSpring() {
    if (mounted) setState(() {});
  }

  void _syncSpring({bool jump = false}) {
    final host = _host;
    if (host == null) return;
    final target = host.open ? 1.0 : 0.0;
    if (jump) {
      _open.jump(target);
    } else {
      _open.animateTo(target);
    }
    if (host.open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) host.measurePlacement();
      });
    }
  }

  @override
  void dispose() {
    _open
      ..removeListener(_onSpring)
      ..dispose();
    super.dispose();
  }

  Widget _panel(_BeuiSelectState host) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final t = _open.value.clamp(0.0, 1.0);
    final open = host.open;
    final isTop = host.placement == BeuiSelectPlacement.top;
    final gap = (reduce ? (open ? 8.0 : 0.0) : 8.0 * t);
    final nearRadius = reduce
        ? (open ? 12.0 : 0.0)
        : 12.0 * Curves.easeOut.transform(t);
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isTop ? 12 : nearRadius),
      topRight: Radius.circular(isTop ? 12 : nearRadius),
      bottomLeft: Radius.circular(isTop ? nearRadius : 12),
      bottomRight: Radius.circular(isTop ? nearRadius : 12),
    );

    return BeuiPresence(
      present: open,
      child: Opacity(
          opacity: reduce ? (open ? 1 : 0) : t,
          child: Transform.translate(
            offset: Offset(0, isTop ? -gap : gap),
            child: ClipRect(
              child: Align(
                alignment: isTop ? Alignment.bottomCenter : Alignment.topCenter,
                heightFactor: t,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: radius,
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x1F000000),
                        blurRadius: 16,
                        offset: Offset(0, isTop ? -6 : 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    key: host.innerKey,
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.children,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final host = _SelectScope.of(context).state;
    _host = host;
    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);

    Widget scopedPanel() {
      return _SelectScope(
        state: host,
        open: host.open,
        value: host.value,
        activeValue: host.activeValue,
        placement: host.placement,
        enabled: host.enabled,
        child: _panel(host),
      );
    }

    if (overlay == null) {
      if (!host.open && _open.value < 0.01) {
        return const SizedBox(width: double.infinity, height: 0);
      }
      return scopedPanel();
    }

    if (!_portal.isShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_portal.isShowing) _portal.show();
      });
    }

    Rect? hole;
    final box = host.triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      hole = box.localToGlobal(Offset.zero) & box.size;
    }

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        if (!host.open) return const SizedBox.shrink();
        final view = MediaQuery.maybeSizeOf(context) ?? const Size(800, 600);
        final isTop = host.placement == BeuiSelectPlacement.top;
        return Stack(
          children: [
            Positioned.fill(
              child: BeuiOverlayDismiss(
                armed: host.dismiss.armed,
                hole: hole,
                onDismiss: () => host.setOpen(false),
              ),
            ),
            if (hole != null)
              Positioned(
                left: hole.left,
                width: hole.width,
                top: isTop ? null : hole.bottom,
                bottom: isTop ? view.height - hole.top : null,
                child: scopedPanel(),
              )
            else
              scopedPanel(),
          ],
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}

class BeuiSelectItem extends StatefulWidget {
  const BeuiSelectItem({
    super.key,
    required this.value,
    required this.child,
    this.label,
    this.enabled = true,
  });

  final String value;
  final Widget child;
  final String? label;
  final bool enabled;

  @override
  State<BeuiSelectItem> createState() => _BeuiSelectItemState();
}

class _BeuiSelectItemState extends State<BeuiSelectItem> {
  bool _hovered = false;
  _BeuiSelectState? _host;

  String get _label {
    if (widget.label != null) return widget.label!;
    final child = widget.child;
    if (child is Text) return child.data ?? widget.value;
    return widget.value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _host = _SelectScope.of(context).state;
    _host!.register(widget.value, _label, enabled: widget.enabled);
  }

  @override
  void didUpdateWidget(BeuiSelectItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _host?.register(widget.value, _label, enabled: widget.enabled);
  }

  @override
  void dispose() {
    _host?.unregister(widget.value);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = _SelectScope.of(context).state;
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final selected = host.value == widget.value;
    final active = host.activeValue == widget.value;
    final highlighted = (active || _hovered) && widget.enabled;
    final index = host._order.indexOf(widget.value);
    final t = host.open ? 1.0 : 0.0;
    final delay = 0.05 + math.max(index, 0) * 0.035;
    final local = reduce || !host.open
        ? t
        : ((t - delay) / 0.35).clamp(0.0, 1.0);
    final blur = reduce ? 0.0 : (3 * (1 - local)).clamp(0.0, 10.0);

    Widget row = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? () => host.select(widget.value) : null,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) {
          _hovered = true;
          if (widget.enabled) host.setActive(widget.value);
          beuiAfterPointer(() {
            if (mounted) setState(() {});
          });
        },
        onExit: (_) {
          _hovered = false;
          beuiAfterPointer(() {
            if (mounted) setState(() {});
          });
        },
        child: Semantics(
          button: true,
          enabled: widget.enabled,
          selected: selected,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected || highlighted ? colors.muted : null,
              borderRadius: BorderRadius.circular(BeuiRadii.md),
            ),
            child: Opacity(
              opacity: widget.enabled ? 1 : 0.5,
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: selected || highlighted
                            ? colors.foreground
                            : colors.mutedForeground,
                      ),
                      child: widget.child,
                    ),
                  ),
                  if (selected)
                    BeuiIcon(
                      BeuiIcons.check,
                      size: 14,
                      color: colors.foreground,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!reduce) {
      row = Opacity(
        opacity: local,
        child: Transform.translate(
          offset: Offset(0, -6 * (1 - local)),
          child: blur > 0.2
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: row,
                )
              : row,
        ),
      );
    }

    return row;
  }
}
