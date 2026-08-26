import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

class _RadioScope extends InheritedWidget {
  const _RadioScope({
    required this.groupValue,
    required this.setValue,
    required super.child,
  });

  final String groupValue;
  final ValueChanged<String> setValue;

  static _RadioScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_RadioScope>();
    assert(scope != null, 'BeuiRadio must be inside BeuiRadioGroup');
    return scope!;
  }

  @override
  bool updateShouldNotify(_RadioScope oldWidget) =>
      groupValue != oldWidget.groupValue;
}

/// Port of `components/motion/radio.tsx`.
class BeuiRadioGroup extends StatefulWidget {
  const BeuiRadioGroup({
    super.key,
    this.value,
    this.initialValue = '',
    this.onChanged,
    this.orientation = Axis.vertical,
    required this.children,
  });

  final String? value;
  final String initialValue;
  final ValueChanged<String>? onChanged;
  final Axis orientation;
  final List<Widget> children;

  @override
  State<BeuiRadioGroup> createState() => _BeuiRadioGroupState();
}

class _BeuiRadioGroupState extends State<BeuiRadioGroup> {
  late String _internal;

  bool get _controlled => widget.value != null;
  String get _current => _controlled ? widget.value! : _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialValue;
  }

  void _set(String next) {
    if (!_controlled) setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return _RadioScope(
      groupValue: _current,
      setValue: _set,
      child: Flex(
        direction: widget.orientation,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: widget.children,
      ),
    );
  }
}

class BeuiRadio extends StatefulWidget {
  const BeuiRadio({
    super.key,
    required this.value,
    this.label,
    this.enabled = true,
  });

  final String value;
  final String? label;
  final bool enabled;

  @override
  State<BeuiRadio> createState() => _BeuiRadioState();
}

class _BeuiRadioState extends State<BeuiRadio> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scope = _RadioScope.of(context);
    final colors = context.beuiColors;
    final selected = scope.groupValue == widget.value;
    final reduce = beuiReduceMotion(context);
    final scale = (!widget.enabled || reduce) ? 1.0 : (_pressed ? 0.92 : 1.0);

    return GestureDetector(
      onTap: widget.enabled ? () => scope.setValue(widget.value) : null,
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Semantics(
            inMutuallyExclusiveGroup: true,
            checked: selected,
            enabled: widget.enabled,
            label: widget.label,
            child: BeuiSpringBuilder(
              value: scale,
              spec: BeuiSpringSpec.press,
              builder: (context, s) {
                return Transform.scale(
                  scale: s,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? colors.primary
                            : colors.mutedForeground.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.all(4),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          if (widget.label != null)
            Opacity(
              opacity: widget.enabled ? 1 : 0.6,
              child: Text(
                widget.label!,
                style: TextStyle(fontSize: 14, color: colors.foreground),
              ),
            ),
        ],
      ),
    );
  }
}
