import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import 'disclosure.dart';

enum BeuiToolResultStatus { running, success, error, cancelled }

enum BeuiToolResultKind { terminal, request, custom }

/// Lightweight execution disclosure. Port of `ToolResult`.
class BeuiToolResult extends StatefulWidget {
  const BeuiToolResult({
    super.key,
    required this.tool,
    required this.title,
    required this.output,
    this.status = BeuiToolResultStatus.running,
    this.kind = BeuiToolResultKind.terminal,
    this.meta,
    this.open,
    this.initialOpen = true,
    this.onOpenChanged,
    this.collapseOnComplete = true,
    this.maxHeight = 150,
    this.onRetry,
  });

  final String tool;
  final String title;
  final String output;
  final BeuiToolResultStatus status;
  final BeuiToolResultKind kind;
  final String? meta;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;
  final bool collapseOnComplete;
  final double maxHeight;
  final VoidCallback? onRetry;

  @override
  State<BeuiToolResult> createState() => _BeuiToolResultState();
}

class _BeuiToolResultState extends State<BeuiToolResult> {
  late bool _internal;
  BeuiToolResultStatus? _prev;

  bool get _controlled => widget.open != null;
  bool get _open => _controlled ? widget.open! : _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialOpen;
    _prev = widget.status;
  }

  @override
  void didUpdateWidget(BeuiToolResult oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasComplete = _prev == BeuiToolResultStatus.success ||
        _prev == BeuiToolResultStatus.error ||
        _prev == BeuiToolResultStatus.cancelled;
    final nowRunning = widget.status == BeuiToolResultStatus.running;
    if (wasComplete && nowRunning) _setOpen(true);
    if (_prev == BeuiToolResultStatus.running &&
        widget.status != BeuiToolResultStatus.running &&
        widget.collapseOnComplete) {
      _setOpen(false);
    }
    _prev = widget.status;
  }

  void _setOpen(bool next) {
    if (_open == next) return;
    if (!_controlled) setState(() => _internal = next);
    widget.onOpenChanged?.call(next);
  }

  Future<void> _copy() async {
    if (widget.output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: widget.output));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final statusColor = switch (widget.status) {
      BeuiToolResultStatus.running => const Color(0xFF60A5FA),
      BeuiToolResultStatus.success => const Color(0xFF34D399),
      BeuiToolResultStatus.error => colors.destructive,
      BeuiToolResultStatus.cancelled => colors.mutedForeground,
    };
    final statusLabel = switch (widget.status) {
      BeuiToolResultStatus.running => 'Running',
      BeuiToolResultStatus.success => 'Completed',
      BeuiToolResultStatus.error => 'Failed',
      BeuiToolResultStatus.cancelled => 'Cancelled',
    };

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
            onTap: () => _setOpen(!_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                spacing: 10,
                children: [
                  BeuiIcon(
                    BeuiIcons.terminal,
                    size: 16,
                    color: statusColor,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                        Text(
                          '${widget.tool} · $statusLabel${widget.meta != null ? ' · ${widget.meta}' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _copy,
                    child: BeuiIcon(
                      BeuiIcons.copy,
                      size: 14,
                      color: colors.mutedForeground,
                    ),
                  ),
                  if (widget.onRetry != null &&
                      widget.status != BeuiToolResultStatus.running)
                    GestureDetector(
                      onTap: widget.onRetry,
                      child: BeuiIcon(
                        BeuiIcons.rotateCcw,
                        size: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(
                  widget.output,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.5,
                    color: colors.foreground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
