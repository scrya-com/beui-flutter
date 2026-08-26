import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

class BeuiSharedLayoutItem {
  const BeuiSharedLayoutItem({
    required this.id,
    required this.child,
  });

  final String id;
  final Widget child;
}

/// Pill that glides between hovered items via shared-layout springs.
/// Port of `components/motion/shared-layout-bg.tsx`.
class BeuiSharedLayoutBg extends StatefulWidget {
  const BeuiSharedLayoutBg({
    super.key,
    required this.items,
    this.inset = 20,
  });

  final List<BeuiSharedLayoutItem> items;

  /// Horizontal inset of the pill relative to each row, in px. Default 20.
  final double inset;

  @override
  State<BeuiSharedLayoutBg> createState() => _BeuiSharedLayoutBgState();
}

class _BeuiSharedLayoutBgState extends State<BeuiSharedLayoutBg>
    with TickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  final _keys = <String, GlobalKey>{};
  String? _active;

  late final BeuiSpringValue _x;
  late final BeuiSpringValue _y;
  late final BeuiSpringValue _w;
  late final BeuiSpringValue _h;
  late final BeuiSpringValue _show;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    _x = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _y = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _w = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _h = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _show = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    for (final s in [_x, _y, _w, _h, _show]) {
      s.addListener(_tick);
    }
  }

  bool _frame = false;
  void _tick() {
    if (_frame) return;
    _frame = true;
    beuiAfterPointer(() {
      _frame = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = beuiReduceMotion(context);
    for (final s in [_x, _y, _w, _h, _show]) {
      s.reducedMotion = reduce;
    }
  }

  @override
  void dispose() {
    for (final s in [_x, _y, _w, _h, _show]) {
      s
        ..removeListener(_tick)
        ..dispose();
    }
    super.dispose();
  }

  void _activate(String id) {
    if (!mounted) return;
    _active = id;
    _keys.putIfAbsent(id, GlobalKey.new);
    _commit(id);
  }

  void _leave() {
    if (!mounted) return;
    _active = null;
    _show.animateTo(0);
  }

  void _commit(String id) {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final itemBox = _keys[id]?.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null ||
        itemBox == null ||
        !stackBox.hasSize ||
        !itemBox.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _active == id) _commit(id);
      });
      return;
    }
    final origin = stackBox.globalToLocal(itemBox.localToGlobal(Offset.zero));
    final left = origin.dx - widget.inset;
    final top = origin.dy;
    final width = itemBox.size.width + widget.inset * 2;
    final height = itemBox.size.height;
    final appearing = !_placed || _show.value < 0.05;
    if (appearing) {
      _x.jump(left);
      _y.jump(top);
      _w.jump(width);
      _h.jump(height);
      _placed = true;
    } else {
      _x.animateTo(left);
      _y.animateTo(top);
      _w.animateTo(width);
      _h.animateTo(height);
    }
    _show.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final t = _show.value.clamp(0.0, 1.0);
    final blur = reduce ? 0.0 : (6.0 * (1 - t)).clamp(0.0, 10.0);

    Widget? pill;
    if (t > 0.001 && _placed) {
      Widget chrome = DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(BeuiRadii.card),
        ),
      );
      if (blur > 0.2) {
        chrome = ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: chrome,
        );
      }
      pill = Positioned(
        left: _x.value,
        top: _y.value,
        width: _w.value,
        height: _h.value,
        child: IgnorePointer(
          child: Opacity(opacity: t, child: chrome),
        ),
      );
    }

    return MouseRegion(
      onExit: (_) => beuiAfterPointer(_leave),
      child: Stack(
        key: _stackKey,
        clipBehavior: Clip.none,
        children: [
          ?pill,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in widget.items)
                MouseRegion(
                  onEnter: (_) {
                    final id = item.id;
                    beuiAfterPointer(() => _activate(id));
                  },
                  child: KeyedSubtree(
                    key: _keys.putIfAbsent(item.id, GlobalKey.new),
                    child: item.child,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
