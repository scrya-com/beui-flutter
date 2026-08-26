import 'package:flutter/widgets.dart';

import '../../motion/pop_in.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import 'disclosure.dart';
import 'thinking_shimmer.dart';

enum BeuiAgentActivityStatus { working, complete }

enum BeuiAgentStepStatus { pending, active, complete }

enum BeuiAgentActivityKind { step, text, search, tool, trace }

class BeuiAgentSearchResult {
  const BeuiAgentSearchResult({
    required this.id,
    required this.title,
    this.domain,
  });
  final String id;
  final String title;
  final String? domain;
}

class BeuiAgentActivityItem {
  const BeuiAgentActivityItem.step({
    required this.id,
    required this.label,
    this.status = BeuiAgentStepStatus.pending,
  })  : kind = BeuiAgentActivityKind.step,
        content = null,
        query = null,
        results = const [],
        action = null,
        target = null,
        additions = null,
        deletions = null;

  const BeuiAgentActivityItem.text({
    required this.id,
    required this.content,
  })  : kind = BeuiAgentActivityKind.text,
        label = null,
        status = null,
        query = null,
        results = const [],
        action = null,
        target = null,
        additions = null,
        deletions = null;

  const BeuiAgentActivityItem.search({
    required this.id,
    required this.query,
    this.results = const [],
  })  : kind = BeuiAgentActivityKind.search,
        label = null,
        status = null,
        content = null,
        action = null,
        target = null,
        additions = null,
        deletions = null;

  const BeuiAgentActivityItem.tool({
    required this.id,
    required this.action,
    required this.target,
    this.additions,
    this.deletions,
  })  : kind = BeuiAgentActivityKind.tool,
        label = null,
        status = null,
        content = null,
        query = null,
        results = const [];

  final String id;
  final BeuiAgentActivityKind kind;
  final String? label;
  final BeuiAgentStepStatus? status;
  final String? content;
  final String? query;
  final List<BeuiAgentSearchResult> results;
  final String? action;
  final String? target;
  final int? additions;
  final int? deletions;
}

/// Adaptive activity disclosure. Port of `AgentActivity`.
class BeuiAgentActivity extends StatefulWidget {
  const BeuiAgentActivity({
    super.key,
    required this.items,
    this.status = BeuiAgentActivityStatus.working,
    this.duration = 0,
    this.open,
    this.initialOpen = true,
    this.onOpenChanged,
    this.collapseOnComplete = true,
    this.activeLabel = 'Working',
    this.maxHeight = 220,
  });

  final List<BeuiAgentActivityItem> items;
  final BeuiAgentActivityStatus status;
  final double duration;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;
  final bool collapseOnComplete;
  final String activeLabel;
  final double maxHeight;

  @override
  State<BeuiAgentActivity> createState() => _BeuiAgentActivityState();
}

class _BeuiAgentActivityState extends State<BeuiAgentActivity> {
  late bool _internal;
  BeuiAgentActivityStatus? _prev;

  bool get _controlled => widget.open != null;
  bool get _open {
    if (widget.status == BeuiAgentActivityStatus.working) return true;
    return _controlled ? widget.open! : _internal;
  }

  @override
  void initState() {
    super.initState();
    _internal = widget.initialOpen;
    _prev = widget.status;
  }

  @override
  void didUpdateWidget(BeuiAgentActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_prev == BeuiAgentActivityStatus.complete &&
        widget.status == BeuiAgentActivityStatus.working) {
      _setOpen(true);
    }
    if (_prev == BeuiAgentActivityStatus.working &&
        widget.status == BeuiAgentActivityStatus.complete &&
        widget.collapseOnComplete) {
      _setOpen(false);
    }
    _prev = widget.status;
  }

  void _setOpen(bool next) {
    if (!_controlled) setState(() => _internal = next);
    widget.onOpenChanged?.call(next);
  }

  String get _summary {
    final tools = widget.items.where((i) => i.kind == BeuiAgentActivityKind.tool);
    if (tools.isNotEmpty) return '${tools.length} tool calls';
    final searches =
        widget.items.where((i) => i.kind == BeuiAgentActivityKind.search);
    if (searches.isNotEmpty) return 'Searched the web';
    return 'Finished';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final working = widget.status == BeuiAgentActivityStatus.working;
    final seconds = widget.duration.round();
    final durationLabel =
        seconds < 60 ? '${seconds}s' : '${seconds ~/ 60}m ${seconds % 60}s';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: working ? null : () => _setOpen(!_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: working
                        ? BeuiThinkingShimmer(text: widget.activeLabel)
                        : Text(
                            _summary,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colors.foreground,
                            ),
                          ),
                  ),
                  Text(
                    durationLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: colors.mutedForeground,
                    ),
                  ),
                  if (!working)
                    BeuiSpringBuilder(
                      value: _open ? 1 : 0,
                      spec: BeuiSpringSpec.swap,
                      builder: (context, t) {
                        return Transform.rotate(
                          angle: t * 3.14159,
                          child: BeuiIcon(
                            BeuiIcons.chevronDown,
                            size: 16,
                            color: colors.mutedForeground,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          BeuiAgentDisclosure(
            open: _open,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxHeight),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                children: [
                  for (final item in widget.items)
                    BeuiPopIn(
                      spec: BeuiSpringSpec.layout,
                      child: _ActivityRow(item: item),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final BeuiAgentActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: switch (item.kind) {
        BeuiAgentActivityKind.step => Text(
            item.label ?? '',
            style: TextStyle(
              fontSize: 13,
              color: item.status == BeuiAgentStepStatus.active
                  ? colors.foreground
                  : colors.mutedForeground,
            ),
          ),
        BeuiAgentActivityKind.text => Text(
            item.content ?? '',
            style: TextStyle(fontSize: 13, color: colors.foreground),
          ),
        BeuiAgentActivityKind.search => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search · ${item.query}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.foreground,
                ),
              ),
              for (final result in item.results)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    '${result.title}${result.domain != null ? ' · ${result.domain}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
            ],
          ),
        BeuiAgentActivityKind.tool => Text(
            '${item.action} ${item.target}'
            '${item.additions != null ? '  +${item.additions}' : ''}'
            '${item.deletions != null ? '  -${item.deletions}' : ''}',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: colors.foreground,
            ),
          ),
        BeuiAgentActivityKind.trace => Text(
            item.label ?? item.content ?? '',
            style: TextStyle(fontSize: 13, color: colors.mutedForeground),
          ),
      },
    );
  }
}
