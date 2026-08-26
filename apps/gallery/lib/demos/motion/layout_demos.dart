import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

class ExpandableControlDemo extends StatelessWidget {
  const ExpandableControlDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 24,
      children: [
        BeuiExpandableButton(
          icon: BeuiIcon(BeuiIcons.sparkles, color: colors.foreground),
          label: 'Notifications',
        ),
        BeuiExpandableChip(
          label: 'React',
          actionIcon: BeuiIcon(BeuiIcons.x, color: colors.mutedForeground),
          actionLabel: 'Remove React',
        ),
      ],
    );
  }
}

class TiltCardDemo extends StatelessWidget {
  const TiltCardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return BeuiTiltCard(
      child: SizedBox(
        width: 280,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.8,
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tilt me',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Move your cursor across the card to see 3D tilt + glare.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SharedLayoutBgDemo extends StatelessWidget {
  const SharedLayoutBgDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const items = <(String, String)>[
      ('Inbox', '12 unread threads, 3 mentions today.'),
      ('Drafts', '4 posts waiting for a final pass.'),
      ('Releases', 'Last shipped 2 days ago, v0.4.1.'),
      ('Billing', 'Plan renews on the 1st of next month.'),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 512),
      child: BeuiSharedLayoutBg(
        items: [
          for (final item in items)
            BeuiSharedLayoutItem(
              id: item.$1,
              child: _SharedRow(title: item.$1, body: item.$2),
            ),
        ],
      ),
    );
  }
}

class _SharedRow extends StatefulWidget {
  const _SharedRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  State<_SharedRow> createState() => _SharedRowState();
}

class _SharedRowState extends State<_SharedRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return MouseRegion(
      onEnter: (_) {
        _hover = true;
        beuiAfterPointer(() {
          if (mounted) setState(() {});
        });
      },
      onExit: (_) {
        _hover = false;
        beuiAfterPointer(() {
          if (mounted) setState(() {});
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.foreground,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: _hover ? const Offset(2, -2) : Offset.zero,
                  child: BeuiIcon(
                    BeuiIcons.arrowUpRight,
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
            Text(
              widget.body,
              style: TextStyle(
                fontSize: 14,
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BouncyAccordionDemo extends StatelessWidget {
  const BouncyAccordionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    Widget icon(BeuiIconPainter painter) => BeuiIcon(
          painter,
          size: 16,
          color: colors.mutedForeground,
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 384),
      child: SizedBox(
        height: 480,
        child: BeuiBouncyAccordion(
          initialValue: 'calendar',
          items: [
            BeuiBouncyAccordionItem(
              id: 'brief',
              title: 'Release Brief',
              description:
                  'Collect launch notes, owners, and risks in one compact handoff before the release window opens.',
              icon: icon(BeuiIcons.fileText),
            ),
            BeuiBouncyAccordionItem(
              id: 'launch',
              title: 'Launch Checklist',
              description:
                  'Verify copy, links, analytics, rollback steps, and final approvals without leaving the queue.',
              icon: icon(BeuiIcons.shieldCheck),
            ),
            BeuiBouncyAccordionItem(
              id: 'campaign',
              title: 'Campaign Notes',
              description:
                  'Keep channel-specific notes close to the task while preserving a calm collapsed list.',
              icon: icon(BeuiIcons.globe),
            ),
            BeuiBouncyAccordionItem(
              id: 'calendar',
              title: 'Rollout Calendar',
              description:
                  'Plan announcements, staging checks, reminders, and quiet periods around the same timeline.',
              icon: icon(BeuiIcons.book),
            ),
            BeuiBouncyAccordionItem(
              id: 'ship',
              title: 'Ship Build',
              description:
                  'Track the current artifact, deploy status, and final sign-off before marking the release complete.',
              icon: icon(BeuiIcons.circleCheck),
            ),
            BeuiBouncyAccordionItem(
              id: 'archive',
              title: 'Archive Assets',
              description:
                  'Move final copy, images, and source files into the campaign folder once the rollout is done.',
              icon: icon(BeuiIcons.file),
            ),
          ],
        ),
      ),
    );
  }
}

class DockDemo extends StatefulWidget {
  const DockDemo({super.key});

  @override
  State<DockDemo> createState() => _DockDemoState();
}

class _DockDemoState extends State<DockDemo> {
  String _active = 'home';

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    Widget icon(BeuiIconPainter painter) => BeuiIcon(
          painter,
          size: 20,
          color: colors.foreground,
        );

    return BeuiDock(
      children: [
        BeuiDockItem(
          semanticLabel: 'Home',
          active: _active == 'home',
          onPressed: () => setState(() => _active = 'home'),
          child: icon(BeuiIcons.globe),
        ),
        BeuiDockItem(
          semanticLabel: 'Mail',
          active: _active == 'mail',
          onPressed: () => setState(() => _active = 'mail'),
          child: icon(BeuiIcons.mail),
        ),
        BeuiDockItem(
          semanticLabel: 'Calendar',
          active: _active == 'calendar',
          onPressed: () => setState(() => _active = 'calendar'),
          child: icon(BeuiIcons.book),
        ),
        BeuiDockItem(
          semanticLabel: 'Music',
          active: _active == 'music',
          onPressed: () => setState(() => _active = 'music'),
          child: icon(BeuiIcons.play),
        ),
        BeuiDockItem(
          semanticLabel: 'Discover',
          active: _active == 'discover',
          onPressed: () => setState(() => _active = 'discover'),
          child: icon(BeuiIcons.sparkles),
        ),
        const BeuiDockSeparator(),
        BeuiDockItem(
          semanticLabel: 'Settings',
          active: _active == 'settings',
          onPressed: () => setState(() => _active = 'settings'),
          child: icon(BeuiIcons.settings),
        ),
        BeuiDockItem(
          semanticLabel: 'GitHub',
          child: icon(BeuiIcons.code),
        ),
      ],
    );
  }
}
