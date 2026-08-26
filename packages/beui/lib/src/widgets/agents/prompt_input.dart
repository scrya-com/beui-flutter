import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../motion/keyboard.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import '../motion/button.dart';

class BeuiPromptModel {
  const BeuiPromptModel({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final String value;
  final String label;
  final bool enabled;
}

class BeuiPromptAction {
  const BeuiPromptAction({
    required this.value,
    required this.label,
    this.description,
  });

  final String value;
  final String label;
  final String? description;
}

/// Auto-growing agent composer. Port of `PromptInput`.
class BeuiPromptInput extends StatefulWidget {
  const BeuiPromptInput({
    super.key,
    this.value,
    this.initialValue = '',
    this.onChanged,
    this.models = const [],
    this.model,
    this.initialModel,
    this.onModelChanged,
    this.actions = const [],
    this.onAction,
    this.onSubmit,
    this.loading = false,
    this.onStop,
    this.enabled = true,
    this.placeholder = 'Ask the agent to do something…',
    this.semanticLabel = 'Prompt',
  });

  final String? value;
  final String initialValue;
  final ValueChanged<String>? onChanged;
  final List<BeuiPromptModel> models;
  final String? model;
  final String? initialModel;
  final ValueChanged<String>? onModelChanged;
  final List<BeuiPromptAction> actions;
  final ValueChanged<String>? onAction;
  final void Function(String value, String? model)? onSubmit;
  final bool loading;
  final VoidCallback? onStop;
  final bool enabled;
  final String placeholder;
  final String semanticLabel;

  @override
  State<BeuiPromptInput> createState() => _BeuiPromptInputState();
}

class _BeuiPromptInputState extends State<BeuiPromptInput> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  late String _model;
  bool _actionsOpen = false;

  bool get _controlled => widget.value != null;
  String get _text => _controlled ? (widget.value ?? '') : _controller.text;
  String get _currentModel => widget.model ?? _model;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? widget.initialValue);
    _focus = FocusNode()
      ..addListener(() {
        if (_focus.hasFocus) beuiRevealFocused(context);
      });
    _model = widget.initialModel ??
        widget.model ??
        (widget.models.isNotEmpty ? widget.models.first.value : '');
  }

  @override
  void didUpdateWidget(BeuiPromptInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controlled && widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value ?? '',
        selection: TextSelection.collapsed(offset: (widget.value ?? '').length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.enabled || widget.loading) return;
    final text = _text.trim();
    if (text.isEmpty) return;
    widget.onSubmit?.call(text, _currentModel.isEmpty ? null : _currentModel);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final canSend = widget.enabled && !widget.loading && _text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: BeuiCurves.easeOut,
            alignment: Alignment.topCenter,
            child: !_actionsOpen || widget.actions.isEmpty
                ? const SizedBox(width: double.infinity, height: 0)
                : Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        for (final action in widget.actions)
                          GestureDetector(
                            onTap: () {
                              setState(() => _actionsOpen = false);
                              widget.onAction?.call(action.value);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      action.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colors.foreground,
                                      ),
                                    ),
                                    if (action.description != null)
                                      Text(
                                        action.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.mutedForeground,
                                        ),
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
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                Stack(
                  children: [
                    if (_text.isEmpty)
                      IgnorePointer(
                        child: Text(
                          widget.placeholder,
                          style: TextStyle(
                            fontSize: 15,
                            color: colors.mutedForeground.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    EditableText(
                      controller: _controller,
                      focusNode: _focus,
                      scrollPadding: beuiKeyboardScrollPadding,
                      maxLines: 8,
                      minLines: 2,
                      style: TextStyle(fontSize: 15, color: colors.foreground),
                      cursorColor: colors.foreground,
                      backgroundCursorColor: colors.card,
                      readOnly: !widget.enabled || widget.loading,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onChanged: (v) {
                        setState(() {});
                        widget.onChanged?.call(v);
                      },
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (widget.actions.isNotEmpty)
                      BeuiButton(
                        variant: BeuiButtonVariant.ghost,
                        size: BeuiButtonSize.icon,
                        semanticLabel: 'Actions',
                        onPressed: () =>
                            setState(() => _actionsOpen = !_actionsOpen),
                        child: AnimatedRotation(
                          turns: _actionsOpen ? 0.125 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: BeuiCurves.easeOut,
                          child: BeuiIcon(
                            BeuiIcons.plus,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ),
                    if (widget.models.isNotEmpty)
                      Expanded(
                        child: _ModelChip(
                          models: widget.models,
                          value: _currentModel,
                          onChanged: (v) {
                            if (widget.model == null) setState(() => _model = v);
                            widget.onModelChanged?.call(v);
                          },
                        ),
                      )
                    else
                      const Spacer(),
                    BeuiButton(
                      variant: BeuiButtonVariant.primary,
                      size: BeuiButtonSize.icon,
                      semanticLabel: widget.loading ? 'Stop' : 'Send',
                      enabled: widget.loading || canSend,
                      onPressed: widget.loading ? widget.onStop : _submit,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: BeuiCurves.easeOut,
                        switchOutCurve: BeuiCurves.easeOut,
                        transitionBuilder: (child, anim) {
                          return FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(
                              scale: Tween(begin: 0.7, end: 1.0).animate(anim),
                              child: child,
                            ),
                          );
                        },
                        child: BeuiIcon(
                          widget.loading
                              ? BeuiIcons.square
                              : BeuiIcons.arrowRight,
                          key: ValueKey(widget.loading),
                          color: colors.primaryForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModelChip extends StatefulWidget {
  const _ModelChip({
    required this.models,
    required this.value,
    required this.onChanged,
  });

  final List<BeuiPromptModel> models;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_ModelChip> createState() => _ModelChipState();
}

class _ModelChipState extends State<_ModelChip> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    BeuiPromptModel current = widget.models.first;
    for (final model in widget.models) {
      if (model.value == widget.value) current = model;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Text(
                  current.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.mutedForeground,
                  ),
                ),
                BeuiIcon(
                  BeuiIcons.chevronDown,
                  size: 14,
                  color: colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          ...widget.models.map(
            (m) => GestureDetector(
              onTap: m.enabled
                  ? () {
                      setState(() => _open = false);
                      widget.onChanged(m.value);
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  m.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: m.value == widget.value
                        ? colors.foreground
                        : colors.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
