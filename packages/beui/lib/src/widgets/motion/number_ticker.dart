import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/ease.dart';

const _kDigitHeightEm = 1.1;

/// Slot-machine rolling digits with staggered entry.
/// Port of `components/motion/number-ticker.tsx`.
class BeuiNumberTicker extends StatefulWidget {
  const BeuiNumberTicker({
    super.key,
    required this.value,
    this.pad,
    this.duration = const Duration(milliseconds: 900),
    this.stagger = 0.04,
    this.startOnView = true,
    this.prefix,
    this.suffix,
    this.blur = false,
    this.locale = false,
    this.format,
    this.style,
  });

  final num value;

  /// Digits to pad to (left).
  final int? pad;

  /// Per-digit roll duration.
  final Duration duration;

  /// Stagger between digits, in seconds, on first entrance only.
  final double stagger;

  /// When true, digits stay at 0 until [TickerMode] is enabled.
  final bool startOnView;
  final String? prefix;
  final String? suffix;

  /// Add a small blur (≤10px) during digit rolls.
  final bool blur;

  /// Insert locale group separators (commas).
  final bool locale;
  final String Function(int value)? format;
  final TextStyle? style;

  @override
  State<BeuiNumberTicker> createState() => _BeuiNumberTickerState();
}

class _BeuiNumberTickerState extends State<BeuiNumberTicker>
    with SingleTickerProviderStateMixin {
  bool _armed = false;
  bool _entered = false;
  late final AnimationController _enterClock;

  String get _text {
    final rounded = widget.value.round();
    var formatted = widget.format != null
        ? widget.format!(rounded)
        : widget.locale
            ? _groupThousands(rounded)
            : rounded.toString();
    if (widget.pad != null) {
      formatted = formatted.padLeft(widget.pad!, '0');
    }
    return formatted;
  }

  @override
  void initState() {
    super.initState();
    _armed = !widget.startOnView;
    _enterClock = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _entered = true);
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final live = TickerMode.valuesOf(context).enabled;
    if (!_armed && (!widget.startOnView || live)) {
      setState(() => _armed = true);
    }
    _syncEnter();
  }

  @override
  void didUpdateWidget(BeuiNumberTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncEnter();
  }

  void _syncEnter() {
    if (!_armed || _entered) return;
    final glyphs = _text.length;
    final total = widget.duration.inMilliseconds +
        (glyphs * widget.stagger * 1000).round();
    _enterClock.duration = Duration(milliseconds: math.max(total, 1));
    if (TickerMode.valuesOf(context).enabled && !_enterClock.isAnimating) {
      _enterClock.forward();
    }
  }

  @override
  void dispose() {
    _enterClock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final text = _text;
    final readable = '${widget.prefix ?? ''}$text${widget.suffix ?? ''}';
    final glyphs = <({String char, String id})>[
      for (var i = 0; i < text.length; i++)
        (char: text[i], id: 'g-${text.length - 1 - i}'),
    ];

    return Semantics(
      label: readable,
      child: ExcludeSemantics(
        child: DefaultTextStyle(
          style: style,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.prefix != null) Text(widget.prefix!, style: style),
              for (var i = 0; i < glyphs.length; i++)
                if (RegExp(r'\d').hasMatch(glyphs[i].char))
                  _Digit(
                    key: ValueKey(glyphs[i].id),
                    digit: _armed ? int.parse(glyphs[i].char) : 0,
                    delay: _entered ? 0 : i * widget.stagger,
                    duration: widget.duration,
                    blur: widget.blur,
                    style: style,
                  )
                else
                  Text(glyphs[i].char, style: style, key: ValueKey(glyphs[i].id)),
              if (widget.suffix != null) Text(widget.suffix!, style: style),
            ],
          ),
        ),
      ),
    );
  }
}

class _Digit extends StatefulWidget {
  const _Digit({
    super.key,
    required this.digit,
    required this.delay,
    required this.duration,
    required this.blur,
    required this.style,
  });

  final int digit;
  final double delay;
  final Duration duration;
  final bool blur;
  final TextStyle style;

  @override
  State<_Digit> createState() => _DigitState();
}

class _DigitState extends State<_Digit> with SingleTickerProviderStateMixin {
  late int _from;
  late int _to;
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _from = 0;
    _to = widget.digit;
    _c = AnimationController(vsync: this)..addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _play();
    });
  }

  @override
  void didUpdateWidget(_Digit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit == widget.digit) return;
    _from = oldWidget.digit;
    _to = widget.digit;
    _play();
  }

  void _play() {
    final reduce = beuiReduceMotion(context);
    final total = reduce
        ? const Duration(milliseconds: 1)
        : widget.duration +
            Duration(milliseconds: (widget.delay * 1000).round());
    _c.duration = total;
    if (reduce) {
      _c.value = 1;
      return;
    }
    _c.forward(from: 0);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.style.fontSize ?? 14;
    final height = fontSize * _kDigitHeightEm;
    final reduce = beuiReduceMotion(context);
    final totalSec = (_c.duration ?? widget.duration).inMicroseconds / 1e6;
    final elapsed = _c.value * totalSec;
    final local = reduce ? 1.0 : (elapsed - widget.delay).clamp(0.0, 10.0);
    final t = reduce
        ? 1.0
        : BeuiCurves.easeOut.transform(
            (local / (widget.duration.inMilliseconds / 1000)).clamp(0.0, 1.0),
          );
    final digit = _from + (_to - _from) * t;
    final blurDur =
        math.min(widget.duration.inMilliseconds / 1000 * 0.75, 0.32);
    final blurT =
        BeuiCurves.easeOut.transform((local / blurDur).clamp(0.0, 1.0));
    final blur = widget.blur && !reduce ? 10 * (1 - blurT) : 0.0;

    Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var n = 0; n < 10; n++)
          SizedBox(
            height: height,
            child: Center(
              child: Text('$n', style: widget.style.copyWith(height: 1)),
            ),
          ),
      ],
    );
    column = Transform.translate(
      offset: Offset(0, -digit * height),
      child: column,
    );
    if (blur >= 0.2) {
      column = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.decal,
        ),
        child: column,
      );
    }

    return SizedBox(
      height: height,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Opacity(
              opacity: 0,
              child: Text('0', style: widget.style.copyWith(height: 1)),
            ),
            OverflowBox(
              maxHeight: height * 10,
              alignment: Alignment.topCenter,
              child: column,
            ),
          ],
        ),
      ),
    );
  }
}

String _groupThousands(int value) {
  final sign = value.isNegative ? '-' : '';
  final digits = value.abs().toString();
  final buf = StringBuffer(sign);
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}
