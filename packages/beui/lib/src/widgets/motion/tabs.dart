import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

enum BeuiTabsVariant { pill, underline, segment }

class _TabsScope extends InheritedWidget {
  const _TabsScope({
    required this.value,
    required this.setValue,
    required this.variant,
    required this.register,
    required super.child,
  });

  final String value;
  final ValueChanged<String> setValue;
  final BeuiTabsVariant variant;
  final void Function(String value, GlobalKey key) register;

  static _TabsScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TabsScope>();
    assert(scope != null, 'Tabs parts must be inside BeuiTabs');
    return scope!;
  }

  @override
  bool updateShouldNotify(_TabsScope oldWidget) =>
      value != oldWidget.value || variant != oldWidget.variant;
}

/// Pill, segment or underline tabs with a spring-gliding indicator.
/// Port of `components/motion/tabs.tsx`.
class BeuiTabs extends StatefulWidget {
  const BeuiTabs({
    super.key,
    this.value,
    this.initialValue,
    this.onChanged,
    this.variant = BeuiTabsVariant.pill,
    required this.child,
  });

  final String? value;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final BeuiTabsVariant variant;
  final Widget child;

  @override
  State<BeuiTabs> createState() => _BeuiTabsState();
}

class _BeuiTabsState extends State<BeuiTabs> {
  late String _internal;
  final Map<String, GlobalKey> _keys = {};

  bool get _controlled => widget.value != null;
  String get _current => _controlled ? widget.value! : _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialValue ?? widget.value ?? '';
  }

  void _set(String next) {
    if (!_controlled) setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  void _register(String value, GlobalKey key) {
    _keys[value] = key;
  }

  @override
  Widget build(BuildContext context) {
    return _TabsScope(
      value: _current,
      setValue: _set,
      variant: widget.variant,
      register: _register,
      child: widget.child,
    );
  }
}

class BeuiTabsList extends StatefulWidget {
  const BeuiTabsList({super.key, required this.children});

  final List<Widget> children;

  @override
  State<BeuiTabsList> createState() => _BeuiTabsListState();
}

class _BeuiTabsListState extends State<BeuiTabsList>
    with SingleTickerProviderStateMixin {
  final GlobalKey _listKey = GlobalKey();
  Rect _indicator = Rect.zero;
  Rect _from = Rect.zero;
  double _t = 1;
  late final BeuiSpringValue _spring;

  @override
  void initState() {
    super.initState();
    _spring = BeuiSpringValue(value: 1, spec: BeuiSpringSpec.tabs)..attach(this);
    _spring.addListener(_onSpring);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure(jump: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _spring.reducedMotion = beuiReduceMotion(context);
  }

  @override
  void dispose() {
    _spring
      ..removeListener(_onSpring)
      ..dispose();
    super.dispose();
  }

  void _onSpring() {
    setState(() {
      _t = _spring.value;
      _indicator = Rect.lerp(_from, _target, _t)!;
    });
  }

  Rect _target = Rect.zero;

  void _measure({bool jump = false}) {
    if (!mounted) return;
    final scope = context.getInheritedWidgetOfExactType<_TabsScope>();
    if (scope == null) return;
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null || !listBox.hasSize) return;
    final key = (context.findAncestorStateOfType<_BeuiTabsState>())?._keys[scope.value];
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = listBox.globalToLocal(box.localToGlobal(Offset.zero));
    final next = origin & box.size;
    if (jump || _indicator == Rect.zero) {
      _from = next;
      _target = next;
      _indicator = next;
      _spring.jump(1);
      setState(() {});
      return;
    }
    if (next == _target) return;
    _from = _indicator;
    _target = next;
    _spring.jump(0);
    _spring.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final scope = _TabsScope.of(context);
    final colors = context.beuiColors;
    final variant = scope.variant;
    final radius = switch (variant) {
      BeuiTabsVariant.pill => BeuiRadii.pill,
      BeuiTabsVariant.segment => BeuiRadii.lg,
      BeuiTabsVariant.underline => 0.0,
    };

    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    return DecoratedBox(
      decoration: BoxDecoration(
        color: variant == BeuiTabsVariant.underline
            ? const Color(0x00000000)
            : colors.card,
        borderRadius: BorderRadius.circular(radius),
        border: variant == BeuiTabsVariant.underline
            ? Border(bottom: BorderSide(color: colors.border))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(switch (variant) {
          BeuiTabsVariant.pill => 4,
          BeuiTabsVariant.segment => 2,
          BeuiTabsVariant.underline => 0,
        }),
        child: Stack(
          key: _listKey,
          children: [
            if (_indicator != Rect.zero)
              Positioned(
                left: variant == BeuiTabsVariant.underline
                    ? _indicator.left
                    : _indicator.left,
                top: variant == BeuiTabsVariant.underline
                    ? _indicator.bottom - 1
                    : _indicator.top,
                width: _indicator.width,
                height: variant == BeuiTabsVariant.underline ? 1 : _indicator.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(
                      variant == BeuiTabsVariant.pill
                          ? BeuiRadii.pill
                          : variant == BeuiTabsVariant.segment
                              ? BeuiRadii.md
                              : 0,
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: variant == BeuiTabsVariant.segment ? 0 : 4,
              children: widget.children,
            ),
          ],
        ),
      ),
    );
  }
}

class BeuiTabsTrigger extends StatefulWidget {
  const BeuiTabsTrigger({
    super.key,
    required this.value,
    required this.child,
  });

  final String value;
  final Widget child;

  @override
  State<BeuiTabsTrigger> createState() => _BeuiTabsTriggerState();
}

class _BeuiTabsTriggerState extends State<BeuiTabsTrigger> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final scope = _TabsScope.of(context);
    scope.register(widget.value, _key);
    final colors = context.beuiColors;
    final active = scope.value == widget.value;
    final variant = scope.variant;

    return GestureDetector(
      key: _key,
      onTap: () => scope.setValue(widget.value),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: variant == BeuiTabsVariant.underline ? 44 : 0,
        ),
        child: Padding(
          padding: variant == BeuiTabsVariant.underline
              ? const EdgeInsets.fromLTRB(12, 4, 12, 10)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: active
                  ? (variant == BeuiTabsVariant.underline
                      ? colors.foreground
                      : colors.primaryForeground)
                  : colors.mutedForeground,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class BeuiTabsContent extends StatelessWidget {
  const BeuiTabsContent({
    super.key,
    required this.value,
    required this.child,
  });

  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = _TabsScope.of(context);
    final active = scope.value == value;
    final reduce = beuiReduceMotion(context);
    if (!active) {
      return Offstage(offstage: true, child: child);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
      curve: BeuiCurves.easeOut,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, reduce ? 0 : 4 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            color: context.beuiColors.mutedForeground,
          ),
          child: child,
        ),
      ),
    );
  }
}
