import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import 'disclosure.dart';

enum BeuiFileDiffStatus { streaming, complete }

enum BeuiFileDiffLineType { added, removed, context }

class BeuiFileDiffLine {
  const BeuiFileDiffLine({
    required this.id,
    required this.content,
    this.type = BeuiFileDiffLineType.context,
    this.oldLine,
    this.newLine,
  });

  final String id;
  final String content;
  final BeuiFileDiffLineType type;
  final int? oldLine;
  final int? newLine;
}

/// Progressive file-change disclosure. Port of `FileDiff`.
class BeuiFileDiff extends StatefulWidget {
  const BeuiFileDiff({
    super.key,
    required this.file,
    required this.lines,
    this.status = BeuiFileDiffStatus.streaming,
    this.open,
    this.initialOpen = true,
    this.onOpenChanged,
    this.collapseOnComplete = true,
    this.maxHeight = 220,
    this.copyText,
  });

  final String file;
  final List<BeuiFileDiffLine> lines;
  final BeuiFileDiffStatus status;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;
  final bool collapseOnComplete;
  final double maxHeight;
  final String? copyText;

  @override
  State<BeuiFileDiff> createState() => _BeuiFileDiffState();
}

class _BeuiFileDiffState extends State<BeuiFileDiff>
    with SingleTickerProviderStateMixin {
  late bool _internal;
  BeuiFileDiffStatus? _prev;
  final _controller = ScrollController();
  late final AnimationController _copied;
  bool _showCopied = false;

  bool get _controlled => widget.open != null;
  bool get _open => _controlled ? widget.open! : _internal;
  bool get _streaming => widget.status == BeuiFileDiffStatus.streaming;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialOpen;
    _prev = widget.status;
    _copied = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _showCopied = false);
        }
      });
  }

  @override
  void didUpdateWidget(BeuiFileDiff oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_prev != BeuiFileDiffStatus.streaming &&
        widget.status == BeuiFileDiffStatus.streaming) {
      _setOpen(true);
    }
    if (_prev == BeuiFileDiffStatus.streaming &&
        widget.status == BeuiFileDiffStatus.complete &&
        widget.collapseOnComplete) {
      _setOpen(false);
    }
    _prev = widget.status;
    if (_streaming && _open && oldWidget.lines.length != widget.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    }
  }

  void _setOpen(bool next) {
    if (_open == next) return;
    if (!_controlled) setState(() => _internal = next);
    widget.onOpenChanged?.call(next);
  }

  void _follow() {
    if (!_controller.hasClients) return;
    final target = _controller.position.maxScrollExtent;
    if (target <= 0) return;
    final reduce = beuiReduceMotion(context);
    if (reduce) {
      _controller.jumpTo(target);
    } else {
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: BeuiCurves.easeOut,
      );
    }
  }

  Future<void> _copy() async {
    final text = widget.copyText ??
        widget.lines.map((l) => l.content).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _showCopied = true);
    _copied.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _copied.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final additions =
        widget.lines.where((l) => l.type == BeuiFileDiffLineType.added).length;
    final deletions =
        widget.lines.where((l) => l.type == BeuiFileDiffLineType.removed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _setOpen(!_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                BeuiIcon(
                  BeuiIcons.fileCode,
                  size: 16,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.file,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: colors.foreground.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (additions > 0)
                  Text(
                    '+$additions',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFF34D399),
                    ),
                  ),
                if (deletions > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '−$deletions',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFFFB7185),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                BeuiIcon(
                  _streaming ? BeuiIcons.loader : BeuiIcons.check,
                  size: 14,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: 4),
                BeuiSpringBuilder(
                  value: _open ? 1 : 0,
                  spec: BeuiSpringSpec.swap,
                  builder: (context, t) {
                    return Transform.rotate(
                      angle: t * 3.14159,
                      child: BeuiIcon(
                        BeuiIcons.chevronDown,
                        size: 14,
                        color: colors.mutedForeground.withValues(alpha: 0.45),
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
          child: Padding(
            padding: const EdgeInsets.only(left: 24, top: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.muted.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxHeight),
                child: SingleChildScrollView(
                  controller: _controller,
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 12,
                      height: 20 / 12,
                      fontFamily: 'monospace',
                      color: colors.foreground,
                    ),
                    child: Column(
                      children: [
                        for (final line in widget.lines)
                          ColoredBox(
                            color: switch (line.type) {
                              BeuiFileDiffLineType.added =>
                                const Color(0x1234D399),
                              BeuiFileDiffLineType.removed =>
                                const Color(0x12FB7185),
                              BeuiFileDiffLineType.context =>
                                const Color(0x00000000),
                            },
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${line.oldLine ?? ''}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: colors.mutedForeground
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${line.newLine ?? ''}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: colors.mutedForeground
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 16,
                                  child: Text(
                                    switch (line.type) {
                                      BeuiFileDiffLineType.added => '+',
                                      BeuiFileDiffLineType.removed => '−',
                                      BeuiFileDiffLineType.context => '',
                                    },
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: switch (line.type) {
                                        BeuiFileDiffLineType.added =>
                                          const Color(0xFF34D399),
                                        BeuiFileDiffLineType.removed =>
                                          const Color(0xFFFB7185),
                                        BeuiFileDiffLineType.context =>
                                          colors.mutedForeground,
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(child: Text(line.content)),
                                if (widget.copyText != null &&
                                    line.id == widget.lines.last.id)
                                  GestureDetector(
                                    onTap: _copy,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: BeuiIcon(
                                        _showCopied
                                            ? BeuiIcons.check
                                            : BeuiIcons.copy,
                                        size: 12,
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
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
