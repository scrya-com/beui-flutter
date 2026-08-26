import 'dart:async';

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
    with SingleTickerProviderStateMixin {
  late double _internal;
  Timer? _timer;
  late final AnimationController _pulse;

  bool get _controlled => widget.elapsedSeconds != null;
  double get _elapsed => widget.elapsedSeconds ?? _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialSeconds;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _arm();
  }

  @override
  void didUpdateWidget(BeuiAgentProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running ||
        oldWidget.elapsedSeconds != widget.elapsedSeconds) {
      _arm();
    }
  }

  void _arm() {
    _timer?.cancel();
    if (_controlled || !widget.running) return;
    final started = DateTime.now().subtract(
      Duration(milliseconds: (widget.initialSeconds * 1000).round()),
    );
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        _internal = DateTime.now().difference(started).inMilliseconds / 1000;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
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
