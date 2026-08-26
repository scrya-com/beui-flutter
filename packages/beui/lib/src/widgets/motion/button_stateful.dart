import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../physics/spring.dart';
import '../../tokens/ease.dart';
import '../icons.dart';
import 'button.dart';

enum BeuiButtonState { idle, loading, success, error }

/// Idle → loading → success / error with blur-swap slots and morphing width.
/// Port of `components/motion/button/stateful.tsx`.
class BeuiStatefulButton extends StatelessWidget {
  const BeuiStatefulButton({
    super.key,
    required this.label,
    required this.state,
    this.onPressed,
    this.loadingText = 'Loading',
    this.successText = 'Done',
    this.errorText = 'Try again',
    this.idleIcon,
    this.variant = BeuiButtonVariant.primary,
    this.size = BeuiButtonSize.md,
    this.enabled = true,
  });

  final String label;
  final BeuiButtonState state;
  final VoidCallback? onPressed;
  final String loadingText;
  final String successText;
  final String errorText;
  final Widget? idleIcon;
  final BeuiButtonVariant variant;
  final BeuiButtonSize size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = switch (state) {
      BeuiButtonState.idle => label,
      BeuiButtonState.loading => loadingText,
      BeuiButtonState.success => successText,
      BeuiButtonState.error => errorText,
    };
    return BeuiButton(
      onPressed: onPressed,
      variant: variant,
      size: size,
      enabled: enabled && state != BeuiButtonState.loading,
      busy: state == BeuiButtonState.loading,
      child: _SwapRow(
        state: state,
        text: text,
        idleIcon: idleIcon,
      ),
    );
  }
}

class _SwapRow extends StatelessWidget {
  const _SwapRow({
    required this.state,
    required this.text,
    this.idleIcon,
  });

  final BeuiButtonState state;
  final String text;
  final Widget? idleIcon;

  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      BeuiButtonState.loading => const _Spin(child: BeuiIcon(BeuiIcons.loader, size: 16)),
      BeuiButtonState.success => const BeuiIcon(BeuiIcons.check, size: 16),
      BeuiButtonState.error => const BeuiIcon(BeuiIcons.x, size: 16),
      BeuiButtonState.idle => idleIcon,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        ?icon,
        _CascadeText(text: text, stateKey: state.name),
      ],
    );
  }
}

class _CascadeText extends StatelessWidget {
  const _CascadeText({required this.text, required this.stateKey});

  final String text;
  final String stateKey;

  @override
  Widget build(BuildContext context) {
    final reduce = beuiReduceMotion(context);
    if (reduce) return Text(text);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < text.length; i++)
          _Letter(
            key: ValueKey('$stateKey-$i-${text[i]}'),
            char: text[i],
            delay: Duration(milliseconds: (i * 25).round()),
          ),
      ],
    );
  }
}

class _Letter extends StatefulWidget {
  const _Letter({
    super.key,
    required this.char,
    required this.delay,
  });

  final String char;
  final Duration delay;

  @override
  State<_Letter> createState() => _LetterState();
}

class _LetterState extends State<_Letter> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = beuiSpringEaseSpec(_c.value * 0.45, BeuiSpringSpec.swap);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: Text(widget.char == ' ' ? '\u00A0' : widget.char),
          ),
        );
      },
    );
  }
}

class _Spin extends StatefulWidget {
  const _Spin({required this.child});
  final Widget child;

  @override
  State<_Spin> createState() => _SpinState();
}

class _SpinState extends State<_Spin> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(turns: _c, child: widget.child);
  }
}
