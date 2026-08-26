import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

class SwitchDemo extends StatefulWidget {
  const SwitchDemo({super.key});

  @override
  State<SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<SwitchDemo> {
  bool on = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        BeuiSwitch(
          value: on,
          onChanged: (v) => setState(() => on = v),
          label: 'Enable notifications',
        ),
        const BeuiSwitch(value: false, label: 'Off'),
        const BeuiSwitch(value: true, enabled: false, label: 'Disabled'),
      ],
    );
  }
}

class CheckboxDemo extends StatefulWidget {
  const CheckboxDemo({super.key});

  @override
  State<CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<CheckboxDemo> {
  bool terms = true;
  bool updates = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        BeuiCheckbox(
          value: terms,
          onChanged: (v) => setState(() => terms = v),
          label: 'Accept terms and conditions',
        ),
        BeuiCheckbox(
          value: updates,
          onChanged: (v) => setState(() => updates = v),
          label: 'Email me product updates',
        ),
        BeuiCheckbox(
          value: true,
          indeterminate: true,
          onChanged: (_) {},
          label: 'Select all (partial)',
        ),
        BeuiCheckbox(
          value: true,
          enabled: false,
          onChanged: (_) {},
          label: 'Disabled',
        ),
      ],
    );
  }
}

class RadioDemo extends StatefulWidget {
  const RadioDemo({super.key});

  @override
  State<RadioDemo> createState() => _RadioDemoState();
}

class _RadioDemoState extends State<RadioDemo> {
  String plan = 'pro';

  @override
  Widget build(BuildContext context) {
    return BeuiRadioGroup(
      value: plan,
      onChanged: (v) => setState(() => plan = v),
      children: const [
        BeuiRadio(value: 'starter', label: 'Starter — free'),
        BeuiRadio(value: 'pro', label: 'Pro — \$12/mo'),
        BeuiRadio(value: 'team', label: 'Team — \$29/mo'),
        BeuiRadio(value: 'legacy', label: 'Legacy plan', enabled: false),
      ],
    );
  }
}

class InputDemo extends StatefulWidget {
  const InputDemo({super.key});

  @override
  State<InputDemo> createState() => _InputDemoState();
}

class _InputDemoState extends State<InputDemo> {
  String email = '';
  String pass = 'hunter2';
  String query = 'Ada';
  bool show = false;

  @override
  Widget build(BuildContext context) {
    final emailError =
        email.isNotEmpty && !email.contains('@') ? 'Enter a valid email address.' : null;
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 20,
        children: [
          BeuiInput(
            label: 'Email',
            placeholder: 'you@example.com',
            value: email,
            onChanged: (v) => setState(() => email = v),
            error: emailError,
            leftIcon: const BeuiIcon(BeuiIcons.mail),
            keyboardType: TextInputType.emailAddress,
          ),
          BeuiInput(
            label: 'Password',
            value: pass,
            onChanged: (v) => setState(() => pass = v),
            obscureText: !show,
            rightIcon: GestureDetector(
              onTap: () => setState(() => show = !show),
              child: BeuiIcon(show ? BeuiIcons.eyeOff : BeuiIcons.eye),
            ),
          ),
          BeuiInput(
            label: 'Search',
            value: query,
            onChanged: (v) => setState(() => query = v),
            leftIcon: const BeuiIcon(BeuiIcons.search),
            success: query.length > 1,
          ),
        ],
      ),
    );
  }
}

class TabsDemo extends StatelessWidget {
  const TabsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = context.beuiColors.mutedForeground;
    Widget section(String title, Widget child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: muted,
            ),
          ),
          child,
        ],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 448),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 32,
        children: [
          section(
            'Pill',
            const BeuiTabs(
              initialValue: 'overview',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BeuiTabsList(
                    children: [
                      BeuiTabsTrigger(value: 'overview', child: Text('Overview')),
                      BeuiTabsTrigger(value: 'activity', child: Text('Activity')),
                      BeuiTabsTrigger(value: 'settings', child: Text('Settings')),
                    ],
                  ),
                  BeuiTabsContent(value: 'overview', child: Text('High-level summary.')),
                  BeuiTabsContent(value: 'activity', child: Text('Recent events.')),
                  BeuiTabsContent(value: 'settings', child: Text('Preferences.')),
                ],
              ),
            ),
          ),
          section(
            'Segment',
            const BeuiTabs(
              initialValue: 'day',
              variant: BeuiTabsVariant.segment,
              child: BeuiTabsList(
                children: [
                  BeuiTabsTrigger(value: 'day', child: Text('Day')),
                  BeuiTabsTrigger(value: 'week', child: Text('Week')),
                  BeuiTabsTrigger(value: 'month', child: Text('Month')),
                ],
              ),
            ),
          ),
          section(
            'Underline',
            const BeuiTabs(
              initialValue: 'all',
              variant: BeuiTabsVariant.underline,
              child: BeuiTabsList(
                children: [
                  BeuiTabsTrigger(value: 'all', child: Text('All')),
                  BeuiTabsTrigger(value: 'open', child: Text('Open')),
                  BeuiTabsTrigger(value: 'closed', child: Text('Closed')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
