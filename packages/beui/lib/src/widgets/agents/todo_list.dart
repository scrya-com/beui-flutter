import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import 'disclosure.dart';

enum BeuiTodoStatus { pending, inProgress, completed, cancelled }

class BeuiTodoItem {
  const BeuiTodoItem({
    required this.id,
    required this.title,
    this.status = BeuiTodoStatus.pending,
    this.progress,
    this.detail,
  });

  final String id;
  final String title;
  final BeuiTodoStatus status;
  final double? progress;
  final String? detail;
}

/// Collapsible agent task plan. Port of `TodoList`.
class BeuiTodoList extends StatefulWidget {
  const BeuiTodoList({
    super.key,
    required this.items,
    this.title = 'To-dos',
    this.open,
    this.initialOpen = true,
    this.onOpenChanged,
    this.collapseOnComplete = true,
    this.maxHeight = 248,
  });

  final List<BeuiTodoItem> items;
  final String title;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;
  final bool collapseOnComplete;
  final double maxHeight;

  @override
  State<BeuiTodoList> createState() => _BeuiTodoListState();
}

class _BeuiTodoListState extends State<BeuiTodoList> {
  late bool _internal;
  bool _wasComplete = false;

  bool get _controlled => widget.open != null;
  bool get _open => _controlled ? widget.open! : _internal;

  int get _completed =>
      widget.items.where((i) => i.status == BeuiTodoStatus.completed).length;

  bool get _allComplete =>
      widget.items.isNotEmpty && _completed == widget.items.length;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialOpen;
    _wasComplete = _allComplete;
  }

  @override
  void didUpdateWidget(BeuiTodoList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_wasComplete && !_allComplete) _setOpen(true);
    if (!_wasComplete && _allComplete && widget.collapseOnComplete) {
      _setOpen(false);
    }
    _wasComplete = _allComplete;
  }

  void _setOpen(bool next) {
    if (_open == next) return;
    if (!_controlled) setState(() => _internal = next);
    widget.onOpenChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => _setOpen(!_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                spacing: 10,
                children: [
                  BeuiIcon(
                    _allComplete ? BeuiIcons.check : BeuiIcons.listTodo,
                    color: _allComplete
                        ? const Color(0xFF10B981)
                        : colors.mutedForeground,
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  Text(
                    '$_completed/${widget.items.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.mutedForeground,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  BeuiSpringBuilder(
                    value: _open ? 1 : 0,
                    spec: BeuiSpringSpec.swap,
                    builder: (context, t) {
                      return Transform.rotate(
                        angle: t * math.pi,
                        child: BeuiIcon(
                          BeuiIcons.chevronDown,
                          size: 14,
                          color: colors.mutedForeground.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          BeuiAgentDisclosure(
            open: _open,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxHeight),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                children: [
                  for (final item in widget.items)
                    _TodoRow(key: ValueKey(item.id), item: item),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoRow extends StatefulWidget {
  const _TodoRow({super.key, required this.item});

  final BeuiTodoItem item;

  @override
  State<_TodoRow> createState() => _TodoRowState();
}

class _TodoRowState extends State<_TodoRow> with TickerProviderStateMixin {
  late final BeuiSpringValue _y;
  late final AnimationController _fade;
  late final AnimationController _strike;

  @override
  void initState() {
    super.initState();
    // AnimatePresence initial={false}: first paint is already in place.
    _y = BeuiSpringValue(value: 1, spec: BeuiSpringSpec.layout)..attach(this);
    _y.addListener(_tick);
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1,
    )..addListener(_tick);
    // 60ms delay + 280ms draw = 340ms (todo-list.tsx strikethrough).
    _strike = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )..addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = beuiReduceMotion(context);
    _y.reducedMotion = reduce;
    if (reduce) {
      _strike.value = widget.item.status == BeuiTodoStatus.completed ? 1 : 0;
      return;
    }
    _syncStrike();
  }

  @override
  void didUpdateWidget(_TodoRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncStrike();
  }

  void _syncStrike() {
    final reduce = beuiReduceMotion(context);
    final done = widget.item.status == BeuiTodoStatus.completed;
    if (reduce) {
      _strike.value = done ? 1 : 0;
      return;
    }
    if (done && _strike.value < 1 && !_strike.isAnimating) {
      _strike.forward();
    } else if (!done && _strike.value > 0) {
      _strike.reverse();
    }
  }

  @override
  void dispose() {
    _y
      ..removeListener(_tick)
      ..dispose();
    _fade.dispose();
    _strike.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final item = widget.item;
    final color = switch (item.status) {
      BeuiTodoStatus.pending => colors.mutedForeground.withValues(alpha: 0.65),
      BeuiTodoStatus.inProgress => colors.foreground,
      BeuiTodoStatus.completed => colors.mutedForeground.withValues(alpha: 0.6),
      BeuiTodoStatus.cancelled => colors.mutedForeground.withValues(alpha: 0.55),
    };
    final opacity = beuiReduceMotion(context)
        ? 1.0
        : BeuiCurves.easeOut.transform(_fade.value.clamp(0.0, 1.0));
    final strikeT = ((_strike.value * 340 - 60) / 280).clamp(0.0, 1.0);
    final strike = BeuiCurves.easeOut.transform(strikeT);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, 6 * (1 - _y.value)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Row(
              spacing: 10,
              children: [
                _StatusMark(
                  status: item.status,
                  progress: item.progress,
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: color,
                        ),
                      ),
                      if (strike > 0)
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: strike,
                              alignment: Alignment.centerLeft,
                              child: ColoredBox(
                                color: color,
                                child: const SizedBox(height: 1),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.detail != null)
                  Text(
                    item.detail!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.mutedForeground.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMark extends StatefulWidget {
  const _StatusMark({required this.status, this.progress});
  final BeuiTodoStatus status;
  final double? progress;

  @override
  State<_StatusMark> createState() => _StatusMarkState();
}

class _StatusMarkState extends State<_StatusMark>
    with TickerProviderStateMixin {
  late final BeuiSpringValue _arc;
  late final AnimationController _spin;
  late final AnimationController _check;
  late final AnimationController _cancel;

  @override
  void initState() {
    super.initState();
    _arc = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _arc.addListener(_tick);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addListener(_tick);
    _check = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(_tick);
    _cancel = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _arc.reducedMotion = beuiReduceMotion(context);
    _sync();
  }

  @override
  void didUpdateWidget(_StatusMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final reduce = beuiReduceMotion(context);
    final spinning = widget.status == BeuiTodoStatus.inProgress &&
        widget.progress == null &&
        !reduce;
    if (spinning) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin.stop();
    }

    final target = widget.status == BeuiTodoStatus.inProgress
        ? ((widget.progress ?? 68) / 100).clamp(0.0, 1.0)
        : 0.0;
    if (reduce) {
      _arc.jump(target);
    } else {
      _arc.animateTo(target);
    }

    if (widget.status == BeuiTodoStatus.completed) {
      if (reduce) {
        _check.value = 1;
      } else if (_check.value < 1) {
        _check.forward();
      }
    } else if (_check.value > 0) {
      if (reduce) {
        _check.value = 0;
      } else {
        _check.reverse();
      }
    }

    if (widget.status == BeuiTodoStatus.cancelled) {
      if (reduce) {
        _cancel.value = 1;
      } else if (_cancel.value < 1) {
        _cancel.forward();
      }
    } else if (_cancel.value > 0) {
      if (reduce) {
        _cancel.value = 0;
      } else {
        _cancel.reverse();
      }
    }
  }

  @override
  void dispose() {
    _arc
      ..removeListener(_tick)
      ..dispose();
    _spin.dispose();
    _check.dispose();
    _cancel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final color = switch (widget.status) {
      BeuiTodoStatus.completed => const Color(0xFF10B981),
      BeuiTodoStatus.cancelled => colors.destructive,
      BeuiTodoStatus.inProgress => colors.foreground,
      BeuiTodoStatus.pending => colors.mutedForeground,
    };
    final check = BeuiCurves.easeOut.transform(_check.value.clamp(0.0, 1.0));
    final cancel = BeuiCurves.easeOut.transform(_cancel.value.clamp(0.0, 1.0));
    return SizedBox(
      width: 20,
      height: 20,
      child: Transform.rotate(
        angle: widget.status == BeuiTodoStatus.inProgress &&
                widget.progress == null &&
                !beuiReduceMotion(context)
            ? _spin.value * math.pi * 2
            : 0,
        child: CustomPaint(
          painter: _TodoPainter(
            status: widget.status,
            progress: _arc.value.clamp(0.0, 1.0),
            check: check,
            cancel: cancel,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TodoPainter extends CustomPainter {
  _TodoPainter({
    required this.status,
    required this.progress,
    required this.check,
    required this.cancel,
    required this.color,
  });

  final BeuiTodoStatus status;
  final double progress;
  final double check;
  final double cancel;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final fill = Paint()
      ..color = color.withValues(alpha: status == BeuiTodoStatus.completed ? 0.06 : 0);
    canvas.drawCircle(c, r, fill);
    if (status == BeuiTodoStatus.pending) {
      p.strokeWidth = 1.2;
      canvas.drawCircle(c, r, p);
    } else {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color.withValues(alpha: status == BeuiTodoStatus.inProgress ? 0.2 : 1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        p
          ..color = color
          ..strokeWidth = 2,
      );
    }
    if (check > 0) {
      final path = Path()
        ..moveTo(size.width * 0.31, size.height * 0.51)
        ..lineTo(size.width * 0.44, size.height * 0.64)
        ..lineTo(size.width * 0.70, size.height * 0.36);
      final metrics = path.computeMetrics().first;
      canvas.drawPath(
        metrics.extractPath(0, metrics.length * check),
        p
          ..color = color
          ..strokeWidth = 2,
      );
    }
    if (cancel > 0) {
      final a = Path()
        ..moveTo(size.width * 0.35, size.height * 0.35)
        ..lineTo(size.width * 0.65, size.height * 0.65);
      final b = Path()
        ..moveTo(size.width * 0.65, size.height * 0.35)
        ..lineTo(size.width * 0.35, size.height * 0.65);
      for (final path in [a, b]) {
        final m = path.computeMetrics().first;
        canvas.drawPath(
          m.extractPath(0, m.length * cancel),
          p
            ..color = color
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TodoPainter oldDelegate) =>
      oldDelegate.status != status ||
      oldDelegate.progress != progress ||
      oldDelegate.check != check ||
      oldDelegate.cancel != cancel ||
      oldDelegate.color != color;
}
