import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

enum BeuiCodeBlockStatus { streaming, complete }

/// Syntax-styled agent code surface. Port of `CodeBlock`.
///
/// Highlighting is line-stable without Shiki: rows keep identity by offset,
/// streamed growth follows in a capped viewport, copy swaps to a check.
class BeuiCodeBlock extends StatefulWidget {
  const BeuiCodeBlock({
    super.key,
    required this.code,
    this.language = 'typescript',
    this.filename,
    this.status = BeuiCodeBlockStatus.complete,
    this.showLineNumbers = true,
    this.highlightLines = const [],
    this.maxHeight = 280,
    this.wrap = false,
    this.copyable = true,
    this.onCopy,
  });

  final String code;
  final String language;
  final String? filename;
  final BeuiCodeBlockStatus status;
  final bool showLineNumbers;
  final List<int> highlightLines;
  final double maxHeight;
  final bool wrap;
  final bool copyable;
  final VoidCallback? onCopy;

  @override
  State<BeuiCodeBlock> createState() => _BeuiCodeBlockState();
}

class _BeuiCodeBlockState extends State<BeuiCodeBlock>
    with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  late final AnimationController _copied;
  bool _showCopied = false;

  bool get _streaming => widget.status == BeuiCodeBlockStatus.streaming;

  @override
  void initState() {
    super.initState();
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
  void didUpdateWidget(BeuiCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_streaming && oldWidget.code != widget.code) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    }
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
    widget.onCopy?.call();
    await Clipboard.setData(ClipboardData(text: widget.code));
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
    final lines = widget.code.split('\n');
    final highlighted = widget.highlightLines.toSet();

    return Semantics(
      liveRegion: _streaming,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.muted.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(BeuiRadii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    BeuiIcon(
                      BeuiIcons.fileCode,
                      size: 14,
                      color: colors.mutedForeground.withValues(alpha: 0.7),
                    ),
                    if (widget.filename != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.filename!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: colors.foreground.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      widget.language.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                        color: colors.mutedForeground.withValues(alpha: 0.55),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        BeuiIcon(
                          _streaming ? BeuiIcons.loader : BeuiIcons.check,
                          size: 12,
                          color: _streaming
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF34D399),
                        ),
                        Text(
                          _streaming ? 'Writing' : 'Ready',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _streaming
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF34D399),
                          ),
                        ),
                      ],
                    ),
                    if (widget.copyable || widget.onCopy != null)
                      GestureDetector(
                        onTap: _copy,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: BeuiIcon(
                            _showCopied ? BeuiIcons.check : BeuiIcons.copy,
                            size: 14,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.foreground.withValues(alpha: 0.06)),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxHeight),
                child: SingleChildScrollView(
                  controller: _controller,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 12,
                      height: 20 / 12,
                      fontFamily: 'monospace',
                      color: colors.foreground.withValues(alpha: 0.85),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < lines.length; i++)
                          ColoredBox(
                            color: highlighted.contains(i + 1)
                                ? const Color(0x123B82F6)
                                : const Color(0x00000000),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.showLineNumbers)
                                    SizedBox(
                                      width: 44,
                                      child: Text(
                                        '${i + 1}',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: colors.mutedForeground
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: widget.showLineNumbers ? 8 : 16,
                                        right: 16,
                                      ),
                                      child: Text(
                                        lines[i].isEmpty ? ' ' : lines[i],
                                        softWrap: widget.wrap,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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
