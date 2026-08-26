import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import 'disclosure.dart';

class BeuiCitationItem {
  const BeuiCitationItem({
    required this.id,
    required this.title,
    this.domain,
    this.url,
  });

  final String id;
  final String title;
  final String? domain;
  final String? url;
}

/// Inline numbered marker. Port of `Citation`.
class BeuiCitation extends StatelessWidget {
  const BeuiCitation({
    super.key,
    required this.index,
    this.semanticLabel,
  });

  final int index;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.muted.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1,
              color: colors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapsible citation collection. Port of `Citations`.
class BeuiCitations extends StatefulWidget {
  const BeuiCitations({
    super.key,
    required this.citations,
    this.title = 'Sources',
    this.open,
    this.initialOpen = false,
    this.onOpenChanged,
  });

  final List<BeuiCitationItem> citations;
  final String title;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;

  @override
  State<BeuiCitations> createState() => _BeuiCitationsState();
}

class _BeuiCitationsState extends State<BeuiCitations> {
  late bool _internal;

  bool get _controlled => widget.open != null;
  bool get _open => _controlled ? widget.open! : _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialOpen;
  }

  void _setOpen(bool next) {
    if (!_controlled) setState(() => _internal = next);
    widget.onOpenChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _setOpen(!_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              spacing: 8,
              children: [
                BeuiIcon(
                  BeuiIcons.book,
                  size: 16,
                  color: colors.mutedForeground,
                ),
                Expanded(
                  child: Text(
                    '${widget.title} · ${widget.citations.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.foreground,
                    ),
                  ),
                ),
                BeuiSpringBuilder(
                  value: _open ? 1 : 0,
                  spec: BeuiSpringSpec.swap,
                  builder: (context, t) {
                    return Transform.rotate(
                      angle: t * 3.14159,
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
        BeuiAgentDisclosure(
          open: _open,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                for (var i = 0; i < widget.citations.length; i++)
                  _CitationEnter(
                    key: ValueKey(widget.citations[i].id),
                    child: _CitationRow(
                      index: i + 1,
                      item: widget.citations[i],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Mount enter: opacity 180ms EASE_OUT, y 6px on SPRING_LAYOUT.
class _CitationEnter extends StatefulWidget {
  const _CitationEnter({super.key, required this.child});

  final Widget child;

  @override
  State<_CitationEnter> createState() => _CitationEnterState();
}

class _CitationEnterState extends State<_CitationEnter>
    with TickerProviderStateMixin {
  late final BeuiSpringValue _y;
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _y = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _y.addListener(_onTick);
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = beuiReduceMotion(context);
    _y.reducedMotion = reduce;
    if (reduce) {
      _y.jump(1);
      _fade.value = 1;
      return;
    }
    if (TickerMode.valuesOf(context).enabled && _y.value == 0 && !_y.isAnimating) {
      _y.animateTo(1);
      _fade.forward();
    }
  }

  @override
  void dispose() {
    _y
      ..removeListener(_onTick)
      ..dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _y.value;
    final opacity = beuiReduceMotion(context)
        ? 1.0
        : BeuiCurves.easeOut.transform(_fade.value.clamp(0.0, 1.0));
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, 6 * (1 - t)),
        child: widget.child,
      ),
    );
  }
}

class _CitationRow extends StatelessWidget {
  const _CitationRow({required this.index, required this.item});
  final int index;
  final BeuiCitationItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        spacing: 10,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.foreground,
                  ),
                ),
                if (item.domain != null)
                  Text(
                    item.domain!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
