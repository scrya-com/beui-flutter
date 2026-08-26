import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/ease.dart';

/// Ease-out count-up triggered when in view.
/// Port of `components/motion/animated-number.tsx`.
class BeuiAnimatedNumber extends StatefulWidget {
  const BeuiAnimatedNumber({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1200),
    this.format,
    this.startOnView = true,
    this.style,
  });

  final double value;
  final Duration duration;
  final String Function(double n)? format;
  final bool startOnView;
  final TextStyle? style;

  @override
  State<BeuiAnimatedNumber> createState() => _BeuiAnimatedNumberState();
}

class _BeuiAnimatedNumberState extends State<BeuiAnimatedNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  double _from = 0;
  double _to = 0;
  bool _started = false;

  String _format(double n) {
    if (widget.format != null) return widget.format!(n);
    return _groupThousands(n.round());
  }

  @override
  void initState() {
    super.initState();
    _to = widget.value;
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  @override
  void didUpdateWidget(BeuiAnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _c.duration = widget.duration;
    }
    if (oldWidget.value != widget.value && _started) {
      _from = _display;
      _to = widget.value;
      _play();
    }
  }

  void _maybeStart() {
    final live = TickerMode.valuesOf(context).enabled;
    if (widget.startOnView && !live) return;
    if (_started) return;
    _started = true;
    _from = 0;
    _to = widget.value;
    _play();
  }

  void _play() {
    if (beuiReduceMotion(context)) {
      _from = _to;
      _c.value = 1;
      return;
    }
    _c.forward(from: 0);
  }

  double get _display {
    final t = BeuiCurves.easeOut.transform(_c.value);
    return _from + (_to - _from) * t;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Text(_format(_display), style: style);
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
