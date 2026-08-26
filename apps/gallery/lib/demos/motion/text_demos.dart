import 'dart:math' as math;

import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

class TextRevealDemo extends StatefulWidget {
  const TextRevealDemo({super.key});

  @override
  State<TextRevealDemo> createState() => _TextRevealDemoState();
}

class _TextRevealDemoState extends State<TextRevealDemo> {
  int _key = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 32,
      children: [
        KeyedSubtree(
          key: ValueKey(_key),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              BeuiTextReveal(
                text: const ['Motion that feels', 'considered.'],
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  height: 0.95,
                  letterSpacing: 36 * -0.04,
                ),
              ),
              BeuiTextReveal(
                text: const ['Word by word, with a soft blur.'],
                delay: 0.9,
                stagger: 0.05,
                blur: 6,
                yOffset: 0.2,
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        BeuiButton(
          variant: BeuiButtonVariant.secondary,
          size: BeuiButtonSize.sm,
          onPressed: () => setState(() => _key++),
          child: const Text('Replay'),
        ),
      ],
    );
  }
}

class TextScrambleDemo extends StatefulWidget {
  const TextScrambleDemo({super.key});

  @override
  State<TextScrambleDemo> createState() => _TextScrambleDemoState();
}

class _TextScrambleDemoState extends State<TextScrambleDemo> {
  static const _phrases = [
    'Inspecting the repository',
    'Running the checks',
    'Preparing the update',
  ];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 32,
      children: [
        BeuiTextScramble(
          text: _phrases[_index],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: context.beuiColors.foreground,
          ),
        ),
        BeuiButton(
          variant: BeuiButtonVariant.secondary,
          size: BeuiButtonSize.sm,
          onPressed: () =>
              setState(() => _index = (_index + 1) % _phrases.length),
          child: const Text('Next phrase'),
        ),
      ],
    );
  }
}

class ChromaticTextRevealDemo extends StatelessWidget {
  const ChromaticTextRevealDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return BeuiChromaticTextReveal(
      prefix: 'Motion that feels',
      words: const ['natural.', 'intentional.', 'alive.'],
      startOnView: false,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        letterSpacing: 28 * -0.04,
        color: context.beuiColors.foreground,
      ),
    );
  }
}

class TextCascadeDemo extends StatefulWidget {
  const TextCascadeDemo({super.key});

  @override
  State<TextCascadeDemo> createState() => _TextCascadeDemoState();
}

class _TextCascadeDemoState extends State<TextCascadeDemo>
    with SingleTickerProviderStateMixin {
  static const _phrases = ['Install skills', 'Open settings', 'Ship updates'];
  int _index = 0;
  late final AnimationController _cycle;

  @override
  void initState() {
    super.initState();
    _cycle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() => _index = (_index + 1) % _phrases.length);
        _cycle.forward(from: 0);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled && !_cycle.isAnimating) {
      _cycle.forward();
    } else if (!TickerMode.valuesOf(context).enabled && _cycle.isAnimating) {
      _cycle.stop();
    }
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BeuiTextCascade(
      text: _phrases[_index],
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: context.beuiColors.foreground,
      ),
    );
  }
}

class TextShimmerDemo extends StatelessWidget {
  const TextShimmerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        BeuiTextShimmer(
          text: 'Loading projects…',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: context.beuiColors.foreground,
          ),
        ),
        const BeuiTextShimmer(
          text: 'Faster shimmer',
          duration: Duration(milliseconds: 1500),
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class NumberTickerDemo extends StatefulWidget {
  const NumberTickerDemo({super.key});

  @override
  State<NumberTickerDemo> createState() => _NumberTickerDemoState();
}

class _NumberTickerDemoState extends State<NumberTickerDemo>
    with SingleTickerProviderStateMixin {
  int _value = 48273;
  final _rng = math.Random();
  late final AnimationController _cycle;

  @override
  void initState() {
    super.initState();
    _cycle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() => _value += _rng.nextInt(50));
        _cycle.forward(from: 0);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled && !_cycle.isAnimating) {
      _cycle.forward();
    } else if (!TickerMode.valuesOf(context).enabled && _cycle.isAnimating) {
      _cycle.stop();
    }
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Text(
          'Active users',
          style: TextStyle(fontSize: 12, color: colors.mutedForeground),
        ),
        BeuiNumberTicker(
          value: _value,
          locale: true,
          startOnView: false,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: colors.foreground,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'live · updates every 2.5s',
          style: TextStyle(fontSize: 12, color: colors.mutedForeground),
        ),
      ],
    );
  }
}

class AnimatedNumberDemo extends StatelessWidget {
  const AnimatedNumberDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Text(
          'Monthly recurring revenue',
          style: TextStyle(fontSize: 12, color: colors.mutedForeground),
        ),
        BeuiAnimatedNumber(
          value: 129480,
          startOnView: false,
          format: (n) => '\$${_group(n.round())}',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: colors.foreground,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          '+12.4% vs last month',
          style: TextStyle(fontSize: 12, color: colors.success),
        ),
      ],
    );
  }
}

class ActionSwapBlurDemo extends StatefulWidget {
  const ActionSwapBlurDemo({super.key});

  @override
  State<ActionSwapBlurDemo> createState() => _ActionSwapBlurDemoState();
}

class _ActionSwapBlurDemoState extends State<ActionSwapBlurDemo> {
  String _text = 'copy';
  String _icon = 'light';
  String _cta = 'copy';

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        BeuiActionSwapBlurButton(
          items: const [
            BeuiActionSwapItem(id: 'copy', label: 'Copy'),
            BeuiActionSwapItem(id: 'copied', label: 'Copied'),
          ],
          value: _text,
          onChanged: (v) => setState(() => _text = v),
        ),
        BeuiActionSwapBlurButton(
          items: const [
            BeuiActionSwapItem(
              id: 'light',
              label: 'Light',
              icon: BeuiIcon(_sun),
              semanticLabel: 'Use light theme',
            ),
            BeuiActionSwapItem(
              id: 'dark',
              label: 'Dark',
              icon: BeuiIcon(_moon),
              semanticLabel: 'Use dark theme',
            ),
          ],
          value: _icon,
          onChanged: (v) => setState(() => _icon = v),
          variant: BeuiButtonVariant.outline,
          size: BeuiButtonSize.icon,
          iconOnly: true,
        ),
        BeuiActionSwapBlurButton(
          items: const [
            BeuiActionSwapItem(
              id: 'copy',
              label: 'Copy link',
              icon: BeuiIcon(BeuiIcons.copy),
              semanticLabel: 'Copy link',
            ),
            BeuiActionSwapItem(
              id: 'copied',
              label: 'Copied',
              icon: BeuiIcon(BeuiIcons.check),
              semanticLabel: 'Copied',
            ),
          ],
          value: _cta,
          onChanged: (v) => setState(() => _cta = v),
          variant: BeuiButtonVariant.primary,
        ),
      ],
    );
  }
}

class ActionSwapRollDemo extends StatefulWidget {
  const ActionSwapRollDemo({super.key});

  @override
  State<ActionSwapRollDemo> createState() => _ActionSwapRollDemoState();
}

class _ActionSwapRollDemoState extends State<ActionSwapRollDemo> {
  String _text = 'idle';
  String _icon = 'light';
  String _cta = 'send';

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        BeuiActionSwapRollButton(
          items: const [
            BeuiActionSwapItem(id: 'idle', label: 'Save'),
            BeuiActionSwapItem(id: 'done', label: 'Saved'),
          ],
          value: _text,
          onChanged: (v) => setState(() => _text = v),
        ),
        BeuiActionSwapRollButton(
          items: const [
            BeuiActionSwapItem(
              id: 'light',
              label: 'Light',
              icon: BeuiIcon(_sun),
              semanticLabel: 'Use light theme',
            ),
            BeuiActionSwapItem(
              id: 'dark',
              label: 'Dark',
              icon: BeuiIcon(_moon),
              semanticLabel: 'Use dark theme',
            ),
          ],
          value: _icon,
          onChanged: (v) => setState(() => _icon = v),
          variant: BeuiButtonVariant.outline,
          size: BeuiButtonSize.icon,
          iconOnly: true,
        ),
        BeuiActionSwapRollButton(
          items: const [
            BeuiActionSwapItem(
              id: 'send',
              label: 'Send invite',
              icon: BeuiIcon(_send),
              semanticLabel: 'Send invite',
            ),
            BeuiActionSwapItem(
              id: 'sent',
              label: 'Invite sent',
              icon: BeuiIcon(BeuiIcons.sparkles),
              semanticLabel: 'Invite sent',
            ),
          ],
          value: _cta,
          onChanged: (v) => setState(() => _cta = v),
          variant: BeuiButtonVariant.primary,
        ),
      ],
    );
  }
}

class ActionSwapCascadeDemo extends StatelessWidget {
  const ActionSwapCascadeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const BeuiActionSwapCascadeButton(
      items: [
        BeuiActionSwapItem(
          id: 'copy',
          label: 'Copy link',
          icon: BeuiIcon(BeuiIcons.copy),
          semanticLabel: 'Copy link',
        ),
        BeuiActionSwapItem(
          id: 'copied',
          label: 'Copied!',
          icon: BeuiIcon(BeuiIcons.check),
          semanticLabel: 'Copied',
        ),
      ],
      variant: BeuiButtonVariant.primary,
    );
  }
}

void _sun(Canvas c, Size s, Paint p) {
  c.drawCircle(const Offset(12, 12), 4, p);
  c.drawLine(const Offset(12, 2), const Offset(12, 4), p);
  c.drawLine(const Offset(12, 20), const Offset(12, 22), p);
  c.drawLine(const Offset(4.93, 4.93), const Offset(6.34, 6.34), p);
  c.drawLine(const Offset(17.66, 17.66), const Offset(19.07, 19.07), p);
  c.drawLine(const Offset(2, 12), const Offset(4, 12), p);
  c.drawLine(const Offset(20, 12), const Offset(22, 12), p);
  c.drawLine(const Offset(6.34, 17.66), const Offset(4.93, 19.07), p);
  c.drawLine(const Offset(19.07, 4.93), const Offset(17.66, 6.34), p);
}

void _moon(Canvas c, Size s, Paint p) {
  c.drawPath(
    Path()
      ..moveTo(12, 3)
      ..cubicTo(16, 5, 19, 9, 19, 14)
      ..cubicTo(19, 16, 18.5, 18, 17, 19.5)
      ..cubicTo(13, 22, 7, 20, 5, 15)
      ..cubicTo(3, 10, 6, 4, 12, 3)
      ..close(),
    p,
  );
}

void _send(Canvas c, Size s, Paint p) {
  c.drawPath(
    Path()
      ..moveTo(22, 2)
      ..lineTo(11, 13)
      ..moveTo(22, 2)
      ..lineTo(15, 22)
      ..lineTo(11, 13)
      ..lineTo(2, 9)
      ..close(),
    p,
  );
}

String _group(int value) {
  final digits = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}
