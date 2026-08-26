import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/colors.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import 'disclosure.dart';

enum BeuiToolApprovalStatus {
  pending,
  approving,
  approved,
  denied,
  running,
  complete,
  error,
}

class BeuiToolApprovalParameter {
  const BeuiToolApprovalParameter({
    required this.id,
    required this.label,
    required this.value,
  });

  final String id;
  final String label;
  final Widget value;
}

class BeuiToolApprovalCode extends StatelessWidget {
  const BeuiToolApprovalCode({
    super.key,
    required this.code,
    this.language = 'bash',
  });

  final String code;
  final String language;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          code,
          style: TextStyle(
            color: colors.foreground.withValues(alpha: 0.85),
            fontFamily: 'Menlo',
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

String beuiToolApprovalStatusCopy(BeuiToolApprovalStatus status) {
  return switch (status) {
    BeuiToolApprovalStatus.approving => 'Approving',
    BeuiToolApprovalStatus.approved => 'Approved',
    BeuiToolApprovalStatus.denied => 'Denied',
    BeuiToolApprovalStatus.running => 'Running',
    BeuiToolApprovalStatus.complete => 'Completed',
    BeuiToolApprovalStatus.error => 'Failed',
    BeuiToolApprovalStatus.pending => 'Approval required',
  };
}

(Color border, Color fill, Color text) _badgeColors(
  BeuiColors colors,
  BeuiToolApprovalStatus status,
) {
  switch (status) {
    case BeuiToolApprovalStatus.pending:
      return (
        colors.warning.withValues(alpha: 0.3),
        colors.warning.withValues(alpha: 0.1),
        colors.warning,
      );
    case BeuiToolApprovalStatus.approving:
    case BeuiToolApprovalStatus.running:
      return (
        const Color(0x4D3B82F6),
        const Color(0x1A3B82F6),
        const Color(0xFF60A5FA),
      );
    case BeuiToolApprovalStatus.approved:
    case BeuiToolApprovalStatus.complete:
      return (
        colors.success.withValues(alpha: 0.3),
        colors.success.withValues(alpha: 0.1),
        colors.success,
      );
    case BeuiToolApprovalStatus.denied:
    case BeuiToolApprovalStatus.error:
      return (
        colors.destructive.withValues(alpha: 0.3),
        colors.destructive.withValues(alpha: 0.1),
        colors.destructive,
      );
  }
}

/// Human-in-the-loop permission card. Port of `components/agents/tool-approval.tsx`.
class BeuiToolApproval extends StatefulWidget {
  const BeuiToolApproval({
    super.key,
    required this.tool,
    this.title,
    this.description,
    this.parameters = const [],
    this.status = BeuiToolApprovalStatus.pending,
    this.open,
    this.initialOpen = false,
    this.onOpenChanged,
    this.onApprove,
    this.onAlwaysAllow,
    this.onDeny,
  });

  final String tool;
  final String? title;
  final String? description;
  final List<BeuiToolApprovalParameter> parameters;
  final BeuiToolApprovalStatus status;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;
  final VoidCallback? onApprove;
  final VoidCallback? onAlwaysAllow;
  final VoidCallback? onDeny;

  @override
  State<BeuiToolApproval> createState() => _BeuiToolApprovalState();
}

class _BeuiToolApprovalState extends State<BeuiToolApproval>
    with SingleTickerProviderStateMixin {
  late bool _internalOpen;
  late BeuiToolApprovalStatus _prev;
  late final AnimationController _spin;

  bool get _controlled => widget.open != null;
  bool get _open => _controlled ? widget.open! : _internalOpen;
  bool get _busy =>
      widget.status == BeuiToolApprovalStatus.approving ||
      widget.status == BeuiToolApprovalStatus.running;
  bool get _pending => widget.status == BeuiToolApprovalStatus.pending;
  bool get _error => widget.status == BeuiToolApprovalStatus.error;

  @override
  void initState() {
    super.initState();
    _internalOpen = widget.initialOpen;
    _prev = widget.status;
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (_busy) _spin.repeat();
  }

  @override
  void didUpdateWidget(BeuiToolApproval oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_prev == BeuiToolApprovalStatus.pending &&
        widget.status != BeuiToolApprovalStatus.pending) {
      _setOpen(false);
    }
    _prev = widget.status;
    if (_busy) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _setOpen(bool next) {
    if (_open == next) return;
    if (!_controlled) setState(() => _internalOpen = next);
    widget.onOpenChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final title = widget.title ??
        (widget.status == BeuiToolApprovalStatus.pending
            ? 'Allow this tool to run?'
            : 'Terminal access');
    final badge = _badgeColors(colors, widget.status);
    final painter = _busy
        ? BeuiIcons.loader
        : _error
            ? BeuiIcons.alertCircle
            : widget.status == BeuiToolApprovalStatus.denied
                ? BeuiIcons.x
                : widget.status == BeuiToolApprovalStatus.approved ||
                        widget.status == BeuiToolApprovalStatus.complete
                    ? BeuiIcons.check
                    : BeuiIcons.shieldCheck;

    Widget icon = BeuiIcon(
      painter,
      size: 16,
      color: _error ? colors.destructive : colors.mutedForeground,
    );
    if (_busy && !reduce) {
      icon = RotationTransition(turns: _spin, child: icon);
    }

    return Semantics(
      container: true,
      liveRegion: _busy,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.muted.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: icon,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 12,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: colors.foreground,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.tool,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.mutedForeground,
                                      fontFamily: 'Menlo',
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: badge.$2,
                                borderRadius:
                                    BorderRadius.circular(BeuiRadii.pill),
                                border: Border.all(color: badge.$1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  beuiToolApprovalStatusCopy(widget.status),
                                  style: TextStyle(
                                    color: badge.$3,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.description!,
                            style: TextStyle(
                              color: colors.mutedForeground,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (widget.parameters.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _setOpen(!_open),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                Text(
                                  'View details',
                                  style: TextStyle(
                                    color: colors.mutedForeground,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: _open ? 0.5 : 0,
                                  duration: Duration(
                                    milliseconds: reduce ? 0 : 180,
                                  ),
                                  curve: BeuiCurves.easeOut,
                                  child: BeuiIcon(
                                    BeuiIcons.chevronDown,
                                    size: 14,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.parameters.isNotEmpty)
              BeuiAgentDisclosure(
                open: _open,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.background.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        spacing: 8,
                        children: [
                          for (final parameter in widget.parameters)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 12,
                              children: [
                                SizedBox(
                                  width: 112,
                                  child: Text(
                                    parameter.label,
                                    style: TextStyle(
                                      color: colors.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: DefaultTextStyle(
                                    style: TextStyle(
                                      color: colors.foreground
                                          .withValues(alpha: 0.85),
                                      fontFamily: 'Menlo',
                                      fontSize: 12,
                                    ),
                                    child: parameter.value,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_pending)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colors.border.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Action(
                        label: 'Allow once',
                        filled: true,
                        onPressed: widget.onApprove,
                      ),
                      if (widget.onAlwaysAllow != null)
                        _Action(
                          label: 'Always allow',
                          filled: false,
                          onPressed: widget.onAlwaysAllow,
                        ),
                      _Action(
                        label: 'Deny',
                        filled: false,
                        muted: true,
                        onPressed: widget.onDeny,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatefulWidget {
  const _Action({
    required this.label,
    required this.filled,
    this.muted = false,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final bool muted;
  final VoidCallback? onPressed;

  @override
  State<_Action> createState() => _ActionState();
}

class _ActionState extends State<_Action> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final bg = widget.filled
        ? colors.foreground
        : widget.muted
            ? const Color(0x00000000)
            : colors.background;
    final fg = widget.filled
        ? colors.background
        : widget.muted
            ? colors.mutedForeground
            : colors.foreground;
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Transform.scale(
        scale: !reduce && _pressed ? 0.97 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: widget.filled || widget.muted
                ? null
                : Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              widget.label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
