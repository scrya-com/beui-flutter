import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

/// Toggle with a heavy spring-driven thumb. Port of `components/motion/switch.tsx`.
///
/// Controlled when [value] is set. Uncontrolled uses [initialValue].
class BeuiSwitch extends StatefulWidget {
  const BeuiSwitch({
    super.key,
    this.value,
    this.initialValue = false,
    this.onChanged,
    this.enabled = true,
    this.label,
    this.semanticLabel,
  });

  final bool? value;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final String? label;
  final String? semanticLabel;

  @override
  State<BeuiSwitch> createState() => _BeuiSwitchState();
}

class _BeuiSwitchState extends State<BeuiSwitch> {
  late bool _internal;
  bool _pressed = false;

  bool get _controlled => widget.value != null;
  bool get _on => _controlled ? widget.value! : _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialValue;
  }

  void _toggle() {
    if (!widget.enabled) return;
    final next = !_on;
    if (!_controlled) setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final track = _on ? colors.primary : colors.mutedForeground.withValues(alpha: 0.6);
    final squish = widget.enabled && _pressed && !reduce;

    return GestureDetector(
      onTap: _toggle,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Semantics(
            toggled: _on,
            enabled: widget.enabled,
            label: widget.semanticLabel ?? widget.label,
            child: Opacity(
              opacity: widget.enabled ? 1 : 0.6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(BeuiRadii.pill),
                ),
                child: BeuiSpringBuilder(
                  value: _on ? 1 : 0,
                  spec: BeuiSpringSpec.switchThumb,
                  builder: (context, t) {
                    return Align(
                      alignment: Alignment.lerp(
                            Alignment.centerLeft,
                            Alignment.centerRight,
                            t,
                          )!,
                      child: Transform.scale(
                        scale: squish ? 0.9 : 1,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: colors.background,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (widget.label != null)
            Text(
              widget.label!,
              style: TextStyle(fontSize: 14, color: colors.foreground),
            ),
        ],
      ),
    );
  }
}
