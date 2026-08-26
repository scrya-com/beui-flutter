import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/colors.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import 'disclosure.dart';

enum BeuiToolApprovalStatus {
  pending,
  approving,
  approved,
  denied,
  running,
  complete,
  error,
}

class BeuiToolApprovalParameter {
  const BeuiToolApprovalParameter({
    required this.id,
    required this.label,
    required this.value,
  });

  final String id;
  final String label;
  final Widget value;
}

/// github-dark-high-contrast bash tokens used by React `AgentCode`.
const _kBashCommand = Color(0xFFF0883E);
const _kBashPath = Color(0xFFA5D6FF);

class BeuiToolApprovalCode extends StatelessWidget {
  const BeuiToolApprovalCode({
    super.key,
    required this.code,
    this.language = 'bash',
  });

  final String code;
  final String language;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final base = colors.foreground.withValues(alpha: 0.85);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                color: base,
                fontFamily: 'Menlo',
                fontSize: 12,
                height: 20 / 12,
              ),
              children: language == 'bash'
                  ? _bashSpans(code, base)
                  : [TextSpan(text: code)],
            ),
            softWrap: true,
            overflow: TextOverflow.clip,
          ),
        ),
      ),
    );
  }
}

List<InlineSpan> _bashSpans(String code, Color base) {
  final spans = <InlineSpan>[];
  var first = true;
  for (final match in RegExp(r'(\s+)|(\S+)').allMatches(code)) {
    final token = match[0]!;
    if (token.trim().isEmpty) {
      spans.add(TextSpan(text: token));
      continue;
    }
    Color? color;
    if (first) {
      color = _kBashCommand;
      first = false;
    } else if (token.contains('/') ||
        token.contains('.tsx') ||
        token.contains('.ts') ||
        token.contains('.js') ||
        token.contains('.json')) {
      color = _kBashPath;
    }
    spans.add(
      TextSpan(
        text: token.replaceAllMapped(
          RegExp(r'([/.])'),
          (m) => '${m[1]}\u200b',
        ),
        style: color == null ? null : TextStyle(color: color),
      ),
    );
  }
  return spans;
}

String beuiToolApprovalStatusCopy(BeuiToolApprovalStatus status) {
  return switch (status) {
    BeuiToolApprovalStatus.approving => 'Approving',
    BeuiToolApprovalStatus.approved => 'Approved',
    BeuiToolApprovalStatus.denied => 'Denied',
    BeuiToolApprovalStatus.running => 'Running',
    BeuiToolApprovalStatus.complete => 'Completed',
    BeuiToolApprovalStatus.error => 'Failed',
    BeuiToolApprovalStatus.pending => 'Approval required',
  };
}

(Color border, Color fill, Color text) _badgeColors(
  BeuiColors colors,
  BeuiToolApprovalStatus status,
) {
  switch (status) {
    case BeuiToolApprovalStatus.pending:
      return (
        colors.warning.withValues(alpha: 0.3),
        colors.warning.withValues(alpha: 0.1),
        colors.warning,
      );
    case BeuiToolApprovalStatus.approving:
    case BeuiToolApprovalStatus.running:
      return (
        const Color(0x4D3B82F6),
        const Color(0x1A3B82F6),
        const Color(0xFF60A5FA),
      );
    case BeuiToolApprovalStatus.approved:
    case BeuiToolApprovalStatus.complete:
      return (
        colors.success.withValues(alpha: 0.3),
        colors.success.withValues(alpha: 0.1),
        colors.success,
      );
    case BeuiToolApprovalStatus.denied:
    case BeuiToolApprovalStatus.error:
      return (
        colors.destructive.withValues(alpha: 0.3),
        colors.destructive.withValues(alpha: 0.1),
        colors.destructive,
      );
  }
}

/// Human-in-the-loop permission card. Port of `components/agents/tool-approval.tsx`.
///
/// Pending cards can be swiped horizontally to deny (toast-stack thresholds:
/// 72px or 520px/s). The drag uses a [Listener] so it does not steal taps
/// from Allow / Deny on mobile.
class BeuiToolApproval extends StatefulWidget {
  const BeuiToolApproval({
    super.key,
    required this.tool,
    this.title,
    this.description,
    this.parameters = const [],
    this.status = BeuiToolApprovalStatus.pending,
    this.open,
    this.initialOpen = false,
    this.onOpenChanged,
    this.onApprove,
    this.onAlwaysAllow,
    this.onDeny,
  });

  final String tool;
  final String? title;
  final String? description;
  final List<BeuiToolApprovalParameter> parameters;
  final BeuiToolApprovalStatus status;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;
  final VoidCallback? onApprove;
  final VoidCallback? onAlwaysAllow;
  final VoidCallback? onDeny;

  @override
  State<BeuiToolApproval> createState() => _BeuiToolApprovalState();
}

class _BeuiToolApprovalState extends State<BeuiToolApproval>
    with TickerProviderStateMixin {
  static const _swipeSlop = 12.0;
  static const _swipeDistance = 72.0;
  static const _swipeFling = 520.0;

  late bool _internalOpen;
  late BeuiToolApprovalStatus _prev;
  late final AnimationController _spin;
  late final BeuiSpringValue _dismissX;

  int? _pointer;
  Offset? _origin;
  double _originX = 0;
  bool _swiping = false;
  DateTime? _lastMoveAt;
  double _lastX = 0;
  double _velocity = 0;

  bool get _controlled => widget.open != null;
  bool get _open => _controlled ? widget.open! : _internalOpen;
  bool get _busy =>
      widget.status == BeuiToolApprovalStatus.approving ||
      widget.status == BeuiToolApprovalStatus.running;
  bool get _pending => widget.status == BeuiToolApprovalStatus.pending;
  bool get _error => widget.status == BeuiToolApprovalStatus.error;
  bool get _canSwipe => _pending && widget.onDeny != null;

  @override
  void initState() {
    super.initState();
    _internalOpen = widget.initialOpen;
    _prev = widget.status;
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (_busy) _spin.repeat();
    _dismissX = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)
      ..attach(this)
      ..addListener(_onDismissTick);
  }

  void _onDismissTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dismissX.reducedMotion = beuiReduceMotion(context);
  }

  @override
  void didUpdateWidget(BeuiToolApproval oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_prev == BeuiToolApprovalStatus.pending &&
        widget.status != BeuiToolApprovalStatus.pending) {
      _setOpen(false);
      if (_dismissX.value.abs() > 0.5) _dismissX.animateTo(0);
    }
    _prev = widget.status;
    if (_busy) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _dismissX
      ..removeListener(_onDismissTick)
      ..dispose();
    _spin.dispose();
    super.dispose();
  }

  void _setOpen(bool next) {
    if (_open == next) return;
    if (!_controlled) setState(() => _internalOpen = next);
    widget.onOpenChanged?.call(next);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_canSwipe || beuiReduceMotion(context)) return;
    _pointer = event.pointer;
    _origin = event.position;
    _originX = _dismissX.value;
    _swiping = false;
    _velocity = 0;
    _lastMoveAt = DateTime.now();
    _lastX = event.position.dx;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || _origin == null) return;
    final delta = event.position - _origin!;
    if (!_swiping) {
      if (delta.distance < _swipeSlop) return;
      if (delta.dx.abs() <= delta.dy.abs()) {
        _pointer = null;
        return;
      }
      _swiping = true;
    }
    final now = DateTime.now();
    final dt = now.difference(_lastMoveAt!).inMicroseconds / 1e6;
    if (dt > 0.0004) {
      _velocity = (event.position.dx - _lastX) / dt;
    }
    _lastMoveAt = now;
    _lastX = event.position.dx;
    _dismissX.jump(_originX + delta.dx);
  }

  void _onPointerUp(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _origin = null;
    if (!_swiping) return;
    _swiping = false;
    final x = _dismissX.value;
    if (x.abs() > _swipeDistance || _velocity.abs() > _swipeFling) {
      widget.onDeny?.call();
    }
    _dismissX.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final title = widget.title ?? 'Allow this tool to run?';
    final badge = _badgeColors(colors, widget.status);
    final painter = _busy
        ? BeuiIcons.loader
        : _error
            ? BeuiIcons.alertCircle
            : widget.status == BeuiToolApprovalStatus.denied
                ? BeuiIcons.x
                : widget.status == BeuiToolApprovalStatus.approved ||
                        widget.status == BeuiToolApprovalStatus.complete
                    ? BeuiIcons.check
                    : BeuiIcons.shieldCheck;

    Widget icon = BeuiIcon(
      painter,
      size: 16,
      color: _error ? colors.destructive : colors.mutedForeground,
    );
    if (_busy && !reduce) {
      icon = RotationTransition(turns: _spin, child: icon);
    }

    final dx = _dismissX.value;
    final fade = (1 - (dx.abs() / 180).clamp(0.0, 0.45));

    return Semantics(
      container: true,
      liveRegion: _busy,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BeuiRadii.card),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.muted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(BeuiRadii.card),
                  border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.border.withValues(alpha: 0.6),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: icon,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: TextStyle(
                                              color: colors.foreground,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.tool,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: colors.mutedForeground,
                                              fontFamily: 'Menlo',
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: badge.$2,
                                        borderRadius: BorderRadius.circular(
                                          BeuiRadii.pill,
                                        ),
                                        border: Border.all(color: badge.$1),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          beuiToolApprovalStatusCopy(
                                            widget.status,
                                          ),
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: badge.$3,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ),
                                  ],
                                ),
                                if (widget.description != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.description!,
                                    style: TextStyle(
                                      color: colors.mutedForeground,
                                      fontSize: 14,
                                      height: 20 / 14,
                                    ),
                                  ),
                                ],
                                if (widget.parameters.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _DetailsToggle(
                                    open: _open,
                                    onPressed: () => _setOpen(!_open),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.parameters.isNotEmpty)
                      BeuiAgentDisclosure(
                        open: _open,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.background.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.border.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                spacing: 8,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final parameter in widget.parameters)
                                    _ParameterRow(parameter: parameter),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    _PendingBar(
                      visible: _pending,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: colors.border.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Action(
                                label: 'Allow once',
                                filled: true,
                                onPressed: widget.onApprove,
                              ),
                              if (widget.onAlwaysAllow != null)
                                _Action(
                                  label: 'Always allow',
                                  filled: false,
                                  onPressed: widget.onAlwaysAllow,
                                ),
                              _Action(
                                label: 'Deny',
                                filled: false,
                                muted: true,
                                scaleOnPress: false,
                                onPressed: widget.onDeny,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParameterRow extends StatelessWidget {
  const _ParameterRow({required this.parameter});

  final BeuiToolApprovalParameter parameter;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 112),
          child: Text(
            parameter.label,
            softWrap: true,
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 12,
              height: 20 / 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DefaultTextStyle(
            style: TextStyle(
              color: colors.foreground.withValues(alpha: 0.85),
              fontFamily: 'Menlo',
              fontSize: 12,
              height: 20 / 12,
            ),
            child: parameter.value,
          ),
        ),
      ],
    );
  }
}

class _DetailsToggle extends StatefulWidget {
  const _DetailsToggle({required this.open, required this.onPressed});

  final bool open;
  final VoidCallback onPressed;

  @override
  State<_DetailsToggle> createState() => _DetailsToggleState();
}

class _DetailsToggleState extends State<_DetailsToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final color = _hovered && beuiHoverCapable(context)
        ? colors.foreground
        : colors.mutedForeground;
    return Semantics(
      button: true,
      expanded: widget.open,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => beuiAfterPointer(() {
          if (mounted) setState(() => _hovered = true);
        }),
        onExit: (_) => beuiAfterPointer(() {
          if (mounted) setState(() => _hovered = false);
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View details',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                BeuiSpringBuilder(
                  value: widget.open ? 1 : 0,
                  spec: BeuiSpringSpec.swap,
                  builder: (context, t) {
                    return Transform.rotate(
                      angle: t * math.pi,
                      child: BeuiIcon(
                        BeuiIcons.chevronDown,
                        size: 14,
                        color: color,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AnimatePresence for the pending action row.
/// Enter: opacity + y:4 over 220ms EASE_OUT. Exit: opacity only. `initial={false}`.
class _PendingBar extends StatefulWidget {
  const _PendingBar({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_PendingBar> createState() => _PendingBarState();
}

class _PendingBarState extends State<_PendingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.visible ? 1 : 0,
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _c.duration = Duration(
      milliseconds: beuiReduceMotion(context) ? 120 : 220,
    );
  }

  @override
  void didUpdateWidget(_PendingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _c.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }
    final reduce = beuiReduceMotion(context);
    final t = _c.value;
    final opacity = _c.status == AnimationStatus.reverse
        ? 1 - BeuiCurves.easeOut.transform(1 - t)
        : BeuiCurves.easeOut.transform(t);
    final y = reduce || _c.status == AnimationStatus.reverse
        ? 0.0
        : 4 * (1 - BeuiCurves.easeOut.transform(t));
    return IgnorePointer(
      ignoring: !widget.visible,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: widget.visible || _c.isAnimating ? 1 : 0,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, y),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Action extends StatefulWidget {
  const _Action({
    required this.label,
    required this.filled,
    this.muted = false,
    this.scaleOnPress = true,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final bool muted;
  final bool scaleOnPress;
  final VoidCallback? onPressed;

  @override
  State<_Action> createState() => _ActionState();
}

class _ActionState extends State<_Action> with SingleTickerProviderStateMixin {
  late final BeuiSpringValue _scale;
  bool _pressed = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _scale = BeuiSpringValue(value: 1, spec: BeuiSpringSpec.press)
      ..attach(this)
      ..addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scale.reducedMotion = beuiReduceMotion(context);
  }

  @override
  void dispose() {
    _scale
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _syncScale() {
    if (!mounted) return;
    final reduce = beuiReduceMotion(context);
    if (reduce || !widget.scaleOnPress || widget.onPressed == null) {
      _scale.jump(1);
      return;
    }
    _scale.animateTo(_pressed ? 0.97 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final hovered = _hovered && beuiHoverCapable(context);
    final bg = widget.filled
        ? colors.foreground
        : widget.muted
            ? (hovered ? colors.muted : const Color(0x00000000))
            : (hovered ? colors.muted : colors.background);
    final fg = widget.filled
        ? colors.background
        : widget.muted
            ? (hovered ? colors.foreground : colors.mutedForeground)
            : colors.foreground;
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      child: MouseRegion(
        cursor: widget.onPressed != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => beuiAfterPointer(() {
          if (!mounted) return;
          setState(() => _hovered = true);
        }),
        onExit: (_) => beuiAfterPointer(() {
          if (!mounted) return;
          setState(() {
            _hovered = false;
            _pressed = false;
          });
          _syncScale();
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: widget.onPressed == null
              ? null
              : (_) {
                  _pressed = true;
                  _syncScale();
                },
          onTapUp: (_) {
            _pressed = false;
            _syncScale();
          },
          onTapCancel: () {
            _pressed = false;
            _syncScale();
          },
          child: Transform.scale(
            scale: _scale.value,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: widget.filled || widget.muted
                      ? null
                      : Border.all(color: colors.border.withValues(alpha: 0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Center(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
