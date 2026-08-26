import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

/// Port of `components/motion/input.tsx`.
class BeuiInput extends StatefulWidget {
  const BeuiInput({
    super.key,
    this.label,
    this.value,
    this.initialValue = '',
    this.onChanged,
    this.placeholder,
    this.error,
    this.success = false,
    this.leftIcon,
    this.rightIcon,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.semanticLabel,
  });

  final String? label;
  final String? value;
  final String initialValue;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final Object? error;
  final bool success;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? semanticLabel;

  @override
  State<BeuiInput> createState() => _BeuiInputState();
}

class _BeuiInputState extends State<BeuiInput>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  late final AnimationController _shake;
  bool _hadError = false;

  bool get _controlled => widget.value != null;
  bool get _hasError => widget.error == true || widget.error is String;
  String? get _errorMessage =>
      widget.error is String ? widget.error as String : null;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.value ?? widget.initialValue);
    _focus = FocusNode()..addListener(() => setState(() {}));
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _hadError = _hasError;
  }

  @override
  void didUpdateWidget(BeuiInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controlled && widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value ?? '',
        selection: TextSelection.collapsed(offset: (widget.value ?? '').length),
      );
    }
    if (_hasError && !_hadError && !beuiReduceMotion(context)) {
      _shake.forward(from: 0);
    }
    _hadError = _hasError;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final focused = _focus.hasFocus;
    final border = _hasError
        ? colors.destructive
        : focused
            ? colors.foreground.withValues(alpha: 0.4)
            : colors.border;
    final ring = _hasError
        ? colors.destructive.withValues(alpha: 0.25)
        : focused
            ? colors.ring.withValues(alpha: 0.4)
            : const Color(0x00000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.foreground,
              ),
            ),
          ),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            final wave = t == 0 || t == 1
                ? 0.0
                : (t < 0.2
                    ? -6 * (t / 0.2)
                    : t < 0.4
                        ? -6 + 12 * ((t - 0.2) / 0.2)
                        : t < 0.6
                            ? 6 - 10 * ((t - 0.4) / 0.2)
                            : t < 0.8
                                ? -4 + 8 * ((t - 0.6) / 0.2)
                                : 4 - 6 * ((t - 0.8) / 0.2));
            return Transform.translate(offset: Offset(wave, 0), child: child);
          },
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BeuiRadii.pill),
                border: Border.all(color: border),
                boxShadow: focused || _hasError
                    ? [BoxShadow(color: ring, blurRadius: 0, spreadRadius: 2)]
                    : null,
              ),
              child: Row(
                spacing: 8,
                children: [
                  if (widget.leftIcon != null)
                    IconTheme(
                      data: IconThemeData(
                        color: colors.mutedForeground,
                        size: 16,
                      ),
                      child: widget.leftIcon!,
                    ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        if (widget.placeholder != null &&
                            _controller.text.isEmpty)
                          IgnorePointer(
                            child: Text(
                              widget.placeholder!,
                              style: TextStyle(
                                fontSize: 16,
                                color: colors.mutedForeground
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        EditableText(
                          controller: _controller,
                          focusNode: _focus,
                          readOnly: !widget.enabled,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: colors.foreground,
                          ),
                          cursorColor: colors.foreground,
                          backgroundCursorColor: colors.card,
                          obscureText: widget.obscureText,
                          keyboardType: widget.keyboardType ??
                              TextInputType.text,
                          onChanged: (v) {
                            setState(() {});
                            widget.onChanged?.call(v);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (widget.success)
                    BeuiIcon(
                      BeuiIcons.check,
                      size: 20,
                      color: colors.success,
                    )
                  else if (widget.rightIcon != null)
                    IconTheme(
                      data: IconThemeData(
                        color: colors.mutedForeground,
                        size: 16,
                      ),
                      child: widget.rightIcon!,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _errorMessage!,
              style: TextStyle(fontSize: 12, color: colors.destructive),
            ),
          ),
      ],
    );
  }
}
