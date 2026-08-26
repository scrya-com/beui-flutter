import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/theme.dart';

const _cells = [
  0.0, 0.14, 0.28,
  0.42, 0.56, 0.70,
  0.84, 0.98, 1.12,
];

/// Compact live-timed agent progress. Port of `AgentProgress`.
class BeuiAgentProgress extends StatefulWidget {
  const BeuiAgentProgress({
    super.key,
    this.label = 'Churning',
    this.elapsedSeconds,
    this.initialSeconds = 0,
    this.running = true,
  });

  final String label;
  final double? elapsedSeconds;
  final double initialSeconds;
  final bool running;

  @override
  State<BeuiAgentProgress> createState() => _BeuiAgentProgressState();
}

class _BeuiAgentProgressState extends State<BeuiAgentProgress>
    with TickerProviderStateMixin {
  late double _internal;
  late final AnimationController _pulse;
  late final AnimationController _clock;

  bool get _controlled => widget.elapsedSeconds != null;
  double get _elapsed => widget.elapsedSeconds ?? _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialSeconds;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!mounted || _controlled || !widget.running) return;
          setState(() => _internal += 0.1);
          _clock.forward(from: 0);
        }
      });
  }

  @override
  void didUpdateWidget(BeuiAgentProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    final live = TickerMode.valuesOf(context).enabled &&
        !beuiReduceMotion(context);
    if (live && !_pulse.isAnimating) _pulse.repeat();
    if (!live && _pulse.isAnimating) _pulse.stop();
    final clock = live && !_controlled && widget.running;
    if (clock && !_clock.isAnimating) _clock.forward();
    if (!clock && _clock.isAnimating) _clock.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _clock.dispose();
    super.dispose();
  }

  String _format(double total) {
    final safe = total < 0 ? 0.0 : total;
    final minutes = safe ~/ 60;
    final seconds = (safe % 60).toStringAsFixed(1);
    return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    return Semantics(
      liveRegion: true,
      label: '${widget.label}, in progress',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Column(
              children: [
                for (var row = 0; row < 3; row++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var col = 0; col < 3; col++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(1),
                              child: AnimatedBuilder(
                                animation: _pulse,
                                builder: (context, _) {
                                  final i = row * 3 + col;
                                  final delay = _cells[i] / 1.6;
                                  var t = (_pulse.value - delay) % 1.0;
                                  if (t < 0) t += 1;
                                  final wave = reduce
                                      ? 0.45
                                      : (0.22 +
                                          0.78 *
                                              (1 - (t - 0.5).abs() * 2)
                                                  .clamp(0.0, 1.0));
                                  return DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: colors.mutedForeground
                                          .withValues(alpha: wave),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              color: colors.mutedForeground,
            ),
          ),
          Text(
            _format(_elapsed),
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
