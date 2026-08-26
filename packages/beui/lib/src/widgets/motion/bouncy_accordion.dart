import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

/// duration 0.55 / bounce 0.38 — Motion `findSpring` rest-time conversion.
const _kRow = BeuiSpringSpec(stiffness: 382.86, damping: 24.26, mass: 1);

/// duration 0.58 / bounce 0.32.
const _kContentOpen = BeuiSpringSpec(stiffness: 300.11, damping: 23.56, mass: 1);

/// duration 0.46 / bounce 0.26.
const _kContentClose = BeuiSpringSpec(stiffness: 423.27, damping: 30.45, mass: 1);

/// duration 0.42 / bounce 0.28.
const _kChevron = BeuiSpringSpec(stiffness: 527.38, damping: 33.07, mass: 1);

const _kRadius = 28.0;
const _kGap = 12.0;

class BeuiBouncyAccordionItem {
  const BeuiBouncyAccordionItem({
    required this.id,
    required this.title,
    this.description,
    this.icon,
    this.enabled = true,
  });

  final String id;
  final String title;
  final String? description;
  final Widget? icon;
  final bool enabled;
}

/// Single-open accordion with weighted spring layout and icon rows.
/// Port of `components/motion/bouncy-accordion.tsx`.
class BeuiBouncyAccordion extends StatefulWidget {
  const BeuiBouncyAccordion({
    super.key,
    required this.items,
    this.value,
    this.initialValue,
    this.onChanged,
    this.collapsible = true,
  });

  final List<BeuiBouncyAccordionItem> items;
  final String? value;
  final String? initialValue;
  final ValueChanged<String?>? onChanged;
  final bool collapsible;

  @override
  State<BeuiBouncyAccordion> createState() => _BeuiBouncyAccordionState();
}

class _BeuiBouncyAccordionState extends State<BeuiBouncyAccordion> {
  late String? _internal;

  bool get _controlled => widget.value != null;
  String? get _current => _controlled ? widget.value : _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialValue;
  }

  void _toggle(String id) {
    final index = widget.items.indexWhere((item) => item.id == id);
    if (index < 0 || !widget.items[index].enabled) return;

    String? next;
    if (_current == id) {
      if (!widget.collapsible) return;
      next = null;
    } else {
      next = id;
    }
    if (!_controlled) setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.items.indexWhere((item) => item.id == _current);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.items.length; i++)
          _BouncyAccordionRow(
            item: widget.items[i],
            open: _current == widget.items[i].id,
            startsGroup: _current == widget.items[i].id ||
                i == 0 ||
                activeIndex == i - 1,
            endsGroup: _current == widget.items[i].id ||
                i == widget.items.length - 1 ||
                activeIndex == i + 1,
            separatedFromPrevious: i > 0 &&
                (_current == widget.items[i].id || activeIndex == i - 1),
            onToggle: () => _toggle(widget.items[i].id),
          ),
      ],
    );
  }
}

class _BouncyAccordionRow extends StatefulWidget {
  const _BouncyAccordionRow({
    required this.item,
    required this.open,
    required this.startsGroup,
    required this.endsGroup,
    required this.separatedFromPrevious,
    required this.onToggle,
  });

  final BeuiBouncyAccordionItem item;
  final bool open;
  final bool startsGroup;
  final bool endsGroup;
  final bool separatedFromPrevious;
  final VoidCallback onToggle;

  @override
  State<_BouncyAccordionRow> createState() => _BouncyAccordionRowState();
}

class _BouncyAccordionRowState extends State<_BouncyAccordionRow>
    with TickerProviderStateMixin {
  late final BeuiSpringValue _gap;
  late final BeuiSpringValue _topR;
  late final BeuiSpringValue _bottomR;
  late final BeuiSpringValue _height;
  late final BeuiSpringValue _chevron;
  final GlobalKey _contentKey = GlobalKey();
  double _contentHeight = 0;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    _gap = BeuiSpringValue(
      value: widget.separatedFromPrevious ? _kGap : 0,
      spec: _kRow,
    )..attach(this);
    _topR = BeuiSpringValue(
      value: widget.startsGroup ? _kRadius : 0,
      spec: _kRow,
    )..attach(this);
    _bottomR = BeuiSpringValue(
      value: widget.endsGroup ? _kRadius : 0,
      spec: _kRow,
    )..attach(this);
    _height = BeuiSpringValue(
      value: 0,
      spec: widget.open ? _kContentOpen : _kContentClose,
    )..attach(this);
    _chevron = BeuiSpringValue(
      value: widget.open ? 1 : 0,
      spec: _kChevron,
    )..attach(this);
    for (final s in [_gap, _topR, _bottomR, _height, _chevron]) {
      s.addListener(_tick);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure(jump: true));
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = beuiReduceMotion(context);
    for (final s in [_gap, _topR, _bottomR, _height, _chevron]) {
      s.reducedMotion = reduce;
    }
  }

  @override
  void didUpdateWidget(_BouncyAccordionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _retarget();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    for (final s in [_gap, _topR, _bottomR, _height, _chevron]) {
      s
        ..removeListener(_tick)
        ..dispose();
    }
    super.dispose();
  }

  void _retarget() {
    _gap.animateTo(widget.separatedFromPrevious ? _kGap : 0);
    _topR.animateTo(widget.startsGroup ? _kRadius : 0);
    _bottomR.animateTo(widget.endsGroup ? _kRadius : 0);
    _chevron.animateTo(widget.open ? 1 : 0);
    _height.spec = widget.open ? _kContentOpen : _kContentClose;
    final hasCopy = widget.item.description != null;
    _height.animateTo(widget.open && hasCopy ? _contentHeight : 0);
  }

  void _measure({bool jump = false}) {
    if (!mounted) return;
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _contentHeight = box.size.height;
    final hasCopy = widget.item.description != null;
    final target = widget.open && hasCopy ? _contentHeight : 0.0;
    if (jump || !_placed) {
      _height.jump(target);
      _placed = true;
      setState(() {});
      return;
    }
    _height.spec = widget.open ? _kContentOpen : _kContentClose;
    _height.animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final top = _topR.value.clamp(0.0, _kRadius);
    final bottom = _bottomR.value.clamp(0.0, _kRadius);
    final radius = BorderRadius.only(
      topLeft: Radius.circular(top),
      topRight: Radius.circular(top),
      bottomLeft: Radius.circular(bottom),
      bottomRight: Radius.circular(bottom),
    );

    return Padding(
      padding: EdgeInsets.only(top: math.max(0.0, _gap.value)),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: colors.card,
          child: Opacity(
            opacity: widget.item.enabled ? 1 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.item.enabled ? widget.onToggle : null,
                  child: Semantics(
                    button: true,
                    enabled: widget.item.enabled,
                    expanded: widget.open,
                    label: widget.item.title,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 54),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          spacing: 16,
                          children: [
                            if (widget.item.icon != null)
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: Center(
                                  child: IconTheme(
                                    data: IconThemeData(
                                      color: colors.mutedForeground,
                                      size: 16,
                                    ),
                                    child: widget.item.icon!,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                widget.item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: colors.foreground,
                                ),
                              ),
                            ),
                            Transform.rotate(
                              angle: _chevron.value * math.pi,
                              child: BeuiIcon(
                                BeuiIcons.chevronDown,
                                size: 16,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ClipRect(
                  child: SizedBox(
                    height: math.max(0.0, _height.value),
                    width: double.infinity,
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: IgnorePointer(
                        ignoring: !widget.open,
                        child: ExcludeSemantics(
                          excluding: !widget.open,
                          child: AnimatedOpacity(
                            opacity: widget.open ? 1 : 0,
                            duration: reduce
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            curve: BeuiCurves.easeOut,
                            child: widget.item.description == null
                                ? const SizedBox.shrink()
                                : Padding(
                                    key: _contentKey,
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      0,
                                      20,
                                      20,
                                    ),
                                    child: Text(
                                      widget.item.description!,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 24 / 15,
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
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
