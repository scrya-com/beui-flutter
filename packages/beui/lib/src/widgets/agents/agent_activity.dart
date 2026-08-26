import 'package:flutter/widgets.dart';

import '../../motion/pop_in.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import 'disclosure.dart';
import 'thinking_shimmer.dart';

enum BeuiAgentActivityStatus { working, complete }

enum BeuiAgentStepStatus { pending, active, complete }

enum BeuiAgentActivityKind { step, text, search, tool, trace }

enum BeuiAgentActivityContentType { step, text, search, tool, trace, mixed }

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
    this.meta,
  })  : kind = BeuiAgentActivityKind.step,
        content = null,
        query = null,
        results = const [],
        moreCount = null,
        action = null,
        target = null,
        additions = null,
        deletions = null,
        traceKind = null,
        detail = null;

  const BeuiAgentActivityItem.text({
    required this.id,
    required this.content,
  })  : kind = BeuiAgentActivityKind.text,
        label = null,
        status = null,
        meta = null,
        query = null,
        results = const [],
        moreCount = null,
        action = null,
        target = null,
        additions = null,
        deletions = null,
        traceKind = null,
        detail = null;

  const BeuiAgentActivityItem.search({
    required this.id,
    required this.query,
    this.results = const [],
    this.moreCount,
  })  : kind = BeuiAgentActivityKind.search,
        label = null,
        status = null,
        meta = null,
        content = null,
        action = null,
        target = null,
        additions = null,
        deletions = null,
        traceKind = null,
        detail = null;

  const BeuiAgentActivityItem.tool({
    required this.id,
    required this.action,
    required this.target,
    this.additions,
    this.deletions,
  })  : kind = BeuiAgentActivityKind.tool,
        label = null,
        status = null,
        meta = null,
        content = null,
        query = null,
        results = const [],
        moreCount = null,
        traceKind = null,
        detail = null;

  const BeuiAgentActivityItem.trace({
    required this.id,
    required this.traceKind,
    required this.label,
    this.detail,
  })  : kind = BeuiAgentActivityKind.trace,
        status = null,
        meta = null,
        content = null,
        query = null,
        results = const [],
        moreCount = null,
        action = null,
        target = null,
        additions = null,
        deletions = null;

  final String id;
  final BeuiAgentActivityKind kind;
  final String? label;
  final BeuiAgentStepStatus? status;
  final String? meta;
  final String? content;
  final String? query;
  final List<BeuiAgentSearchResult> results;
  final int? moreCount;
  final String? action;
  final String? target;
  final int? additions;
  final int? deletions;
  final String? traceKind;
  final String? detail;
}

String _formatDuration(double duration) {
  final seconds = duration.round().clamp(0, 1 << 30);
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return remainder == 0 ? '${minutes}m' : '${minutes}m ${remainder}s';
}

BeuiAgentActivityContentType _contentType(List<BeuiAgentActivityItem> items) {
  if (items.isEmpty) return BeuiAgentActivityContentType.mixed;
  final first = items.first.kind;
  return items.every((i) => i.kind == first)
      ? BeuiAgentActivityContentType.values[first.index]
      : BeuiAgentActivityContentType.mixed;
}

String _activeLabel(BeuiAgentActivityContentType type) {
  return switch (type) {
    BeuiAgentActivityContentType.search => 'Searching the web…',
    BeuiAgentActivityContentType.tool => 'Running tools…',
    BeuiAgentActivityContentType.trace => 'Working through the run…',
    BeuiAgentActivityContentType.mixed => 'Working through it…',
    BeuiAgentActivityContentType.step ||
    BeuiAgentActivityContentType.text =>
      'Thinking…',
  };
}

String _summary(
  BeuiAgentActivityContentType type,
  List<BeuiAgentActivityItem> items,
  double duration,
) {
  switch (type) {
    case BeuiAgentActivityContentType.step:
    case BeuiAgentActivityContentType.text:
      return 'Thought for ${_formatDuration(duration)}';
    case BeuiAgentActivityContentType.search:
      return 'Searched the web';
    case BeuiAgentActivityContentType.tool:
      return 'Ran ${items.length} ${items.length == 1 ? 'tool' : 'tools'}';
    case BeuiAgentActivityContentType.trace:
      final messages = items
          .where(
            (i) =>
                i.kind == BeuiAgentActivityKind.trace &&
                (i.traceKind == 'thinking' || i.traceKind == 'message'),
          )
          .length;
      final tools = items.length - messages;
      return '$tools ${tools == 1 ? 'tool call' : 'tool calls'}, $messages ${messages == 1 ? 'message' : 'messages'}';
    case BeuiAgentActivityContentType.mixed:
      return 'Completed ${items.length} ${items.length == 1 ? 'step' : 'steps'}';
  }
}

/// Adaptive activity disclosure. Port of `AgentActivity`.
class BeuiAgentActivity extends StatefulWidget {
  const BeuiAgentActivity({
    super.key,
    required this.items,
    this.contentType,
    this.status = BeuiAgentActivityStatus.working,
    this.duration = 0,
    this.open,
    this.initialOpen = false,
    this.onOpenChanged,
    this.collapseOnComplete = true,
    this.activeLabel,
    this.summary,
    this.maxHeight = 208,
  });

  final List<BeuiAgentActivityItem> items;
  final BeuiAgentActivityContentType? contentType;
  final BeuiAgentActivityStatus status;
  final double duration;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;
  final bool collapseOnComplete;
  final String? activeLabel;
  final String? summary;
  final double maxHeight;

  @override
  State<BeuiAgentActivity> createState() => _BeuiAgentActivityState();
}

class _BeuiAgentActivityState extends State<BeuiAgentActivity> {
  late bool _internal;
  BeuiAgentActivityStatus? _prev;
  final _contentKey = GlobalKey();
  double _contentHeight = 0;

  bool get _controlled => widget.open != null;
  bool get _working => widget.status == BeuiAgentActivityStatus.working;
  bool get _expanded => _working || (_controlled ? widget.open! : _internal);

  @override
  void initState() {
    super.initState();
    _internal = widget.initialOpen;
    _prev = widget.status;
  }

  @override
  void didUpdateWidget(BeuiAgentActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_prev == BeuiAgentActivityStatus.working &&
        widget.status == BeuiAgentActivityStatus.complete) {
      _setOpen(!widget.collapseOnComplete);
    }
    _prev = widget.status;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _setOpen(bool next) {
    if (!_controlled) setState(() => _internal = next);
    widget.onOpenChanged?.call(next);
  }

  void _measure() {
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    if ((box.size.height - _contentHeight).abs() < 0.5) return;
    setState(() => _contentHeight = box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final type = widget.items.isEmpty
        ? (widget.contentType ?? BeuiAgentActivityContentType.mixed)
        : _contentType(widget.items);
    final liveLabel = widget.activeLabel ?? _activeLabel(type);
    final completed = widget.summary ?? _summary(type, widget.items, widget.duration);
    final cappedHeight = _contentHeight.clamp(0, widget.maxHeight).toDouble();
    final viewportHeight = _working ? widget.maxHeight : cappedHeight;
    final capped = _contentHeight > widget.maxHeight;
    final streamOffset = _working
        ? (viewportHeight - _contentHeight).clamp(-100000.0, 0.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_working)
          SizedBox(
            height: 28,
            child: Align(
              alignment: Alignment.centerLeft,
              child: BeuiThinkingShimmer(text: liveLabel),
            ),
          )
        else
          GestureDetector(
            onTap: () => _setOpen(!_expanded),
            child: SizedBox(
              height: 28,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      completed,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                  BeuiSpringBuilder(
                    value: _expanded ? 1 : 0,
                    spec: BeuiSpringSpec.swap,
                    builder: (context, t) {
                      return Transform.rotate(
                        angle: t * 3.14159,
                        child: BeuiIcon(
                          BeuiIcons.chevronDown,
                          size: 14,
                          color: colors.mutedForeground.withValues(alpha: 0.7),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        BeuiAgentDisclosure(
          open: _expanded,
          child: SizedBox(
            height: viewportHeight,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) {
                if (!capped) {
                  return const LinearGradient(
                    colors: [Color(0xFF000000), Color(0xFF000000)],
                  ).createShader(rect);
                }
                if (_working) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xFF000000)],
                    stops: [0, 12 / 208],
                  ).createShader(rect);
                }
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0xFF000000),
                    Color(0xFF000000),
                    Color(0x00000000),
                  ],
                  stops: [0, 0.08, 0.92, 1],
                ).createShader(rect);
              },
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: double.infinity,
                  child: BeuiSpringBuilder(
                    value: streamOffset,
                    spec: BeuiSpringSpec.layout,
                    builder: (context, y) {
                      return Transform.translate(
                        offset: Offset(0, reduce ? streamOffset : y),
                        child: Padding(
                          key: _contentKey,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            spacing: 2,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final item in widget.items)
                                KeyedSubtree(
                                  key: ValueKey(item.id),
                                  child: BeuiPopIn(
                                    spec: BeuiSpringSpec.layout,
                                    fromScale: 1,
                                    child: _ActivityRow(item: item),
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
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final BeuiAgentActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return switch (item.kind) {
      BeuiAgentActivityKind.step => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _StepMark(status: item.status ?? BeuiAgentStepStatus.complete),
              ),
              Expanded(
                child: Text(
                  item.label ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    color: item.status == BeuiAgentStepStatus.pending
                        ? colors.mutedForeground.withValues(alpha: 0.55)
                        : colors.foreground.withValues(alpha: 0.9),
                  ),
                ),
              ),
              if (item.meta != null)
                Text(
                  item.meta!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.mutedForeground.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
        ),
      BeuiAgentActivityKind.text => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            item.content ?? '',
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: colors.mutedForeground,
            ),
          ),
        ),
      BeuiAgentActivityKind.search => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                spacing: 10,
                children: [
                  BeuiIcon(
                    BeuiIcons.search,
                    size: 16,
                    color: colors.mutedForeground,
                  ),
                  Expanded(
                    child: Text(
                      item.query ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                    ),
                  ),
                ],
              ),
            ),
            for (final result in item.results)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 2, 6, 2),
                child: Row(
                  spacing: 8,
                  children: [
                    BeuiIcon(
                      BeuiIcons.globe,
                      size: 12,
                      color: colors.mutedForeground,
                    ),
                    Flexible(
                      child: Text(
                        result.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.foreground.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    if (result.domain != null)
                      Flexible(
                        child: Text(
                          result.domain!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.mutedForeground.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (item.moreCount != null && item.moreCount! > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 4, 6, 4),
                child: Text(
                  '+${item.moreCount} more',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.mutedForeground.withValues(alpha: 0.55),
                  ),
                ),
              ),
          ],
        ),
      BeuiAgentActivityKind.tool => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            spacing: 10,
            children: [
              BeuiIcon(
                _actionIcon(item.action),
                size: 16,
                color: colors.mutedForeground.withValues(alpha: 0.7),
              ),
              Text(
                _titleCase(item.action ?? ''),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.foreground.withValues(alpha: 0.9),
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.muted.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      item.target ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: colors.mutedForeground.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
              if (item.additions != null || item.deletions != null)
                Row(
                  spacing: 8,
                  children: [
                    if (item.additions != null)
                      Text(
                        '+${item.additions}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Color(0xFF10B981),
                        ),
                      ),
                    if (item.deletions != null)
                      Text(
                        '−${item.deletions}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Color(0xFFF43F5E),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      BeuiAgentActivityKind.trace => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            spacing: 10,
            children: [
              BeuiIcon(
                _traceIcon(item.traceKind),
                size: 16,
                color: colors.mutedForeground.withValues(alpha: 0.7),
              ),
              Text(
                item.label ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.foreground.withValues(alpha: 0.9),
                ),
              ),
              if (item.detail != null)
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.muted.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        item.detail!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: colors.mutedForeground.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
    };
  }
}

class _StepMark extends StatefulWidget {
  const _StepMark({required this.status});
  final BeuiAgentStepStatus status;

  @override
  State<_StepMark> createState() => _StepMarkState();
}

class _StepMarkState extends State<_StepMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_StepMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final live = TickerMode.valuesOf(context).enabled &&
        widget.status == BeuiAgentStepStatus.active &&
        !beuiReduceMotion(context);
    if (live && !_pulse.isAnimating) _pulse.repeat();
    if (!live && _pulse.isAnimating) _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    if (widget.status == BeuiAgentStepStatus.complete) {
      return BeuiIcon(
        BeuiIcons.check,
        size: 16,
        color: colors.mutedForeground.withValues(alpha: 0.7),
      );
    }
    if (widget.status == BeuiAgentStepStatus.pending) {
      return BeuiIcon(
        BeuiIcons.circle,
        size: 12,
        color: colors.mutedForeground.withValues(alpha: 0.7),
      );
    }
    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final o = 0.35 + 0.45 * (1 - (_pulse.value - 0.5).abs() * 2);
              return DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.foreground.withValues(alpha: o),
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.foreground.withValues(alpha: 0.6),
            ),
            child: const SizedBox(width: 6, height: 6),
          ),
        ],
      ),
    );
  }
}

BeuiIconPainter _actionIcon(String? action) {
  return switch (action) {
    'read' => BeuiIcons.fileText,
    'edit' || 'write' => BeuiIcons.pencil,
    'run' => BeuiIcons.terminal,
    _ => BeuiIcons.wrench,
  };
}

BeuiIconPainter _traceIcon(String? kind) {
  return switch (kind) {
    'thinking' => BeuiIcons.sparkles,
    'message' => BeuiIcons.messageSquare,
    'write' => BeuiIcons.pencil,
    'run' => BeuiIcons.terminal,
    'read' => BeuiIcons.fileText,
    _ => BeuiIcons.wrench,
  };
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
