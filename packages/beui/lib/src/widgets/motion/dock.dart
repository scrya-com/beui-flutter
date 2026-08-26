import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

class _DockScope extends InheritedWidget {
  const _DockScope({
    required this.size,
    required this.register,
    required super.child,
  });

  final double size;
  final void Function(Object id, GlobalKey key, bool active) register;

  static _DockScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_DockScope>();
    assert(scope != null, 'Dock parts must be inside BeuiDock');
    return scope!;
  }

  @override
  bool updateShouldNotify(_DockScope oldWidget) => size != oldWidget.size;
}

/// macOS-style dock with grouped actions and a gliding active pill.
/// Port of `components/motion/dock.tsx`.
class BeuiDock extends StatefulWidget {
  const BeuiDock({
    super.key,
    required this.children,
    this.size = 44,
  });

  final List<Widget> children;
  final double size;

  @override
  State<BeuiDock> createState() => _BeuiDockState();
}

class _BeuiDockState extends State<BeuiDock> with TickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  final Map<Object, GlobalKey> _keys = {};
  final Map<Object, bool> _activeFlags = {};
  Object? _activeId;
  bool _scheduled = false;

  late final BeuiSpringValue _x;
  late final BeuiSpringValue _y;
  late final BeuiSpringValue _w;
  late final BeuiSpringValue _h;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    _x = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _y = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _w = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _h = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    for (final s in [_x, _y, _w, _h]) {
      s.addListener(_tick);
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = beuiReduceMotion(context);
    for (final s in [_x, _y, _w, _h]) {
      s.reducedMotion = reduce;
    }
  }

  @override
  void dispose() {
    for (final s in [_x, _y, _w, _h]) {
      s
        ..removeListener(_tick)
        ..dispose();
    }
    super.dispose();
  }

  void _register(Object id, GlobalKey key, bool active) {
    _keys[id] = key;
    _activeFlags[id] = active;
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      Object? next;
      for (final entry in _activeFlags.entries) {
        if (entry.value) {
          next = entry.key;
          break;
        }
      }
      final was = _activeId;
      _activeId = next;
      _measure(jump: was == null || next == null);
    });
  }

  void _measure({bool jump = false}) {
    final id = _activeId;
    if (id == null) {
      _placed = false;
      if (mounted) setState(() {});
      return;
    }
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final itemBox = _keys[id]?.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null ||
        itemBox == null ||
        !stackBox.hasSize ||
        !itemBox.hasSize) {
      return;
    }
    final origin = stackBox.globalToLocal(itemBox.localToGlobal(Offset.zero));
    // `inset-0.5` — 2px inset from the item.
    final left = origin.dx + 2;
    final top = origin.dy + 2;
    final width = itemBox.size.width - 4;
    final height = itemBox.size.height - 4;
    if (jump || !_placed) {
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _activeId != null) _measure();
    });

    return _DockScope(
      size: widget.size,
      register: _register,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BeuiRadii.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(BeuiRadii.card),
              border: Border.all(color: colors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 50,
                  spreadRadius: -12,
                  offset: Offset(0, 25),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Stack(
                key: _stackKey,
                alignment: Alignment.bottomCenter,
                children: [
                  if (_placed && _activeId != null)
                    Positioned(
                      left: _x.value,
                      top: _y.value,
                      width: _w.value,
                      height: _h.value,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(BeuiRadii.lg),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 6,
                    children: widget.children,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BeuiDockItem extends StatefulWidget {
  const BeuiDockItem({
    super.key,
    required this.child,
    this.onPressed,
    this.active = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool active;
  final String? semanticLabel;

  @override
  State<BeuiDockItem> createState() => _BeuiDockItemState();
}

class _BeuiDockItemState extends State<BeuiDockItem> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final scope = _DockScope.of(context);
    scope.register(this, _key, widget.active);
    final colors = context.beuiColors;
    final size = scope.size;

    final content = SizedBox(
      key: _key,
      width: size,
      height: size,
      child: Center(
        child: IconTheme(
          data: IconThemeData(color: colors.foreground, size: 20),
          child: DefaultTextStyle(
            style: TextStyle(color: colors.foreground),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onPressed == null) {
      return content;
    }

    return Semantics(
      button: true,
      enabled: true,
      selected: widget.active,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: content,
        ),
      ),
    );
  }
}

class BeuiDockSeparator extends StatelessWidget {
  const BeuiDockSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final size = _DockScope.of(context).size;
    return SizedBox(
      height: size,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: 1,
            height: 24,
            child: ColoredBox(color: colors.border),
          ),
        ),
      ),
    );
  }
}
