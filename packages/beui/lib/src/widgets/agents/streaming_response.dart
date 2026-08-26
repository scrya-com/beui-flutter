import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import 'citations.dart';

enum BeuiStreamingStatus { streaming, complete, error }

enum BeuiStreamingFeedback { up, down }

/// Streamed answer surface. Port of `StreamingResponse`.
class BeuiStreamingResponse extends StatefulWidget {
  const BeuiStreamingResponse({
    super.key,
    required this.child,
    this.status = BeuiStreamingStatus.streaming,
    this.copyText,
    this.onRetry,
    this.sources = const [],
    this.feedback,
    this.initialFeedback,
    this.onFeedbackChanged,
    this.showActions = true,
  });

  final Widget child;
  final BeuiStreamingStatus status;
  final String? copyText;
  final VoidCallback? onRetry;
  final List<BeuiCitationItem> sources;
  final BeuiStreamingFeedback? feedback;
  final BeuiStreamingFeedback? initialFeedback;
  final ValueChanged<BeuiStreamingFeedback?>? onFeedbackChanged;
  final bool showActions;

  @override
  State<BeuiStreamingResponse> createState() => _BeuiStreamingResponseState();
}

class _BeuiStreamingResponseState extends State<BeuiStreamingResponse> {
  BeuiStreamingFeedback? _internalFeedback;
  bool _copied = false;
  bool _sourcesOpen = false;

  bool get _feedbackControlled => widget.feedback != null;
  BeuiStreamingFeedback? get _feedback =>
      _feedbackControlled ? widget.feedback : _internalFeedback;

  @override
  void initState() {
    super.initState();
    _internalFeedback = widget.initialFeedback;
  }

  Future<void> _copy() async {
    final text = widget.copyText;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _copied = false);
  }

  void _setFeedback(BeuiStreamingFeedback value) {
    final next = _feedback == value ? null : value;
    if (!_feedbackControlled) setState(() => _internalFeedback = next);
    widget.onFeedbackChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final complete = widget.status == BeuiStreamingStatus.complete;
    final reduce = beuiReduceMotion(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: colors.foreground,
          ),
          child: widget.child,
        ),
        if (widget.showActions)
          ClipRect(
            child: AnimatedSize(
              duration: Duration(milliseconds: reduce ? 0 : 220),
              curve: BeuiCurves.easeOut,
              alignment: Alignment.topLeft,
              child: complete
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        spacing: 4,
                        children: [
                          _Action(
                            label: _copied ? 'Copied' : 'Copy',
                            onPressed: _copy,
                            child: BeuiIcon(
                              _copied ? BeuiIcons.check : BeuiIcons.copy,
                              size: 16,
                              color: colors.mutedForeground,
                            ),
                          ),
                          if (widget.onRetry != null)
                            _Action(
                              label: 'Retry',
                              onPressed: widget.onRetry!,
                              child: BeuiIcon(
                                BeuiIcons.rotateCcw,
                                size: 16,
                                color: colors.mutedForeground,
                              ),
                            ),
                          _Action(
                            label: 'Helpful',
                            active: _feedback == BeuiStreamingFeedback.up,
                            onPressed: () =>
                                _setFeedback(BeuiStreamingFeedback.up),
                            child: BeuiIcon(
                              BeuiIcons.thumbsUp,
                              size: 16,
                              color: _feedback == BeuiStreamingFeedback.up
                                  ? colors.foreground
                                  : colors.mutedForeground,
                            ),
                          ),
                          _Action(
                            label: 'Not helpful',
                            active: _feedback == BeuiStreamingFeedback.down,
                            onPressed: () =>
                                _setFeedback(BeuiStreamingFeedback.down),
                            child: BeuiIcon(
                              BeuiIcons.thumbsDown,
                              size: 16,
                              color: _feedback == BeuiStreamingFeedback.down
                                  ? colors.foreground
                                  : colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ),
        if (widget.sources.isNotEmpty && complete)
          BeuiCitations(
            citations: widget.sources,
            open: _sourcesOpen,
            onOpenChanged: (v) => setState(() => _sourcesOpen = v),
          ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.onPressed,
    required this.child,
    this.active = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}
