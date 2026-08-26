import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../physics/spring.dart';
import '../../tokens/ease.dart';

/// Word/character reveal (`text-reveal.tsx` local spring).
const _kRevealSpring = BeuiSpringSpec(
  stiffness: 140,
  damping: 26,
  mass: 1.2,
);

enum BeuiTextRevealSplit { word, char }

/// Word or character reveal with a spring slide-up and blur.
/// Port of `components/motion/text-reveal.tsx`.
class BeuiTextReveal extends StatelessWidget {
  const BeuiTextReveal({
    super.key,
    required this.text,
    this.split = BeuiTextRevealSplit.word,
    this.stagger = 0.09,
    this.delay = 0,
    this.blur = 10,
    this.yOffset = 0.4,
    this.spring = _kRevealSpring,
    this.whileInView = false,
    this.style,
  });

  /// One string per line.
  final List<String> text;
  final BeuiTextRevealSplit split;
  final double stagger;
  final double delay;

  /// Gaussian blur in logical pixels. Capped at 10.
  final double blur;

  /// Fractional Y travel of each unit (0.4 = 40% of its own height).
  final double yOffset;
  final BeuiSpringSpec spring;

  /// When true, the reveal waits until [TickerMode] is enabled.
  final bool whileInView;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final animate = !whileInView || TickerMode.valuesOf(context).enabled;
    final blurPx = math.min(blur, 10.0);
    var unitIndex = 0;
    final lines = <Widget>[];
    for (final line in text) {
      final children = <Widget>[];
      for (final group in _wordGroups(line)) {
        final whole = '${group.text}${group.trailing}';
        if (split != BeuiTextRevealSplit.char) {
          children.add(
            _Unit(
              text: whole,
              delay: delay + unitIndex * stagger,
              blur: blurPx,
              yOffset: yOffset,
              spring: spring,
              animate: animate,
            ),
          );
          unitIndex += 1;
          continue;
        }
        final chars = <Widget>[];
        for (var i = 0; i < whole.length; i++) {
          chars.add(
            _Unit(
              text: whole[i],
              delay: delay + unitIndex * stagger,
              blur: blurPx,
              yOffset: yOffset,
              spring: spring,
              animate: animate,
            ),
          );
          unitIndex += 1;
        }
        children.add(Row(mainAxisSize: MainAxisSize.min, children: chars));
      }
      lines.add(Wrap(children: children));
    }

    return DefaultTextStyle.merge(
      style: style ?? const TextStyle(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }
}

class _Unit extends StatefulWidget {
  const _Unit({
    required this.text,
    required this.delay,
    required this.blur,
    required this.yOffset,
    required this.spring,
    required this.animate,
  });

  final String text;
  final double delay;
  final double blur;
  final double yOffset;
  final BeuiSpringSpec spring;
  final bool animate;

  @override
  State<_Unit> createState() => _UnitState();
}

class _UnitState extends State<_Unit> with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this)..addListener(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncClock();
  }

  @override
  void didUpdateWidget(_Unit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate ||
        oldWidget.delay != widget.delay) {
      _syncClock();
    }
  }

  void _syncClock() {
    final reduce = beuiReduceMotion(context);
    final delay = reduce ? widget.delay * 0.3 : widget.delay;
    final travel = reduce ? 0.25 : 0.9;
    final total = Duration(milliseconds: math.max(1, ((delay + travel) * 1000).round()));
    if (_clock.duration != total) {
      _clock.duration = total;
    }
    if (widget.animate &&
        TickerMode.valuesOf(context).enabled &&
        !_clock.isCompleted &&
        !_clock.isAnimating) {
      _clock.forward();
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = beuiReduceMotion(context);
    final delay = reduce ? widget.delay * 0.3 : widget.delay;
    final travel = reduce ? 0.25 : 0.9;
    final total = math.max(0.001, delay + travel);
    final elapsed = _clock.value * total;
    final local = (elapsed - delay).clamp(0.0, 10.0);

    final double opacity;
    final double yFrac;
    final double blurPx;
    if (reduce) {
      opacity = BeuiCurves.easeOut.transform((local / 0.25).clamp(0.0, 1.0));
      yFrac = 0;
      blurPx = 0;
    } else {
      opacity = BeuiCurves.easeOut.transform((local / 0.7).clamp(0.0, 1.0));
      final springT =
          local <= 0 ? 0.0 : beuiSpringEaseSpec(local, widget.spring);
      yFrac = widget.yOffset * (1 - springT);
      blurPx = widget.blur *
          (1 - BeuiCurves.easeOut.transform((local / 0.9).clamp(0.0, 1.0)));
    }

    Widget child = Text(widget.text, softWrap: false);
    if (blurPx >= 0.2) {
      child = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurPx,
          sigmaY: blurPx,
          tileMode: TileMode.decal,
        ),
        child: child,
      );
    }
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: FractionalTranslation(
        translation: Offset(0, yFrac),
        child: child,
      ),
    );
  }
}

class _WordGroup {
  const _WordGroup(this.text, this.trailing);
  final String text;
  final String trailing;
}

List<_WordGroup> _wordGroups(String line) {
  return [
    for (final match in RegExp(r'\S+\s*|\s+').allMatches(line))
      _chunk(match.group(0)!),
  ];
}

_WordGroup _chunk(String chunk) {
  final trimmed = chunk.trimRight();
  return _WordGroup(trimmed, chunk.substring(trimmed.length));
}
