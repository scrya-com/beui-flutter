import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

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
                          size: 16,
                          color: colors.mutedForeground,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: BeuiCurves.easeOut,
              alignment: Alignment.topCenter,
              child: _open
                  ? ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: widget.maxHeight),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        itemCount: widget.items.length,
                        itemBuilder: (context, i) {
                          final item = widget.items[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Row(
                              spacing: 10,
                              children: [
                                _StatusMark(
                                  status: item.status,
                                  progress: item.progress,
                                ),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: item.status ==
                                              BeuiTodoStatus.cancelled
                                          ? colors.mutedForeground
                                          : colors.foreground,
                                      decoration: item.status ==
                                              BeuiTodoStatus.cancelled
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (item.detail != null)
                                  Text(
                                    item.detail!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.mutedForeground,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ),
        ],
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpin();
  }

  @override
  void didUpdateWidget(_StatusMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin();
  }

  void _syncSpin() {
    final spin = widget.status == BeuiTodoStatus.inProgress &&
        widget.progress == null &&
        !beuiReduceMotion(context);
    if (spin && !_spin.isAnimating) _spin.repeat();
    if (!spin && _spin.isAnimating) _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
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
    return SizedBox(
      width: 20,
      height: 20,
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, _) {
          return Transform.rotate(
            angle: widget.status == BeuiTodoStatus.inProgress
                ? _spin.value * math.pi * 2
                : 0,
            child: CustomPaint(
              painter: _TodoPainter(
                status: widget.status,
                progress: ((widget.progress ?? 0) / 100).clamp(0.0, 1.0),
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TodoPainter extends CustomPainter {
  _TodoPainter({
    required this.status,
    required this.progress,
    required this.color,
  });

  final BeuiTodoStatus status;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    if (status == BeuiTodoStatus.pending) {
      p.strokeWidth = 1.2;
      canvas.drawCircle(c, r, p);
      return;
    }
    if (status == BeuiTodoStatus.inProgress) {
      canvas.drawCircle(c, r, p..color = color.withValues(alpha: 0.2));
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -1.57,
        6.28 * (progress == 0 ? 0.68 : progress),
        false,
        p..color = color,
      );
      return;
    }
    canvas.drawCircle(c, r, p);
    if (status == BeuiTodoStatus.completed) {
      canvas.drawPath(
        Path()
          ..moveTo(size.width * 0.28, size.height * 0.52)
          ..lineTo(size.width * 0.44, size.height * 0.68)
          ..lineTo(size.width * 0.74, size.height * 0.34),
        p,
      );
    } else {
      canvas.drawLine(
        Offset(size.width * 0.32, size.height * 0.32),
        Offset(size.width * 0.68, size.height * 0.68),
        p,
      );
      canvas.drawLine(
        Offset(size.width * 0.68, size.height * 0.32),
        Offset(size.width * 0.32, size.height * 0.68),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TodoPainter oldDelegate) =>
      oldDelegate.status != status ||
      oldDelegate.progress != progress ||
      oldDelegate.color != color;
}
