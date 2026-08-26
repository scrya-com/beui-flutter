import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import 'message_bubble.dart';

/// Reader-aware conversation viewport. Port of `MessageScroller`.
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
    this.height = 420,
  });

  final List<Widget> children;
  final bool followOutput;
  final double followThreshold;
  final bool smooth;
  final ValueChanged<bool>? onFollowChanged;
  final String label;
  final bool busy;
  final double height;

  @override
  State<BeuiMessageScroller> createState() => _BeuiMessageScrollerState();
}

class _BeuiMessageScrollerState extends State<BeuiMessageScroller> {
  final _controller = ScrollController();
  bool _following = true;

  @override
  void initState() {
    super.initState();
    _following = widget.followOutput;
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(BeuiMessageScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFollow());
    }
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final distance = _controller.position.maxScrollExtent - _controller.offset;
    final atEdge = distance <= widget.followThreshold;
    if (atEdge != _following) {
      _following = atEdge;
      widget.onFollowChanged?.call(_following);
    }
  }

  void _maybeFollow() {
    if (!widget.followOutput || !_following || !_controller.hasClients) return;
    final reduce = beuiReduceMotion(context);
    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: (widget.smooth && !reduce)
          ? const Duration(milliseconds: 220)
          : Duration.zero,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      liveRegion: widget.busy,
      child: SizedBox(
        height: widget.height,
        child: ListView(
          controller: _controller,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            BeuiMessageBubbleGroup(children: widget.children),
          ],
        ),
      ),
    );
  }
}
