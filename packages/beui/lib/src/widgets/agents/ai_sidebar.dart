import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

enum BeuiSidebarResourceKind { folder, project, file, bookmark }

enum BeuiSidebarDropPosition { before, inside, after }

class BeuiSidebarResource {
  const BeuiSidebarResource({
    required this.id,
    required this.label,
    required this.kind,
    this.children,
    this.disabled = false,
  });

  final String id;
  final String label;
  final BeuiSidebarResourceKind kind;
  final List<BeuiSidebarResource>? children;
  final bool disabled;

  BeuiSidebarResource copyWith({
    String? label,
    List<BeuiSidebarResource>? children,
  }) {
    return BeuiSidebarResource(
      id: id,
      label: label ?? this.label,
      kind: kind,
      children: children ?? this.children,
      disabled: disabled,
    );
  }
}

class BeuiSidebarResourceMove {
  const BeuiSidebarResourceMove({
    required this.itemId,
    required this.targetId,
    required this.position,
  });

  final String itemId;
  final String? targetId;
  final BeuiSidebarDropPosition position;
}

bool beuiSidebarCanContain(BeuiSidebarResource item) =>
    item.kind == BeuiSidebarResourceKind.folder ||
    item.kind == BeuiSidebarResourceKind.project;

BeuiSidebarResource? beuiFindResource(
  List<BeuiSidebarResource> items,
  String id,
) {
  for (final item in items) {
    if (item.id == id) return item;
    final children = item.children;
    if (children != null) {
      final found = beuiFindResource(children, id);
      if (found != null) return found;
    }
  }
  return null;
}

bool _contains(BeuiSidebarResource item, String id) {
  return item.id == id ||
      (item.children?.any((child) => _contains(child, id)) ?? false);
}

({List<BeuiSidebarResource> items, BeuiSidebarResource? removed})
    _removeResource(List<BeuiSidebarResource> items, String id) {
  BeuiSidebarResource? removed;
  final next = <BeuiSidebarResource>[];
  for (final item in items) {
    if (item.id == id) {
      removed = item;
      continue;
    }
    final children = item.children;
    if (children != null && children.isNotEmpty) {
      final child = _removeResource(children, id);
      if (child.removed != null) {
        removed = child.removed;
        next.add(item.copyWith(children: child.items));
        continue;
      }
    }
    next.add(item);
  }
  return (items: next, removed: removed);
}

List<BeuiSidebarResource> _insertResource(
  List<BeuiSidebarResource> items,
  BeuiSidebarResource resource,
  String? targetId,
  BeuiSidebarDropPosition position,
) {
  if (targetId == null) return [...items, resource];
  final next = <BeuiSidebarResource>[];
  for (final item in items) {
    if (item.id == targetId) {
      if (position == BeuiSidebarDropPosition.before) {
        next.addAll([resource, item]);
      } else if (position == BeuiSidebarDropPosition.after) {
        next.addAll([item, resource]);
      } else {
        next.add(
          item.copyWith(children: [...?item.children, resource]),
        );
      }
      continue;
    }
    final children = item.children;
    if (children != null && children.isNotEmpty) {
      next.add(
        item.copyWith(
          children: _insertResource(children, resource, targetId, position),
        ),
      );
    } else {
      next.add(item);
    }
  }
  return next;
}

List<BeuiSidebarResource>? beuiMoveResource(
  List<BeuiSidebarResource> items,
  BeuiSidebarResourceMove move,
) {
  final source = beuiFindResource(items, move.itemId);
  if (source == null || source.disabled) return null;
  if (move.targetId != null && _contains(source, move.targetId!)) return null;
  final target =
      move.targetId == null ? null : beuiFindResource(items, move.targetId!);
  if (move.position == BeuiSidebarDropPosition.inside &&
      (target == null || target.disabled || !beuiSidebarCanContain(target))) {
    return null;
  }
  final removed = _removeResource(items, move.itemId);
  if (removed.removed == null) return null;
  return _insertResource(
    removed.items,
    removed.removed!,
    move.targetId,
    move.position,
  );
}

List<BeuiSidebarResource> beuiRenameResource(
  List<BeuiSidebarResource> items,
  String id,
  String label,
) {
  return [
    for (final item in items)
      item.copyWith(
        label: item.id == id ? label : item.label,
        children: item.children == null
            ? null
            : beuiRenameResource(item.children!, id, label),
      ),
  ];
}

class _FlatRow {
  const _FlatRow({
    required this.item,
    required this.depth,
    required this.parentId,
  });

  final BeuiSidebarResource item;
  final int depth;
  final String? parentId;
}

List<_FlatRow> _flatten(
  List<BeuiSidebarResource> items,
  Set<String> expanded, {
  int depth = 0,
  String? parentId,
}) {
  final out = <_FlatRow>[];
  for (final item in items) {
    out.add(_FlatRow(item: item, depth: depth, parentId: parentId));
    if (item.children != null &&
        item.children!.isNotEmpty &&
        expanded.contains(item.id)) {
      out.addAll(
        _flatten(
          item.children!,
          expanded,
          depth: depth + 1,
          parentId: item.id,
        ),
      );
    }
  }
  return out;
}

/// Collapsible resource tree. Port of `components/agents/ai-sidebar.tsx`.
class BeuiAISidebar extends StatefulWidget {
  const BeuiAISidebar({
    super.key,
    this.items,
    this.initialItems = const [],
    this.onItemsChanged,
    this.onMove,
    this.onRename,
    this.activeId,
    this.initialActiveId,
    this.onActiveChanged,
    this.initialExpandedIds = const [],
    this.semanticLabel = 'Resources',
  });

  final List<BeuiSidebarResource>? items;
  final List<BeuiSidebarResource> initialItems;
  final ValueChanged<List<BeuiSidebarResource>>? onItemsChanged;
  final Future<void> Function(BeuiSidebarResourceMove move)? onMove;
  final Future<void> Function(BeuiSidebarResource item, String label)? onRename;
  final String? activeId;
  final String? initialActiveId;
  final ValueChanged<String>? onActiveChanged;
  final List<String> initialExpandedIds;
  final String semanticLabel;

  @override
  State<BeuiAISidebar> createState() => _BeuiAISidebarState();
}

class _BeuiAISidebarState extends State<BeuiAISidebar> {
  late List<BeuiSidebarResource> _internal;
  late String? _internalActive;
  late Set<String> _expanded;
  String? _focusedId;
  String? _draggingId;
  String? _dropId;
  BeuiSidebarDropPosition? _dropPosition;
  String? _menuId;
  String? _renamingId;
  String _live = '';
  bool _movePending = false;

  bool get _itemsControlled => widget.items != null;
  List<BeuiSidebarResource> get _items => widget.items ?? _internal;

  @override
  void initState() {
    super.initState();
    _internal = List.of(widget.initialItems);
    _internalActive = widget.initialActiveId;
    _expanded = {...widget.initialExpandedIds};
    _focusedId = widget.activeId ?? widget.initialActiveId;
  }

  void _commit(List<BeuiSidebarResource> next) {
    if (!_itemsControlled) setState(() => _internal = next);
    widget.onItemsChanged?.call(next);
  }

  Future<void> _performMove(BeuiSidebarResourceMove move) async {
    if (_movePending) {
      setState(() => _live = 'Wait for the current move to finish.');
      return;
    }
    final before = _items;
    final next = beuiMoveResource(before, move);
    if (next == null) return;
    _movePending = true;
    _commit(next);
    setState(() {
      _dropId = null;
      _draggingId = null;
    });
    try {
      await widget.onMove?.call(move);
    } catch (_) {
      _commit(before);
      setState(() => _live = 'Move failed.');
    } finally {
      _movePending = false;
    }
  }

  void _select(String id) {
    if (widget.activeId == null) setState(() => _internalActive = id);
    widget.onActiveChanged?.call(id);
  }

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final selected = widget.activeId ?? _internalActive;
    final flat = _flatten(_items, _expanded);
    final focused = ( _focusedId != null &&
            flat.any((r) => r.item.id == _focusedId))
        ? _focusedId
        : (flat.isEmpty ? null : flat.first.item.id);

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      liveRegion: true,
      value: _live,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          for (final row in flat)
            _ResourceRow(
              key: ValueKey(row.item.id),
              row: row,
              active: selected == row.item.id,
              expanded: _expanded.contains(row.item.id),
              focused: focused == row.item.id,
              dragging: _draggingId == row.item.id,
              drop: _dropId == row.item.id ? _dropPosition : null,
              menuOpen: _menuId == row.item.id,
              renaming: _renamingId == row.item.id,
              onFocus: () => setState(() => _focusedId = row.item.id),
              onSelect: () => _select(row.item.id),
              onToggle: () => _toggle(row.item.id),
              onRenameStart: () => setState(() => _renamingId = row.item.id),
              onRenameCancel: () => setState(() => _renamingId = null),
              onRenameCommit: (label) {
                final trimmed = label.trim();
                setState(() => _renamingId = null);
                if (trimmed.isEmpty || trimmed == row.item.label) return;
                final before = _items;
                _commit(beuiRenameResource(before, row.item.id, trimmed));
                widget.onRename?.call(row.item, trimmed);
              },
              onMenu: () => setState(
                () => _menuId = _menuId == row.item.id ? null : row.item.id,
              ),
              onMoveUp: () {
                final i = flat.indexWhere((r) => r.item.id == row.item.id);
                if (i <= 0) return;
                _performMove(
                  BeuiSidebarResourceMove(
                    itemId: row.item.id,
                    targetId: flat[i - 1].item.id,
                    position: BeuiSidebarDropPosition.before,
                  ),
                );
              },
              onMoveDown: () {
                final i = flat.indexWhere((r) => r.item.id == row.item.id);
                if (i < 0 || i >= flat.length - 1) return;
                _performMove(
                  BeuiSidebarResourceMove(
                    itemId: row.item.id,
                    targetId: flat[i + 1].item.id,
                    position: BeuiSidebarDropPosition.after,
                  ),
                );
              },
              onDragStarted: () => setState(() => _draggingId = row.item.id),
              onDragEnded: () => setState(() {
                _draggingId = null;
                _dropId = null;
              }),
              onDragOver: (localY, height) {
                if (_draggingId == null || _draggingId == row.item.id) return;
                final source = beuiFindResource(_items, _draggingId!);
                if (source != null && _contains(source, row.item.id)) return;
                final ratio = height <= 0 ? 0.5 : localY / height;
                final position = !row.item.disabled &&
                        beuiSidebarCanContain(row.item) &&
                        ratio >= 0.25 &&
                        ratio <= 0.75
                    ? BeuiSidebarDropPosition.inside
                    : ratio < 0.5
                        ? BeuiSidebarDropPosition.before
                        : BeuiSidebarDropPosition.after;
                setState(() {
                  _dropId = row.item.id;
                  _dropPosition = position;
                });
              },
              onDrop: () {
                if (_draggingId == null || _dropId == null) return;
                _performMove(
                  BeuiSidebarResourceMove(
                    itemId: _draggingId!,
                    targetId: _dropId,
                    position: _dropPosition ?? BeuiSidebarDropPosition.after,
                  ),
                );
              },
              onKey: (event) => _onKey(event, row, flat),
            ),
          if (_draggingId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const SizedBox(
                  height: 32,
                  child: Center(
                    child: Text(
                      'Move to top level',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  KeyEventResult _onKey(
    KeyEvent event,
    _FlatRow row,
    List<_FlatRow> flat,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final i = flat.indexWhere((r) => r.item.id == row.item.id);
    final prev = i > 0 ? flat[i - 1] : null;
    final next = i >= 0 && i < flat.length - 1 ? flat[i + 1] : null;
    final move = HardwareKeyboard.instance.isAltPressed &&
        HardwareKeyboard.instance.isShiftPressed;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown && !move && next != null) {
      setState(() => _focusedId = next.item.id);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp && !move && prev != null) {
      setState(() => _focusedId = prev.item.id);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (beuiSidebarCanContain(row.item)) {
        _toggle(row.item.id);
      } else {
        _select(row.item.id);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f2) {
      setState(() => _renamingId = row.item.id);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight &&
        beuiSidebarCanContain(row.item)) {
      if (!_expanded.contains(row.item.id)) {
        _toggle(row.item.id);
      } else if (next?.parentId == row.item.id) {
        setState(() => _focusedId = next!.item.id);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (_expanded.contains(row.item.id)) {
        _toggle(row.item.id);
      } else if (row.parentId != null) {
        setState(() => _focusedId = row.parentId);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class _ResourceRow extends StatefulWidget {
  const _ResourceRow({
    super.key,
    required this.row,
    required this.active,
    required this.expanded,
    required this.focused,
    required this.dragging,
    required this.drop,
    required this.menuOpen,
    required this.renaming,
    required this.onFocus,
    required this.onSelect,
    required this.onToggle,
    required this.onRenameStart,
    required this.onRenameCancel,
    required this.onRenameCommit,
    required this.onMenu,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onDragOver,
    required this.onDrop,
    required this.onKey,
  });

  final _FlatRow row;
  final bool active;
  final bool expanded;
  final bool focused;
  final bool dragging;
  final BeuiSidebarDropPosition? drop;
  final bool menuOpen;
  final bool renaming;
  final VoidCallback onFocus;
  final VoidCallback onSelect;
  final VoidCallback onToggle;
  final VoidCallback onRenameStart;
  final VoidCallback onRenameCancel;
  final ValueChanged<String> onRenameCommit;
  final VoidCallback onMenu;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final void Function(double localY, double height) onDragOver;
  final VoidCallback onDrop;
  final KeyEventResult Function(KeyEvent event) onKey;

  @override
  State<_ResourceRow> createState() => _ResourceRowState();
}

class _ResourceRowState extends State<_ResourceRow> {
  bool _hover = false;

  BeuiIconPainter get _icon {
    final item = widget.row.item;
    if (item.kind == BeuiSidebarResourceKind.folder ||
        item.kind == BeuiSidebarResourceKind.project) {
      return widget.expanded ? BeuiIcons.folderOpen : BeuiIcons.folder;
    }
    if (item.kind == BeuiSidebarResourceKind.bookmark) {
      return BeuiIcons.bookmark;
    }
    return BeuiIcons.fileText;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final item = widget.row.item;
    final contains = beuiSidebarCanContain(item);
    final highlighted = widget.active && !contains || widget.menuOpen;
    final dropInside = widget.drop == BeuiSidebarDropPosition.inside;

    Widget row = Focus(
      autofocus: widget.focused,
      onFocusChange: (v) {
        if (v) widget.onFocus();
      },
      onKeyEvent: (node, event) => widget.onKey(event),
      child: MouseRegion(
        onEnter: (_) => beuiAfterPointer(() {
          if (!mounted) return;
          setState(() => _hover = true);
        }),
        onExit: (_) => beuiAfterPointer(() {
          if (!mounted) return;
          setState(() => _hover = false);
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: item.disabled
              ? null
              : () {
                  if (contains) {
                    widget.onToggle();
                  } else {
                    widget.onSelect();
                  }
                },
          onDoubleTap: contains || item.disabled ? null : widget.onRenameStart,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: BeuiCurves.easeOut,
            constraints: const BoxConstraints(minHeight: 36),
            padding: EdgeInsets.fromLTRB(
              12 + widget.row.depth * 16,
              0,
              12,
              0,
            ),
            decoration: BoxDecoration(
              color: dropInside
                  ? colors.primary.withValues(alpha: 0.1)
                  : highlighted
                      ? colors.muted
                      : _hover
                          ? colors.muted.withValues(alpha: 0.7)
                          : const Color(0x00000000),
              borderRadius: BorderRadius.circular(12),
              border: dropInside
                  ? Border.all(color: colors.primary.withValues(alpha: 0.45))
                  : widget.drop == BeuiSidebarDropPosition.before
                      ? Border(
                          top: BorderSide(color: colors.primary, width: 2),
                        )
                      : widget.drop == BeuiSidebarDropPosition.after
                          ? Border(
                              bottom: BorderSide(color: colors.primary, width: 2),
                            )
                          : null,
            ),
            child: Opacity(
              opacity: widget.dragging || item.disabled ? 0.4 : 1,
              child: Row(
                spacing: 10,
                children: [
                  BeuiIcon(_icon, size: 16, color: colors.mutedForeground),
                  if (widget.renaming)
                    Expanded(
                      child: _RenameField(
                        initial: item.label,
                        onCommit: widget.onRenameCommit,
                        onCancel: widget.onRenameCancel,
                      ),
                    )
                  else
                    Expanded(
                      child: _MarqueeLabel(
                        text: item.label,
                        active: _hover || widget.menuOpen,
                        color: highlighted
                            ? colors.foreground
                            : colors.mutedForeground,
                      ),
                    ),
                  if (!widget.renaming && !item.disabled)
                    GestureDetector(
                      onTap: widget.onMenu,
                      child: Opacity(
                        opacity: _hover || widget.menuOpen || !beuiHoverCapable(context)
                            ? 1
                            : 0,
                        child: BeuiIcon(
                          BeuiIcons.moreHorizontal,
                          size: 16,
                          color: colors.mutedForeground,
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

    if (widget.menuOpen) {
      row = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row,
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 4, bottom: 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.popover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  _MenuItem(
                    icon: BeuiIcons.pencil,
                    label: 'Rename',
                    onTap: widget.onRenameStart,
                  ),
                  _MenuItem(
                    icon: BeuiIcons.arrowUp,
                    label: 'Move up',
                    onTap: widget.onMoveUp,
                  ),
                  _MenuItem(
                    icon: BeuiIcons.arrowDown,
                    label: 'Move down',
                    onTap: widget.onMoveDown,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (Overlay.maybeOf(context) == null) return row;
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != item.id,
      onMove: (d) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final local = box.globalToLocal(d.offset);
        widget.onDragOver(local.dy, box.size.height);
      },
      onAcceptWithDetails: (_) => widget.onDrop(),
      builder: (context, candidate, rejected) {
        return LongPressDraggable<String>(
          data: item.id,
          onDragStarted: widget.onDragStarted,
          onDragEnd: (_) => widget.onDragEnded(),
          feedback: Text(
            item.label,
            style: TextStyle(color: colors.foreground, fontSize: 13),
          ),
          child: row,
        );
      },
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final BeuiIconPainter icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          spacing: 8,
          children: [
            BeuiIcon(icon, size: 14, color: colors.foreground),
            Text(label, style: TextStyle(fontSize: 12, color: colors.foreground)),
          ],
        ),
      ),
    );
  }
}

class _RenameField extends StatefulWidget {
  const _RenameField({
    required this.initial,
    required this.onCommit,
    required this.onCancel,
  });

  final String initial;
  final ValueChanged<String> onCommit;
  final VoidCallback onCancel;

  @override
  State<_RenameField> createState() => _RenameFieldState();
}

class _RenameFieldState extends State<_RenameField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
    _focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onCommit(_controller.text);
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
        }
      },
      child: EditableText(
        controller: _controller,
        focusNode: _focus,
        style: TextStyle(fontSize: 14, color: colors.foreground),
        cursorColor: colors.foreground,
        backgroundCursorColor: colors.muted,
        onSubmitted: widget.onCommit,
      ),
    );
  }
}

class _MarqueeLabel extends StatelessWidget {
  const _MarqueeLabel({
    required this.text,
    required this.active,
    required this.color,
  });

  final String text;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 14, color: color),
    );
  }
}
