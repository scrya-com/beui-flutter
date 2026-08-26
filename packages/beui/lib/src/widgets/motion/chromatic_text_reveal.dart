import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

/// Default chromatic trail (`chromatic-text-reveal.tsx`).
const kBeuiChromaticPalette = <Color>[
  Color(0xFF60A5FA),
  Color(0xFF818CF8),
  Color(0xFFC084FC),
  Color(0xFFFB7185),
  Color(0xFFFBBF24),
];

const _kTrail = 0.14;

/// Fixed sentence prefix with a cycling final word revealed by a chromatic sweep.
/// Port of `components/motion/chromatic-text-reveal.tsx`.
class BeuiChromaticTextReveal extends StatefulWidget {
  const BeuiChromaticTextReveal({
    super.key,
    required this.prefix,
    required this.words,
    this.colors = kBeuiChromaticPalette,
    this.foregroundColor,
    this.duration = const Duration(milliseconds: 1200),
    this.delay = Duration.zero,
    this.pauseDuration = const Duration(milliseconds: 800),
    this.loop = true,
    this.startOnView = true,
    this.style,
  });

  /// Sentence fragment that remains fixed while the final word changes.
  final String prefix;

  /// Words revealed one after another after the fixed prefix.
  final List<String> words;

  /// Colors used along the moving chromatic edge.
  final List<Color> colors;

  /// Final text color after the sweep passes. Defaults to theme foreground.
  final Color? foregroundColor;
  final Duration duration;
  final Duration delay;

  /// Rest after a word finishes revealing.
  final Duration pauseDuration;
  final bool loop;

  /// Starts when [TickerMode] is enabled (catalog cards) or immediately.
  final bool startOnView;
  final TextStyle? style;

  @override
  State<BeuiChromaticTextReveal> createState() =>
      _BeuiChromaticTextRevealState();
}

class _BeuiChromaticTextRevealState extends State<BeuiChromaticTextReveal>
    with TickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _sweep;
  late final AnimationController _pause;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: widget.delay + widget.duration,
    )
      ..addListener(_onTick)
      ..addStatusListener(_onSweepDone);
    _pause = AnimationController(vsync: this, duration: widget.pauseDuration)
      ..addStatusListener(_onPauseDone);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _onSweepDone(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final last = widget.words.isEmpty ||
        _index == widget.words.length - 1;
    if (beuiReduceMotion(context) ||
        widget.words.length < 2 ||
        (last && !widget.loop)) {
      return;
    }
    if (TickerMode.valuesOf(context).enabled) {
      _pause.forward(from: 0);
    }
  }

  void _onPauseDone(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (widget.words.isEmpty) return;
    setState(() => _index = (_index + 1) % widget.words.length);
    _sweep.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTickers();
  }

  @override
  void didUpdateWidget(BeuiChromaticTextReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delay != widget.delay ||
        oldWidget.duration != widget.duration) {
      _sweep.duration = widget.delay + widget.duration;
    }
    if (oldWidget.pauseDuration != widget.pauseDuration) {
      _pause.duration = widget.pauseDuration;
    }
    _syncTickers();
  }

  void _syncTickers() {
    final reduce = beuiReduceMotion(context);
    final live = TickerMode.valuesOf(context).enabled &&
        !reduce &&
        (!widget.startOnView || TickerMode.valuesOf(context).enabled);
    if (!live) {
      _sweep.stop();
      _pause.stop();
      return;
    }
    if (_sweep.isAnimating || _pause.isAnimating) return;
    if (!_sweep.isCompleted) {
      _sweep.forward();
    } else if (widget.words.length >= 2 &&
        (widget.loop || _index < widget.words.length - 1)) {
      _pause.forward();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    _pause.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final style = (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
      color: widget.style?.color ?? colors.foreground,
    );
    final fg = widget.foregroundColor ?? colors.foreground;
    final reduce = beuiReduceMotion(context);
    final hasWords = widget.words.isNotEmpty;
    final word = hasWords ? widget.words[_index % widget.words.length] : '';
    final unique = widget.words.toSet().toList();

    final totalMs =
        (widget.delay + widget.duration).inMilliseconds.clamp(1, 100000);
    final elapsedMs = _sweep.value * totalMs;
    final delayMs = widget.delay.inMilliseconds;
    final sweepLocal = reduce
        ? 1.0
        : ((elapsedMs - delayMs) / widget.duration.inMilliseconds)
            .clamp(0.0, 1.0);
    final sweepT = BeuiCurves.easeInOut.transform(sweepLocal);

    final appear = reduce
        ? 1.0
        : ((elapsedMs - delayMs) / 1000.0).clamp(0.0, 10.0);
    final opacityT = BeuiCurves.easeOut.transform((appear / 0.28).clamp(0.0, 1.0));
    final moveT = BeuiCurves.easeOut.transform((appear / 0.36).clamp(0.0, 1.0));
    final opacity = reduce ? 1.0 : 0.56 + 0.44 * opacityT;
    final y = reduce ? 0.0 : 5 * (1 - moveT);
    final blur = reduce ? 0.0 : 6 * (1 - moveT);

    Widget wordPaint = Text(word, style: style, softWrap: false);
    if (!reduce) {
      wordPaint = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) {
          final g = _chromaticGradient(
            palette: widget.colors.isEmpty
                ? kBeuiChromaticPalette
                : widget.colors,
            foreground: fg,
            t: sweepT,
          );
          return LinearGradient(
            colors: g.colors,
            stops: g.stops,
          ).createShader(rect);
        },
        child: Text(
          word,
          style: style.copyWith(color: const Color(0xFFFFFFFF)),
          softWrap: false,
        ),
      );
    }

    if (blur >= 0.2) {
      wordPaint = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.decal,
        ),
        child: wordPaint,
      );
    }

    wordPaint = Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, y),
        child: wordPaint,
      ),
    );

    return Semantics(
      label: '${widget.prefix}${hasWords ? ' $word' : ''}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(widget.prefix, style: style, softWrap: false),
            if (hasWords) ...[
              Text('\u00A0', style: style),
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  for (final w in unique)
                    IgnorePointer(
                      child: Opacity(
                        opacity: 0,
                        child: Text(w, style: style, softWrap: false),
                      ),
                    ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: wordPaint,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

({List<Color> colors, List<double> stops}) _chromaticGradient({
  required List<Color> palette,
  required Color foreground,
  required double t,
}) {
  final pos = -_kTrail + t * (1 + 2 * _kTrail);
  final transparent = foreground.withValues(alpha: 0);

  Color at(double x) {
    if (x <= pos - _kTrail) return foreground;
    if (x >= pos + _kTrail) return transparent;
    if (palette.isEmpty) return foreground;
    if (palette.length == 1) return palette.first;
    final u = ((x - (pos - _kTrail)) / (2 * _kTrail)).clamp(0.0, 1.0);
    final scaled = u * (palette.length - 1);
    final i = scaled.floor().clamp(0, palette.length - 2);
    final f = scaled - i;
    return Color.lerp(palette[i], palette[i + 1], f)!;
  }

  final keys = <double>{0, 1, pos - _kTrail, pos + _kTrail};
  for (var i = 0; i < palette.length; i++) {
    final o = palette.length == 1
        ? 0.0
        : -_kTrail + (i / (palette.length - 1)) * _kTrail * 2;
    keys.add(pos + o);
  }
  final stops = keys.where((s) => s >= 0 && s <= 1).toList()..sort();
  if (stops.isEmpty) {
    return (colors: [transparent, transparent], stops: const [0, 1]);
  }
  if (stops.first > 0) stops.insert(0, 0);
  if (stops.last < 1) stops.add(1);
  // Collapse runs that would violate strictly-increasing after rounding.
  final outStops = <double>[];
  final outColors = <Color>[];
  for (final s in stops) {
    if (outStops.isEmpty || s > outStops.last) {
      outStops.add(s);
      outColors.add(at(s));
    } else {
      outColors[outColors.length - 1] = at(s);
    }
  }
  if (outStops.length == 1) {
    outStops.add(1);
    outColors.add(outColors.first);
  }
  return (colors: outColors, stops: outStops);
}
