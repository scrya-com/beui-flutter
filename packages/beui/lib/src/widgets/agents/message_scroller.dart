import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import 'message_bubble.dart';

enum BeuiMessageScrollerNavigation { none, rail }

enum BeuiMessageFrom { user, assistant }

/// Marks a row the scroller can follow and, with [navigation] rail, preview.
class BeuiScrollerMessage extends StatelessWidget {
  const BeuiScrollerMessage({
    super.key,
    required this.id,
    required this.from,
    required this.text,
    required this.child,
  });

  final String id;
  final BeuiMessageFrom from;
  final String text;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class BeuiMessageRailItem {
  const BeuiMessageRailItem({
    required this.id,
    required this.label,
    this.description,
    this.from = BeuiMessageFrom.assistant,
  });

  final String id;
  final String label;
  final String? description;
  final BeuiMessageFrom from;
}

/// Reader-aware conversation viewport. Port of `MessageScroller`.
///
/// Follows streamed growth only at the live edge. Wheel, drag, and
/// ArrowUp/PageUp/Home release follow. Programmatic follow-scrolls are ignored.
class BeuiMessageScroller extends StatefulWidget {
  const BeuiMessageScroller({
    super.key,
    required this.children,
    this.followOutput = true,
    this.followThreshold = 56,
    this.smooth = true,
    this.onFollowChanged,
    this.label = 'Conversation',
    this.busy = false,
    this.navigation = BeuiMessageScrollerNavigation.none,
    this.navigationLabel = 'Message navigation',
    this.height = 420,
  });

  final List<Widget> children;
  final bool followOutput;
  final double followThreshold;
  final bool smooth;
  final ValueChanged<bool>? onFollowChanged;
  final String label;
  final bool busy;
  final BeuiMessageScrollerNavigation navigation;
  final String navigationLabel;
  final double? height;

  @override
  State<BeuiMessageScroller> createState() => _BeuiMessageScrollerState();
}

class _BeuiMessageScrollerState extends State<BeuiMessageScroller> {
  final _controller = ScrollController();
  final _contentKey = GlobalKey();
  final Map<String, GlobalKey> _rowKeys = {};
  bool _following = true;
  bool _programmatic = false;
  String _activeRailId = '';
  bool _railOverflowing = false;

  static const _titleLen = 56;
  static const _descLen = 88;

  @override
  void initState() {
    super.initState();
    _following = widget.followOutput;
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd(smooth: false));
  }

  @override
  void didUpdateWidget(BeuiMessageScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followOutput != oldWidget.followOutput) {
      _setFollowing(widget.followOutput);
      if (widget.followOutput) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd(smooth: false));
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncRail();
      _maybeFollow();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setFollowing(bool next) {
    if (_following == next) return;
    _following = next;
    widget.onFollowChanged?.call(next);
  }

  void _onScroll() {
    if (!_controller.hasClients || _programmatic) return;
    _updateFollowingFromOffset();
    _updateActiveRail();
  }

  void _updateFollowingFromOffset() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final distance = pos.maxScrollExtent - pos.pixels;
    _setFollowing(distance <= widget.followThreshold);
  }

  void _leaveLiveEdge() {
    _programmatic = false;
  }

  void _maybeFollow() {
    if (!widget.followOutput || !_following) return;
    _scrollToEnd(smooth: widget.smooth);
  }

  void _scrollToEnd({required bool smooth}) {
    if (!_controller.hasClients) return;
    final target = _controller.position.maxScrollExtent;
    if ((target - _controller.offset).abs() < 1) return;
    final reduce = beuiReduceMotion(context);
    _programmatic = true;
    if (smooth && !reduce) {
      _controller
          .animateTo(
            target,
            duration: const Duration(milliseconds: 320),
            curve: BeuiCurves.easeOut,
          )
          .whenComplete(() {
        _programmatic = false;
      });
    } else {
      _controller.jumpTo(target);
      _programmatic = false;
    }
  }

  void _scrollToId(String id) {
    final ctx = _rowKeys[id]?.currentContext;
    if (ctx == null) return;
    final items = _railItems();
    final last = items.isNotEmpty && items.last.id == id;
    setState(() => _activeRailId = id);
    if (last) {
      _setFollowing(true);
      _scrollToEnd(smooth: widget.smooth);
      return;
    }
    _setFollowing(false);
    _programmatic = true;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: (widget.smooth && !beuiReduceMotion(context))
          ? const Duration(milliseconds: 320)
          : Duration.zero,
      curve: BeuiCurves.easeOut,
    ).whenComplete(() {
      _programmatic = false;
    });
  }

  List<BeuiMessageRailItem> _railItems() {
    final rows = _scrollerMessages();
    final items = <BeuiMessageRailItem>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      String? description;
      if (row.text.length <= _titleLen) {
        if (row.from == BeuiMessageFrom.user) {
          BeuiScrollerMessage? next;
          for (var j = i + 1; j < rows.length; j++) {
            if (rows[j].from == BeuiMessageFrom.assistant) {
              next = rows[j];
              break;
            }
          }
          if (next != null && next.text.isNotEmpty) {
            description = _truncate(next.text, _descLen);
          }
        }
        items.add(
          BeuiMessageRailItem(
            id: row.id,
            label: row.text.isEmpty ? 'Message' : row.text,
            description: description,
            from: row.from,
          ),
        );
      } else {
        final titleEnd = _titleEnd(row.text);
        final rest = row.text.substring(titleEnd).trim();
        items.add(
          BeuiMessageRailItem(
            id: row.id,
            label: '${row.text.substring(0, titleEnd).trim()}…',
            description: rest.isEmpty ? null : _truncate(rest, _descLen),
            from: row.from,
          ),
        );
      }
    }
    return items;
  }

  List<BeuiScrollerMessage> _scrollerMessages() {
    return widget.children.whereType<BeuiScrollerMessage>().toList();
  }

  int _titleEnd(String text) {
    final excerpt = text.substring(0, _titleLen.clamp(0, text.length));
    final boundary = excerpt.lastIndexOf(' ');
    return boundary > _titleLen * 0.65 ? boundary : _titleLen.clamp(0, text.length);
  }

  String _truncate(String text, int limit) {
    if (text.length <= limit) return text;
    final excerpt = text.substring(0, limit);
    final boundary = excerpt.lastIndexOf(' ');
    final end = boundary > limit * 0.65 ? boundary : limit;
    return '${excerpt.substring(0, end).trim()}…';
  }

  void _syncRail() {
    if (widget.navigation != BeuiMessageScrollerNavigation.rail) return;
    if (!_controller.hasClients) return;
    final overflowing = _controller.position.maxScrollExtent > 1 &&
        _scrollerMessages().length > 1;
    if (overflowing != _railOverflowing) {
      setState(() => _railOverflowing = overflowing);
    }
    _updateActiveRail();
  }

  void _updateActiveRail() {
    if (widget.navigation != BeuiMessageScrollerNavigation.rail) return;
    if (!_controller.hasClients) return;
    final items = _scrollerMessages();
    if (items.isEmpty) return;
    final pos = _controller.position;
    String next;
    if (pos.pixels <= widget.followThreshold) {
      next = items.first.id;
    } else if (pos.maxScrollExtent - pos.pixels <= widget.followThreshold) {
      next = items.last.id;
    } else {
      next = items.first.id;
      var nearest = double.infinity;
      final viewportBox = context.findRenderObject() as RenderBox?;
      if (viewportBox == null || !viewportBox.hasSize) return;
      final viewCenter = viewportBox.size.height / 2;
      for (final row in items) {
        final box = _rowKeys[row.id]?.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) continue;
        final offset = box.localToGlobal(Offset.zero, ancestor: viewportBox);
        final center = offset.dy + box.size.height / 2;
        final d = (center - viewCenter).abs();
        if (d < nearest) {
          nearest = d;
          next = row.id;
        }
      }
    }
    if (next != _activeRailId) {
      setState(() => _activeRailId = next);
    }
  }

  Widget _wrapRows() {
    final rows = widget.children.map((child) {
      if (child is BeuiScrollerMessage) {
        final key = _rowKeys.putIfAbsent(child.id, GlobalKey.new);
        return KeyedSubtree(key: key, child: child);
      }
      return child;
    }).toList();
    return BeuiMessageBubbleGroup(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final viewport = Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) _leaveLiveEdge();
      },
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _syncRail();
              _maybeFollow();
            }
          });
          return false;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollStartNotification && n.dragDetails != null) {
              _leaveLiveEdge();
            }
            if (n is OverscrollNotification) _leaveLiveEdge();
            return false;
          },
          child: Semantics(
            label: widget.label,
            liveRegion: widget.busy,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                overscroll: false,
              ),
              child: SingleChildScrollView(
                controller: _controller,
                padding: EdgeInsets.fromLTRB(
                  16,
                  20,
                  widget.navigation == BeuiMessageScrollerNavigation.rail &&
                          _railOverflowing
                      ? 40
                      : 16,
                  20,
                ),
                child: SizeChangedLayoutNotifier(
                  key: _contentKey,
                  child: _wrapRows(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Widget body = Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.pageUp ||
                event.logicalKey == LogicalKeyboardKey.home)) {
          _leaveLiveEdge();
        }
        return KeyEventResult.ignored;
      },
      child: viewport,
    );

    if (widget.navigation == BeuiMessageScrollerNavigation.rail) {
      body = Stack(
        children: [
          Positioned.fill(child: body),
          if (_railOverflowing)
            Positioned(
              right: 4,
              top: 12,
              bottom: 12,
              width: 28,
              child: _MessageRail(
                label: widget.navigationLabel,
                items: _railItems(),
                activeId: _activeRailId,
                onSelect: _scrollToId,
              ),
            ),
        ],
      );
    }

    if (widget.height == null) return body;
    return SizedBox(height: widget.height, child: body);
  }
}

class _MessageRail extends StatelessWidget {
  const _MessageRail({
    required this.label,
    required this.items,
    required this.activeId,
    required this.onSelect,
  });

  final String label;
  final List<BeuiMessageRailItem> items;
  final String activeId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Column(
        children: [
          for (final item in items)
            Expanded(
              child: _RailTick(
                item: item,
                active: item.id == activeId,
                onSelect: () => onSelect(item.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailTick extends StatefulWidget {
  const _RailTick({
    required this.item,
    required this.active,
    required this.onSelect,
  });

  final BeuiMessageRailItem item;
  final bool active;
  final VoidCallback onSelect;

  @override
  State<_RailTick> createState() => _RailTickState();
}

class _RailTickState extends State<_RailTick> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return MouseRegion(
      onEnter: (_) {
        _hover = true;
        beuiAfterPointer(() {
          if (mounted) setState(() {});
        });
      },
      onExit: (_) {
        _hover = false;
        beuiAfterPointer(() {
          if (mounted) setState(() {});
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelect,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: BeuiCurves.easeOut,
                width: widget.active || _hover ? 16 : 12,
                height: 1,
                color: widget.active
                    ? colors.foreground
                    : colors.mutedForeground.withValues(alpha: 0.45),
              ),
            ),
            if (_hover)
              Positioned(
                right: 22,
                child: IgnorePointer(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(BeuiRadii.card),
                        border: Border.all(color: colors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.foreground,
                              ),
                            ),
                            if (widget.item.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  widget.item.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
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
              ),
          ],
        ),
      ),
    );
  }
}
