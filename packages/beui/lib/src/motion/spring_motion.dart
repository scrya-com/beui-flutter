import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../physics/spring.dart';
import '../tokens/ease.dart';
import 'reduce.dart';

/// Animates a [double] with a rest-to-rest damped spring.
///
/// Uses elapsed wall-clock seconds into `beuiSpringEase` so the feel matches
/// Framer Motion `type: "spring"` (unbounded, settles on its own).
class BeuiSpringValue extends ChangeNotifier {
  BeuiSpringValue({
    required double value,
    this.spec = BeuiSpringSpec.layout,
    this.reducedMotion = false,
  })  : _current = value,
        _from = value,
        _to = value;

  BeuiSpringSpec spec;
  bool reducedMotion;

  double _current;
  double _from;
  double _to;
  double _elapsed = 0;
  bool _running = false;
  Ticker? _ticker;

  double get value => _current;
  bool get isAnimating => _running;

  void attach(TickerProvider vsync) {
    _ticker ??= vsync.createTicker(_tick);
  }

  void jump(double next) {
    _from = next;
    _to = next;
    _current = next;
    _elapsed = 0;
    _running = false;
    _ticker?.stop();
    notifyListeners();
  }

  void animateTo(double next) {
    if ((next - _current).abs() < 1e-6) {
      _to = next;
      _current = next;
      _running = false;
      _ticker?.stop();
      return;
    }
    if (reducedMotion) {
      jump(next);
      return;
    }
    _from = _current;
    _to = next;
    _elapsed = 0;
    _running = true;
    _restartTicker();
  }

  /// Retargeting must restart: [_elapsed] is reset, so a live ticker's
  /// elapsed would skip the new rest-to-rest curve. Hover + press both
  /// call [animateTo] in the same frame; starting twice asserts.
  void _restartTicker() {
    final ticker = _ticker;
    if (ticker == null) return;
    if (ticker.isActive) ticker.stop();
    ticker.start();
  }

  void _tick(Duration elapsed) {
    _elapsed = elapsed.inMicroseconds / 1e6;
    final t = beuiSpringEaseSpec(_elapsed, spec);
    _current = _from + (_to - _from) * t;
    final settled = (_elapsed >=
            beuiSpringSettleDuration(spec).inMicroseconds / 1e6) ||
        ((t - 1.0).abs() < 0.002 &&
            beuiSpringResponse(
                  _elapsed,
                  spec.mass,
                  spec.stiffness,
                  spec.damping,
                )
                    .abs() <
                0.004);
    if (settled) {
      _current = _to;
      _running = false;
      _ticker?.stop();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }
}

/// Rebuilds [builder] as [value] springs toward each new target.
class BeuiSpringBuilder extends StatefulWidget {
  const BeuiSpringBuilder({
    super.key,
    required this.value,
    required this.builder,
    this.spec = BeuiSpringSpec.layout,
  });

  final double value;
  final BeuiSpringSpec spec;
  final Widget Function(BuildContext context, double value) builder;

  @override
  State<BeuiSpringBuilder> createState() => _BeuiSpringBuilderState();
}

class _BeuiSpringBuilderState extends State<BeuiSpringBuilder>
    with SingleTickerProviderStateMixin {
  late final BeuiSpringValue _spring;

  @override
  void initState() {
    super.initState();
    _spring = BeuiSpringValue(value: widget.value, spec: widget.spec)
      ..attach(this)
      ..addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _spring.reducedMotion = beuiReduceMotion(context);
  }

  @override
  void didUpdateWidget(BeuiSpringBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _spring.spec = widget.spec;
    if (oldWidget.value != widget.value) {
      _spring.animateTo(widget.value);
    }
  }

  @override
  void dispose() {
    _spring
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _spring.value);
}

/// Follow-spring for a moving target (magnetic, tilt). Integrates each frame.
class BeuiFollowSpring extends ChangeNotifier {
  BeuiFollowSpring({
    double value = 0,
    this.spec = BeuiSpringSpec.mouse,
  })  : _value = value,
        _target = value;

  BeuiSpringSpec spec;

  double _value;
  double _velocity = 0;
  double _target;
  Duration? _last;
  Ticker? _ticker;

  double get value => _value;

  void attach(TickerProvider vsync) {
    _ticker ??= vsync.createTicker(_tick);
  }

  void setTarget(double target, {bool enabled = true}) {
    _target = target;
    if (!enabled) {
      _value = target;
      _velocity = 0;
      _ticker?.stop();
      _last = null;
      notifyListeners();
      return;
    }
    if (!(_ticker?.isActive ?? false)) {
      _last = null;
      _ticker?.start();
    }
  }

  void jump(double next) {
    _value = next;
    _target = next;
    _velocity = 0;
    _ticker?.stop();
    _last = null;
    notifyListeners();
  }

  void _tick(Duration elapsed) {
    final last = _last ?? elapsed;
    _last = elapsed;
    var dt = (elapsed - last).inMicroseconds / 1e6;
    if (dt <= 0) return;
    dt = dt.clamp(0.0, 1 / 30);
    final step = beuiSpringStep(
      value: _value,
      velocity: _velocity,
      target: _target,
      spec: spec,
      dt: dt,
    );
    _value = step.value;
    _velocity = step.velocity;
    if ((_value - _target).abs() < 0.05 && _velocity.abs() < 0.5) {
      _value = _target;
      _velocity = 0;
      _ticker?.stop();
      _last = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }
}
