import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../motion/text_shimmer.dart';

enum BeuiReasoningVariant { cascade, swap, scramble }

/// Cycling phrases with cascade / swap / scramble. Port of `ReasoningText`.
class BeuiReasoningText extends StatefulWidget {
  const BeuiReasoningText({
    super.key,
    this.phrases = const [
      'Thinking',
      'Reading the context',
      'Connecting the details',
      'Forming a response',
    ],
    this.variant = BeuiReasoningVariant.cascade,
    this.interval = const Duration(milliseconds: 2200),
    this.shimmerDuration = const Duration(milliseconds: 1800),
  });

  final List<String> phrases;
  final BeuiReasoningVariant variant;
  final Duration interval;
  final Duration shimmerDuration;

  @override
  State<BeuiReasoningText> createState() => _BeuiReasoningTextState();
}

class _BeuiReasoningTextState extends State<BeuiReasoningText> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) {
      _timer?.cancel();
      _timer = null;
    } else if (_timer == null) {
      _arm();
    }
  }

  @override
  void didUpdateWidget(BeuiReasoningText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval ||
        oldWidget.phrases.length != widget.phrases.length) {
      _arm();
    }
  }

  void _arm() {
    _timer?.cancel();
    if (widget.phrases.length < 2) return;
    if (!mounted || !TickerMode.valuesOf(context).enabled) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.phrases.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrase = widget.phrases.isEmpty
        ? 'Thinking'
        : widget.phrases[_index % widget.phrases.length];
    final text = '$phrase…';
    final reduce = beuiReduceMotion(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        Text(
          '>',
          style: TextStyle(
            fontFamily: 'monospace',
            color: context.beuiColors.mutedForeground,
          ),
        ),
        Flexible(
          child: reduce
              ? BeuiTextShimmer(text: text, duration: widget.shimmerDuration)
              : switch (widget.variant) {
                  BeuiReasoningVariant.cascade => _Cascade(
                      text: text,
                      key: ValueKey(text),
                      shimmer: widget.shimmerDuration,
                    ),
                  BeuiReasoningVariant.swap => _Swap(
                      text: text,
                      key: ValueKey(text),
                      shimmer: widget.shimmerDuration,
                    ),
                  BeuiReasoningVariant.scramble => _Scramble(
                      text: text,
                      key: ValueKey(text),
                      shimmer: widget.shimmerDuration,
                    ),
                },
        ),
      ],
    );
  }
}

class _Cascade extends StatelessWidget {
  const _Cascade({super.key, required this.text, required this.shimmer});
  final String text;
  final Duration shimmer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < text.length; i++)
          _Letter(
            char: text[i],
            delay: Duration(milliseconds: (i * 25)),
            shimmer: shimmer,
          ),
      ],
    );
  }
}

class _Letter extends StatefulWidget {
  const _Letter({
    required this.char,
    required this.delay,
    required this.shimmer,
  });
  final String char;
  final Duration delay;
  final Duration shimmer;

  @override
  State<_Letter> createState() => _LetterState();
}

class _LetterState extends State<_Letter> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: BeuiCurves.easeOut),
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.4), end: Offset.zero)
            .animate(CurvedAnimation(parent: _c, curve: BeuiCurves.easeOut)),
        child: BeuiTextShimmer(
          text: widget.char == ' ' ? '\u00A0' : widget.char,
          duration: widget.shimmer,
        ),
      ),
    );
  }
}

class _Swap extends StatelessWidget {
  const _Swap({super.key, required this.text, required this.shimmer});
  final String text;
  final Duration shimmer;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: BeuiCurves.easeOut,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - t)),
            child: child,
          ),
        );
      },
      child: BeuiTextShimmer(text: text, duration: shimmer),
    );
  }
}

class _Scramble extends StatefulWidget {
  const _Scramble({super.key, required this.text, required this.shimmer});
  final String text;
  final Duration shimmer;

  @override
  State<_Scramble> createState() => _ScrambleState();
}

class _ScrambleState extends State<_Scramble> {
  late String _shown;
  Timer? _timer;
  int _step = 0;
  static const _glyphs = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
  final _rng = math.Random(4);

  @override
  void initState() {
    super.initState();
    _shown = widget.text;
    _timer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (!mounted) return;
      _step++;
      if (_step > widget.text.length + 4) {
        _timer?.cancel();
        setState(() => _shown = widget.text);
        return;
      }
      final buf = StringBuffer();
      for (var i = 0; i < widget.text.length; i++) {
        if (i < _step - 2 || widget.text[i] == ' ' || widget.text[i] == '…') {
          buf.write(widget.text[i]);
        } else {
          buf.write(_glyphs[_rng.nextInt(_glyphs.length)]);
        }
      }
      setState(() => _shown = buf.toString());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: BeuiTextShimmer(text: _shown, duration: widget.shimmer),
    );
  }
}
