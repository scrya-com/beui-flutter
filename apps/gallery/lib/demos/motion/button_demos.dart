import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

Widget gapChildren(List<Widget> children, {double gap = 8}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    spacing: gap,
    children: children,
  );
}

class ButtonBaseDemo extends StatelessWidget {
  const ButtonBaseDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 24,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            BeuiButton(
              onPressed: () {},
              child: gapChildren([
                const Text('Continue'),
                const BeuiIcon(BeuiIcons.arrowRight),
              ]),
            ),
            BeuiButton(
              variant: BeuiButtonVariant.secondary,
              onPressed: () {},
              child: gapChildren([
                const BeuiIcon(BeuiIcons.download),
                const Text('Download'),
              ]),
            ),
            BeuiButton(
              variant: BeuiButtonVariant.outline,
              onPressed: () {},
              child: const Text('Outline'),
            ),
            BeuiButton(
              variant: BeuiButtonVariant.ghost,
              onPressed: () {},
              child: const Text('Ghost'),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            BeuiButton(
              size: BeuiButtonSize.sm,
              onPressed: () {},
              child: const Text('Small'),
            ),
            BeuiButton(
              onPressed: () {},
              child: const Text('Medium'),
            ),
            BeuiButton(
              size: BeuiButtonSize.lg,
              onPressed: () {},
              child: const Text('Large'),
            ),
            BeuiButton(
              variant: BeuiButtonVariant.secondary,
              size: BeuiButtonSize.icon,
              semanticLabel: 'Delete',
              onPressed: () {},
              child: const BeuiIcon(BeuiIcons.trash),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            BeuiButton(
              ripple: true,
              onPressed: () {},
              child: const Text('Ripple'),
            ),
            BeuiButton(
              variant: BeuiButtonVariant.outline,
              ripple: true,
              onPressed: () {},
              child: const Text('Tap me'),
            ),
          ],
        ),
      ],
    );
  }
}

class ButtonStatefulDemo extends StatefulWidget {
  const ButtonStatefulDemo({super.key});

  @override
  State<ButtonStatefulDemo> createState() => _ButtonStatefulDemoState();
}

class _ButtonStatefulDemoState extends State<ButtonStatefulDemo> {
  BeuiButtonState ok = BeuiButtonState.idle;
  BeuiButtonState err = BeuiButtonState.idle;

  void _run(String target) {
    final setter = target == 'ok'
        ? (BeuiButtonState s) => setState(() => ok = s)
        : (BeuiButtonState s) => setState(() => err = s);
    setter(BeuiButtonState.loading);
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      setter(target == 'ok' ? BeuiButtonState.success : BeuiButtonState.error);
      Future<void>.delayed(const Duration(milliseconds: 1800), () {
        setter(BeuiButtonState.idle);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        BeuiStatefulButton(
          state: ok,
          label: 'Save changes',
          loadingText: 'Saving',
          successText: 'Saved',
          idleIcon: const BeuiIcon(BeuiIcons.arrowRight),
          onPressed: () => _run('ok'),
        ),
        BeuiStatefulButton(
          state: err,
          label: 'Submit',
          variant: BeuiButtonVariant.secondary,
          loadingText: 'Submitting',
          errorText: 'Failed',
          onPressed: () => _run('err'),
        ),
      ],
    );
  }
}

class ButtonMagneticDemo extends StatelessWidget {
  const ButtonMagneticDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        BeuiMagneticButton(
          strength: 0.35,
          onPressed: () {},
          child: gapChildren([
            const Text('Hover me'),
            const BeuiIcon(BeuiIcons.arrowRight),
          ]),
        ),
        BeuiMagneticButton(
          variant: BeuiButtonVariant.secondary,
          strength: 0.25,
          onPressed: () {},
          child: const Text('Subtle pull'),
        ),
        BeuiMagneticButton(
          variant: BeuiButtonVariant.outline,
          strength: 0.5,
          onPressed: () {},
          child: const Text('Strong pull'),
        ),
      ],
    );
  }
}

class ButtonMetallicDemo extends StatelessWidget {
  const ButtonMetallicDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        BeuiMetallicButton(
          onPressed: () {},
          child: gapChildren([
            const Text('Continue'),
            const BeuiIcon(BeuiIcons.arrowUpRight, color: Color(0xFFF5F5F5)),
          ]),
        ),
        BeuiMetallicButton(
          size: BeuiButtonSize.sm,
          onPressed: () {},
          child: gapChildren([
            const BeuiIcon(BeuiIcons.sparkles, size: 14, color: Color(0xFFF5F5F5)),
            const Text('Generate'),
          ], gap: 6),
        ),
        BeuiMetallicButton(
          size: BeuiButtonSize.icon,
          semanticLabel: 'Magic tools',
          onPressed: () {},
          child: const BeuiIcon(BeuiIcons.sparkles, color: Color(0xFFF5F5F5)),
        ),
      ],
    );
  }
}
