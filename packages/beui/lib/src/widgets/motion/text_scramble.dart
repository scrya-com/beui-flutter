import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';

const _kDefaultGlyphs = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789#%&@\$?/';

/// Character scramble that resolves to [text] and respects reduced motion.
/// Port of `components/motion/text-scramble.tsx`.
class BeuiTextScramble extends StatefulWidget {
  const BeuiTextScramble({
    super.key,
    required this.text,
    this.duration,
    this.glyphs = _kDefaultGlyphs,
    this.style,
  });

  /// Final text revealed by the scramble.
  final String text;

  /// Maximum animation duration. Defaults to `min(760, max(420, length * 32))` ms.
  final Duration? duration;

  /// Characters sampled while unresolved positions are scrambling.
  final String glyphs;
  final TextStyle? style;

  @override
  State<BeuiTextScramble> createState() => _BeuiTextScrambleState();
}

class _BeuiTextScrambleState extends State<BeuiTextScramble>
    with SingleTickerProviderStateMixin {
  late String _display;
  late final AnimationController _clock;
  Duration _lastUpdate = Duration.zero;
  final _rng = math.Random();

  int get _durationMs {
    final n = widget.text.length;
    return widget.duration?.inMilliseconds ??
        math.min(760, math.max(420, n * 32));
  }

  @override
  void initState() {
    super.initState();
    _display = widget.text;
    _clock = AnimationController(vsync: this)
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(BeuiTextScramble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text &&
        oldWidget.duration == widget.duration &&
        oldWidget.glyphs == widget.glyphs) {
      return;
    }
    _startScramble();
  }

  void _startScramble() {
    final reduce = beuiReduceMotion(context);
    if (reduce || widget.glyphs.isEmpty) {
      _clock.stop();
      setState(() => _display = widget.text);
      return;
    }
    _lastUpdate = Duration.zero;
    _clock
      ..duration = Duration(milliseconds: _durationMs)
      ..forward(from: 0);
  }

  void _onTick() {
    if (!_clock.isAnimating) return;
    final now = _clock.lastElapsedDuration ?? Duration.zero;
    if (now - _lastUpdate < const Duration(milliseconds: 40)) return;
    _lastUpdate = now;
    final progress = (now.inMilliseconds / _durationMs).clamp(0.0, 1.0);
    final settled = (progress * widget.text.length).floor();
    final buf = StringBuffer();
    for (var i = 0; i < widget.text.length; i++) {
      final ch = widget.text[i];
      if (i < settled || ch == ' ') {
        buf.write(ch);
      } else {
        buf.write(widget.glyphs[_rng.nextInt(widget.glyphs.length)]);
      }
    }
    setState(() => _display = buf.toString());
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _display = widget.text);
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    final reduce = beuiReduceMotion(context);
    final shown = reduce ? widget.text : _display;
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: Text(
          shown,
          style: style,
          softWrap: false,
        ),
      ),
    );
  }
}
