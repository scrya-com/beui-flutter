import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/keyboard.dart';
import '../../motion/overlay_dismiss.dart';
import '../../motion/presence.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

/// Fuzzy subsequence match used when no [BeuiCombobox.filter] is passed.
bool beuiComboboxDefaultFilter(
  String value,
  String query,
  List<String> keywords,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  final haystack = ([value, ...keywords].join(' ')).toLowerCase();
  var queryIndex = 0;
  for (var i = 0; i < haystack.length; i++) {
    if (haystack[i] == needle[queryIndex]) queryIndex += 1;
    if (queryIndex == needle.length) return true;
  }
  return false;
}

typedef BeuiComboboxFilter = bool Function(
  String value,
  String query,
  List<String> keywords,
);

enum BeuiComboboxSide { top, bottom }

enum BeuiComboboxAlign { start, center, end }

class _ComboboxItemData {
  _ComboboxItemData({
    required this.value,
    required this.label,
    required this.keywords,
    required this.enabled,
    required this.groupId,
  });

  String label;
  List<String> keywords;
  bool enabled;
  Object? groupId;
  final String value;
}

class _ComboboxScope extends InheritedWidget {
  const _ComboboxScope({
    required this.state,
    required this.open,
    required this.value,
    required this.query,
    required this.listQuery,
    required this.activeValue,
    required this.enabled,
    required this.side,
    required super.child,
  });

  final _BeuiComboboxState state;
  final bool open;
  final String? value;
  final String query;
  final String listQuery;
  final String? activeValue;
  final bool enabled;
  final BeuiComboboxSide side;

  static _ComboboxScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ComboboxScope>();
    assert(scope != null, 'Combobox parts must be used within BeuiCombobox');
    return scope!;
  }

  @override
  bool updateShouldNotify(_ComboboxScope oldWidget) =>
      open != oldWidget.open ||
      value != oldWidget.value ||
      query != oldWidget.query ||
      activeValue != oldWidget.activeValue ||
      enabled != oldWidget.enabled ||
      listQuery != oldWidget.listQuery ||
      side != oldWidget.side;
}

class _GroupScope extends InheritedWidget {
  const _GroupScope({required this.id, required super.child});

  final Object id;

  static Object? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GroupScope>()?.id;

  @override
  bool updateShouldNotify(_GroupScope oldWidget) => id != oldWidget.id;
}

/// Searchable combobox whose input is the trigger.
/// Port of `components/motion/combobox.tsx`.
class BeuiCombobox extends StatefulWidget {
  const BeuiCombobox({
    super.key,
    this.value,
    this.initialValue,
    this.onChanged,
    this.open,
    this.initialOpen = false,
    this.onOpenChanged,
    this.query,
    this.initialQuery = '',
    this.onQueryChanged,
    this.filter = beuiComboboxDefaultFilter,
    this.enabled = true,
    required this.child,
  });

  final String? value;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;
  final String? query;
  final String initialQuery;
  final ValueChanged<String>? onQueryChanged;
  final BeuiComboboxFilter filter;
  final bool enabled;
  final Widget child;

  @override
  State<BeuiCombobox> createState() => _BeuiComboboxState();
}

class _BeuiComboboxState extends State<BeuiCombobox> {
  late String? _internalValue;
  late bool _internalOpen;
  late String _internalQuery;
  final Map<String, _ComboboxItemData> items = {};
  final List<String> _order = [];
  final LayerLink link = LayerLink();
  final GlobalKey triggerKey = GlobalKey();
  final TextEditingController inputController = TextEditingController();
  final FocusNode inputFocus = FocusNode();

  String? _cursorId;
  String _cursorQuery = '';
  bool _openedOnce = false;
  String _openQuery = '';
  BeuiComboboxSide side = BeuiComboboxSide.bottom;
  String? activeValue;
  List<String> _latestEnabled = const [];
  final BeuiDismissArm dismiss = BeuiDismissArm();

  bool get _valueControlled => widget.value != null;
  bool get _openControlled => widget.open != null;
  bool get _queryControlled => widget.query != null;
  String? get value => _valueControlled ? widget.value : _internalValue;
  bool get open => _openControlled ? widget.open! : _internalOpen;
  String get query => _queryControlled ? widget.query! : _internalQuery;
  String get listQuery => open ? query : _openQuery;
  bool get enabled => widget.enabled;

  @override
  void initState() {
    super.initState();
    _internalValue = widget.initialValue ?? widget.value;
    _internalOpen = widget.initialOpen;
    _internalQuery = widget.initialQuery;
    _openQuery = _internalQuery;
    inputFocus
      ..addListener(_onFocus)
      ..onKeyEvent = (node, event) => handleKey(event)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
  }

  @override
  void dispose() {
    dismiss.cancel();
    inputFocus
      ..removeListener(_onFocus)
      ..dispose();
    inputController.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (inputFocus.hasFocus) {
      beuiRevealFocused(context);
      setOpen(true);
    }
  }

  void setQuery(String next) {
    if (!_queryControlled) setState(() => _internalQuery = next);
    widget.onQueryChanged?.call(next);
    if (_queryControlled) setState(() {});
  }

  void setOpen(bool next, {bool restoreFocus = false}) {
    if (!enabled && next) return;
    if (open == next) {
      if (restoreFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) inputFocus.requestFocus();
        });
      }
      return;
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
    if (!next) setQuery('');
    if (_openControlled) setState(() {});
    if (restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) inputFocus.requestFocus();
      });
    }
    if (next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) inputFocus.requestFocus();
      });
    }
  }

  void register(_ComboboxItemData item) {
    final existing = items[item.value];
    if (existing != null &&
        existing.label == item.label &&
        existing.enabled == item.enabled &&
        existing.groupId == item.groupId &&
        existing.keywords.join('\u0000') == item.keywords.join('\u0000')) {
      return;
    }
    items[item.value] = item;
    if (!_order.contains(item.value)) _order.add(item.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void unregister(String value) {
    if (items.remove(value) == null) return;
    _order.remove(value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  bool isVisible(String value) {
    if (listQuery.trim().isEmpty) return true;
    return _visibleIds().contains(value);
  }

  bool hasVisibleItems(Object groupId) {
    for (final id in _order) {
      final item = items[id];
      if (item != null && item.groupId == groupId && isVisible(id)) {
        return true;
      }
    }
    return false;
  }

  int get visibleCount => _visibleIds().length;

  List<String> _visibleIds() {
    final q = listQuery;
    return _order.where((id) {
      final item = items[id];
      if (item == null) return false;
      return widget.filter(item.value, q, [item.label, ...item.keywords]);
    }).toList(growable: false);
  }

  List<String> _enabledVisible() {
    return _visibleIds().where((id) => items[id]?.enabled ?? false).toList(
          growable: false,
        );
  }

  String? _liveCursor(List<String> enabled) {
    if (_cursorId == null || _cursorQuery != listQuery) return null;
    return enabled.contains(_cursorId) ? _cursorId : null;
  }

  void _resolveActive() {
    if (open && _openQuery != query) _openQuery = query;
    if (open) _openedOnce = true;
    final enabled = _enabledVisible();
    _latestEnabled = enabled;
    final live = _liveCursor(enabled);
    if (_cursorId != null && live == null) _cursorId = null;
    final derived = live ??
        (value != null && enabled.contains(value)
            ? value
            : (enabled.isEmpty ? null : enabled.first));
    activeValue = _openedOnce ? derived : null;
  }

  void setActiveValue(String? id) {
    beuiAfterPointer(() {
      if (!mounted) return;
      setState(() {
        _cursorId = id;
        _cursorQuery = listQuery;
      });
    });
  }

  void moveActive(Object direction) {
    if (!open) return;
    final rows = _latestEnabled;
    if (rows.isEmpty) {
      setState(() => _cursorId = null);
      return;
    }
    final last = rows.length - 1;
    setState(() {
      final live = _liveCursor(rows);
      final from = live ??
          (value != null && rows.contains(value) ? value : rows.first);
      final at = rows.indexOf(from!);
      final index = direction == 'first'
          ? 0
          : direction == 'last'
              ? last
              : (at + (direction as int) + rows.length) % rows.length;
      _cursorId = rows[index];
      _cursorQuery = listQuery;
    });
  }

  void select(String next) {
    final item = items[next];
    if (item != null && !item.enabled) return;
    if (!_valueControlled) setState(() => _internalValue = next);
    widget.onChanged?.call(next);
    setOpen(false, restoreFocus: true);
  }

  void selectActive() {
    final id = activeValue;
    if (id != null) select(id);
  }

  String? labelFor(String? id) => id == null ? null : items[id]?.label;

  void measureSide({
    required BeuiComboboxSide preferred,
    required bool avoidCollisions,
    required double sideOffset,
    required double contentHeight,
  }) {
    if (!open) return;
    final box = triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final view = MediaQuery.sizeOf(context);
    final below = view.height - (origin.dy + box.size.height);
    final above = origin.dy;
    BeuiComboboxSide next = preferred;
    if (avoidCollisions) {
      if (preferred == BeuiComboboxSide.bottom &&
          below < contentHeight + sideOffset &&
          above > below) {
        next = BeuiComboboxSide.top;
      } else if (preferred == BeuiComboboxSide.top &&
          above < contentHeight + sideOffset &&
          below > above) {
        next = BeuiComboboxSide.bottom;
      }
    }
    if (next != side) setState(() => side = next);
  }

  bool handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (!open) {
        setOpen(true);
        return true;
      }
      moveActive(key == LogicalKeyboardKey.arrowDown ? 1 : -1);
      return true;
    }
    if (key == LogicalKeyboardKey.home && open) {
      moveActive('first');
      return true;
    }
    if (key == LogicalKeyboardKey.end && open) {
      moveActive('last');
      return true;
    }
    if (key == LogicalKeyboardKey.enter) {
      if (open) {
        selectActive();
      } else {
        setOpen(true);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.escape && open) {
      setOpen(false, restoreFocus: true);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _resolveActive();
    _syncInputText();
    return _ComboboxScope(
      state: this,
      open: open,
      value: value,
      query: query,
      listQuery: listQuery,
      activeValue: activeValue,
      enabled: enabled,
      side: side,
      child: widget.child,
    );
  }

  void _syncInputText() {
    final next = open ? query : (labelFor(value) ?? '');
    if (inputController.text != next) {
      inputController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }
}

class BeuiComboboxTrigger extends StatefulWidget {
  const BeuiComboboxTrigger({super.key, required this.child});

  final Widget child;

  @override
  State<BeuiComboboxTrigger> createState() => _BeuiComboboxTriggerState();
}

class _BeuiComboboxTriggerState extends State<BeuiComboboxTrigger> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final host = _ComboboxScope.of(context).state;
    final colors = context.beuiColors;
    final focused = _focused || host.inputFocus.hasFocus;
    final border = focused || _hovered ? colors.borderStrong : colors.border;
    final ring = focused
        ? colors.ring.withValues(alpha: 0.4)
        : const Color(0x00000000);

    return CompositedTransformTarget(
      link: host.link,
      child: KeyedSubtree(
        key: host.triggerKey,
        child: MouseRegion(
          cursor: host.enabled
              ? SystemMouseCursors.text
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: host.enabled
                ? () {
                    host.inputFocus.requestFocus();
                    host.setOpen(true);
                  }
                : null,
            child: Focus(
              onFocusChange: (v) {
                _focused = v;
                beuiAfterPointer(() {
                  if (mounted) setState(() {});
                });
              },
              child: Opacity(
                opacity: host.enabled ? 1 : 0.5,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x00000000),
                    borderRadius: BorderRadius.circular(BeuiRadii.card),
                    border: Border.all(color: border),
                    boxShadow: focused
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
                      _ChevronsUpDown(color: colors.mutedForeground),
                    ],
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

class _ChevronsUpDown extends StatelessWidget {
  const _ChevronsUpDown({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 2),
            child: Transform.rotate(
              angle: 3.14159,
              child: BeuiIcon(BeuiIcons.chevronDown, size: 12, color: color),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -2),
            child: BeuiIcon(BeuiIcons.chevronDown, size: 12, color: color),
          ),
        ],
      ),
    );
  }
}

class BeuiComboboxInput extends StatelessWidget {
  const BeuiComboboxInput({
    super.key,
    this.placeholder = 'Search…',
    this.semanticLabel = 'Search options',
  });

  final String placeholder;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final host = _ComboboxScope.of(context).state;
    final colors = context.beuiColors;
    final empty = host.inputController.text.isEmpty;

    return Semantics(
      textField: true,
      label: semanticLabel,
      child: Row(
        children: [
          BeuiIcon(BeuiIcons.search, size: 16, color: colors.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (empty)
                  IgnorePointer(
                    child: Text(
                      placeholder,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.mutedForeground.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                EditableText(
                  controller: host.inputController,
                  focusNode: host.inputFocus,
                  readOnly: !host.enabled,
                  scrollPadding: beuiKeyboardScrollPadding,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: colors.foreground,
                  ),
                  cursorColor: colors.foreground,
                  backgroundCursorColor: colors.card,
                  onChanged: (v) {
                    host.setOpen(true);
                    host.setQuery(v);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BeuiComboboxContent extends StatefulWidget {
  const BeuiComboboxContent({
    super.key,
    required this.child,
    this.side = BeuiComboboxSide.bottom,
    this.align = BeuiComboboxAlign.start,
    this.sideOffset = 6,
    this.avoidCollisions = true,
  });

  final Widget child;
  final BeuiComboboxSide side;
  final BeuiComboboxAlign align;
  final double sideOffset;
  final bool avoidCollisions;

  @override
  State<BeuiComboboxContent> createState() => _BeuiComboboxContentState();
}

class _BeuiComboboxContentState extends State<BeuiComboboxContent>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _measureKey = GlobalKey();
  late final BeuiSpringValue _open;
  _BeuiComboboxState? _host;

  @override
  void initState() {
    super.initState();
    _open = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.panel)
      ..attach(this)
      ..addListener(_tick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Overlay.maybeOf(context) != null && !_portal.isShowing) {
        _portal.show();
      }
      _sync(jump: true);
    });
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _host = _ComboboxScope.of(context).state;
    _open.reducedMotion = beuiReduceMotion(context);
    _sync();
  }

  @override
  void didUpdateWidget(BeuiComboboxContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync({bool jump = false}) {
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
        if (!mounted) return;
        final box =
            _measureKey.currentContext?.findRenderObject() as RenderBox?;
        host.measureSide(
          preferred: widget.side,
          avoidCollisions: widget.avoidCollisions,
          sideOffset: widget.sideOffset,
          contentHeight: box?.size.height ?? 0,
        );
      });
    }
  }

  @override
  void dispose() {
    _open
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  Widget _panel(_BeuiComboboxState host) {
    final colors = context.beuiColors;
    final t = _open.value.clamp(0.0, 1.0);
    final reduce = beuiReduceMotion(context);
    final isTop = host.side == BeuiComboboxSide.top;
    final gap = widget.sideOffset * (reduce ? (host.open ? 1.0 : 0.0) : t);

    return BeuiPresence(
      present: host.open,
      child: Opacity(
          opacity: reduce ? (host.open ? 1 : 0) : t,
          child: Transform.translate(
            offset: Offset(0, isTop ? -gap : gap),
            child: ClipRect(
              child: Align(
                alignment:
                    isTop ? Alignment.bottomCenter : Alignment.topCenter,
                heightFactor: t,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(BeuiRadii.card),
                    border: Border.all(color: colors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: KeyedSubtree(key: _measureKey, child: widget.child),
                ),
              ),
            ),
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final host = _ComboboxScope.of(context).state;
    _host = host;
    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);

    Widget scopedPanel() {
      return _ComboboxScope(
        state: host,
        open: host.open,
        value: host.value,
        query: host.query,
        listQuery: host.listQuery,
        activeValue: host.activeValue,
        enabled: host.enabled,
        side: host.side,
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
        final isTop = host.side == BeuiComboboxSide.top;
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

class BeuiComboboxList extends StatelessWidget {
  const BeuiComboboxList({
    super.key,
    required this.children,
    this.semanticLabel = 'Options',
  });

  final List<Widget> children;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 256),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

class BeuiComboboxGroup extends StatefulWidget {
  const BeuiComboboxGroup({super.key, required this.child});

  final Widget child;

  @override
  State<BeuiComboboxGroup> createState() => _BeuiComboboxGroupState();
}

class _BeuiComboboxGroupState extends State<BeuiComboboxGroup> {
  final Object _id = Object();

  @override
  Widget build(BuildContext context) {
    final host = _ComboboxScope.of(context).state;
    final visible = host.hasVisibleItems(_id);
    return _GroupScope(
      id: _id,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: visible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !visible,
            child: ExcludeSemantics(
              excluding: !visible,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class BeuiComboboxLabel extends StatelessWidget {
  const BeuiComboboxLabel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: colors.mutedForeground,
        ),
        child: child,
      ),
    );
  }
}

class BeuiComboboxItem extends StatefulWidget {
  const BeuiComboboxItem({
    super.key,
    required this.value,
    required this.child,
    this.textValue,
    this.keywords = const [],
    this.enabled = true,
    this.onSelect,
  });

  final String value;
  final Widget child;
  final String? textValue;
  final List<String> keywords;
  final bool enabled;
  final ValueChanged<String>? onSelect;

  @override
  State<BeuiComboboxItem> createState() => _BeuiComboboxItemState();
}

class _BeuiComboboxItemState extends State<BeuiComboboxItem> {
  _BeuiComboboxState? _host;

  String get _label {
    if (widget.textValue != null) return widget.textValue!;
    final child = widget.child;
    if (child is Text) return child.data ?? widget.value;
    return widget.value;
  }

  void _register(Object? groupId) {
    _host?.register(
      _ComboboxItemData(
        value: widget.value,
        label: _label,
        keywords: widget.keywords,
        enabled: widget.enabled,
        groupId: groupId,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _host = _ComboboxScope.of(context).state;
    _register(_GroupScope.maybeOf(context));
  }

  @override
  void didUpdateWidget(BeuiComboboxItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _register(_GroupScope.maybeOf(context));
  }

  @override
  void dispose() {
    _host?.unregister(widget.value);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = _ComboboxScope.of(context).state;
    if (!host.isVisible(widget.value)) return const SizedBox.shrink();
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final selected = host.value == widget.value;
    final active = host.activeValue == widget.value;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled
          ? () {
              widget.onSelect?.call(widget.value);
              host.select(widget.value);
            }
          : null,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) {
          if (widget.enabled) host.setActiveValue(widget.value);
        },
        child: Semantics(
          button: true,
          enabled: widget.enabled,
          selected: selected,
          child: AnimatedContainer(
            duration: Duration(milliseconds: reduce ? 0 : 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: active ? colors.muted : null,
              borderRadius: BorderRadius.circular(BeuiRadii.md),
            ),
            child: Opacity(
              opacity: widget.enabled ? 1 : 0.45,
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 14,
                        color: active
                            ? colors.foreground
                            : colors.mutedForeground,
                      ),
                      child: widget.child,
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: Duration(milliseconds: reduce ? 0 : 140),
                    curve: BeuiCurves.easeOut,
                    child: Transform.scale(
                      scale: selected ? 1 : 0.82,
                      child: BeuiIcon(
                        BeuiIcons.check,
                        size: 16,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BeuiComboboxEmpty extends StatelessWidget {
  const BeuiComboboxEmpty({
    super.key,
    this.child = const Text('No options found.'),
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final host = _ComboboxScope.of(context).state;
    if (host.visibleCount > 0) return const SizedBox.shrink();
    final colors = context.beuiColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 32),
      child: DefaultTextStyle(
        style: TextStyle(fontSize: 14, color: colors.mutedForeground),
        textAlign: TextAlign.center,
        child: child,
      ),
    );
  }
}

class BeuiComboboxSeparator extends StatelessWidget {
  const BeuiComboboxSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 1,
      color: context.beuiColors.border,
    );
  }
}

class BeuiComboboxValue extends StatelessWidget {
  const BeuiComboboxValue({
    super.key,
    this.placeholder = 'Select an option',
  });

  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final host = _ComboboxScope.of(context).state;
    final colors = context.beuiColors;
    final label = host.labelFor(host.value);
    return Text(
      label ?? placeholder,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        color: label == null ? colors.mutedForeground : colors.foreground,
      ),
    );
  }
}
