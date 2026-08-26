import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

/// Stagger delays from `agent-progress.tsx` (`GRID_CELLS`).
const _kDelays = [
  0.0, 0.14, 0.28,
  0.42, 0.56, 0.70,
  0.84, 0.98, 1.12,
];
const _kCycle = 1.55;

/// Compact live-timed agent progress. Port of `AgentProgress`.
class BeuiAgentProgress extends StatefulWidget {
  const BeuiAgentProgress({
    super.key,
    this.label = 'Churning',
    this.elapsedSeconds,
    this.initialSeconds = 0,
    this.running = true,
    this.fontSize = 14,
  });

  final String label;
  final double? elapsedSeconds;
  final double initialSeconds;
  final bool running;

  /// Root size. React preview sets `text-base` (16). Default is `text-sm` (14).
  final double fontSize;

  @override
  State<BeuiAgentProgress> createState() => _BeuiAgentProgressState();
}

class _BeuiAgentProgressState extends State<BeuiAgentProgress>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _elapsed = Duration.zero;

  bool get _controlled => widget.elapsedSeconds != null;

  double get _seconds {
    if (_controlled) return widget.elapsedSeconds!;
    if (!widget.running) return widget.initialSeconds;
    return widget.initialSeconds + _elapsed.inMicroseconds / 1e6;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(BeuiAgentProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSeconds != widget.initialSeconds && !_controlled) {
      _elapsed = Duration.zero;
    }
    _syncTicker();
  }

  void _syncTicker() {
    final enabled = TickerMode.valuesOf(context).enabled;
    if (enabled) {
      if (!(_ticker?.isActive ?? false)) _ticker?.start();
    } else if (_ticker?.isActive ?? false) {
      _ticker?.stop();
    }
  }

  void _onTick(Duration elapsed) {
    _elapsed = elapsed;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }

  String _format(double total) {
    final safe = total < 0 ? 0.0 : total;
    final minutes = safe ~/ 60;
    final seconds = (safe % 60).toStringAsFixed(1);
    return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
  }

  /// Even keyframes `[a, b, a]` over 1.55s with `EASE_IN_OUT` per half.
  double _wave(double tSec, double delay) {
    final local = tSec - delay;
    if (local <= 0) return 0;
    final u = (local % _kCycle) / _kCycle;
    final half = u < 0.5 ? u * 2 : (u - 0.5) * 2;
    final eased = BeuiCurves.easeInOut.transform(half);
    return u < 0.5 ? eased : 1 - eased;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final tSec = _elapsed.inMicroseconds / 1e6;

    return Semantics(
      container: true,
      liveRegion: true,
      label: '${widget.label}, in progress',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: 20,
              height: 20,
              child: Column(
                spacing: 2,
                children: [
                  for (var row = 0; row < 3; row++)
                    Expanded(
                      child: Row(
                        spacing: 2,
                        children: [
                          for (var col = 0; col < 3; col++)
                            Expanded(
                              child: _Cell(
                                t: _wave(tSec, _kDelays[row * 3 + col]),
                                reduce: reduce,
                                color: colors.mutedForeground,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w500,
              color: colors.mutedForeground,
            ),
          ),
          ExcludeSemantics(
            child: Text(
              _format(_seconds),
              style: TextStyle(
                fontSize: widget.fontSize,
                fontFamily: 'monospace',
                fontFeatures: const [FontFeature.tabularFigures()],
                color: colors.mutedForeground.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.t,
    required this.reduce,
    required this.color,
  });

  final double t;
  final bool reduce;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: reduce ? 1 : 0.72 + 0.28 * t,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(
            alpha: reduce ? 0.35 + 0.45 * t : 0.28 + 0.72 * t,
          ),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
