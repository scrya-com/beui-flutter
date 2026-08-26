import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

/// Port of `components/motion/checkbox.tsx`.
class BeuiCheckbox extends StatefulWidget {
  const BeuiCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.indeterminate = false,
    this.enabled = true,
    this.label,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool indeterminate;
  final bool enabled;
  final String? label;
  final String? semanticLabel;

  @override
  State<BeuiCheckbox> createState() => _BeuiCheckboxState();
}

class _BeuiCheckboxState extends State<BeuiCheckbox> {
  bool _pressed = false;

  bool get _marked => widget.value || widget.indeterminate;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final scale = (!widget.enabled || reduce)
        ? 1.0
        : (_pressed ? 0.92 : 1.0);

    return GestureDetector(
      onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Semantics(
            checked: widget.indeterminate ? false : widget.value,
            enabled: widget.enabled,
            label: widget.semanticLabel ?? widget.label,
            child: BeuiSpringBuilder(
              value: scale,
              spec: BeuiSpringSpec.press,
              builder: (context, s) {
                return Transform.scale(
                  scale: s,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _marked ? colors.primary : colors.background,
                      borderRadius: BorderRadius.circular(BeuiRadii.md),
                      border: Border.all(
                        color: _marked
                            ? colors.primary
                            : colors.mutedForeground.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: _marked
                        ? Center(
                            child: widget.indeterminate
                                ? Container(
                                    width: 10,
                                    height: 2,
                                    color: colors.primaryForeground,
                                  )
                                : BeuiIcon(
                                    BeuiIcons.check,
                                    size: 12,
                                    color: colors.primaryForeground,
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
