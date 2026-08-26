import 'dart:async';

import 'package:beui/beui.dart';

import 'package:flutter/widgets.dart';

class SelectDemo extends StatefulWidget {
  const SelectDemo({super.key});

  @override
  State<SelectDemo> createState() => _SelectDemoState();
}

class _SelectDemoState extends State<SelectDemo> {
  String value = 'next';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 224,
      child: BeuiSelect(
        value: value,
        onChanged: (v) => setState(() => value = v),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BeuiSelectTrigger(
              child: BeuiSelectValue(placeholder: 'Pick a framework'),
            ),
            BeuiSelectContent(
              children: [
                BeuiSelectItem(value: 'next', child: Text('Next.js')),
                BeuiSelectItem(value: 'remix', child: Text('Remix')),
                BeuiSelectItem(value: 'astro', child: Text('Astro')),
                BeuiSelectItem(value: 'vite', child: Text('Vite')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Workspace {
  const _Workspace({
    required this.value,
    required this.label,
    required this.detail,
    required this.group,
    required this.icon,
    required this.tint,
    required this.ink,
  });

  final String value;
  final String label;
  final String detail;
  final String group;
  final BeuiIconPainter icon;
  final Color tint;
  final Color ink;
}

const _workspaces = [
  _Workspace(
    value: 'studio',
    label: 'Design studio',
    detail: '12 projects',
    group: 'Recent',
    icon: BeuiIcons.sparkles,
    tint: Color(0x33FBBF24),
    ink: Color(0xFFFCD34D),
  ),
  _Workspace(
    value: 'product',
    label: 'Product team',
    detail: '8 projects',
    group: 'Recent',
    icon: BeuiIcons.listTodo,
    tint: Color(0x3338BDF8),
    ink: Color(0xFF7DD3FC),
  ),
  _Workspace(
    value: 'playground',
    label: 'Playground',
    detail: '24 experiments',
    group: 'Workspaces',
    icon: BeuiIcons.square,
    tint: Color(0x3334D399),
    ink: Color(0xFF6EE7B7),
  ),
  _Workspace(
    value: 'archive',
    label: 'Component archive',
    detail: '41 components',
    group: 'Workspaces',
    icon: BeuiIcons.fileCode,
    tint: Color(0x33FB7185),
    ink: Color(0xFFFDA4AF),
  ),
];

class ComboboxDemo extends StatefulWidget {
  const ComboboxDemo({super.key});

  @override
  State<ComboboxDemo> createState() => _ComboboxDemoState();
}

class _ComboboxDemoState extends State<ComboboxDemo> {
  String value = 'studio';

  @override
  Widget build(BuildContext context) {
    final muted = context.beuiColors.mutedForeground;
    const groups = ['Recent', 'Workspaces'];
    return SizedBox(
      width: 288,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Workspace',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
          ),
          BeuiCombobox(
            value: value,
            onChanged: (v) => setState(() => value = v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BeuiComboboxTrigger(
                  child: BeuiComboboxInput(
                    semanticLabel: 'Search workspaces',
                    placeholder: 'Search workspaces…',
                  ),
                ),
                BeuiComboboxContent(
                  child: BeuiComboboxList(
                    semanticLabel: 'Workspaces',
                    children: [
                      const BeuiComboboxEmpty(
                        child: Text('No workspaces found.'),
                      ),
                      for (var g = 0; g < groups.length; g++)
                        BeuiComboboxGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (g > 0) const BeuiComboboxSeparator(),
                              BeuiComboboxLabel(child: Text(groups[g])),
                              for (final workspace in _workspaces
                                  .where((w) => w.group == groups[g]))
                                BeuiComboboxItem(
                                  value: workspace.value,
                                  textValue: workspace.label,
                                  keywords: [workspace.detail, workspace.group],
                                  child: Row(
                                    children: [
                                      _WorkspaceMark(workspace: workspace),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              workspace.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: context
                                                    .beuiColors.foreground,
                                              ),
                                            ),
                                            Text(
                                              workspace.detail,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceMark extends StatelessWidget {
  const _WorkspaceMark({required this.workspace});

  final _Workspace workspace;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: workspace.tint,
        borderRadius: BorderRadius.circular(BeuiRadii.md),
      ),
      alignment: Alignment.center,
      child: BeuiIcon(workspace.icon, size: 14, color: workspace.ink),
    );
  }
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

final _years = [for (var i = 0; i < 60; i++) '${1980 + i}'];

int _daysIn(int monthIndex, int year) {
  const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  final leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  if (monthIndex == 1 && leap) return 29;
  return lengths[monthIndex];
}

class WheelPickerDemo extends StatefulWidget {
  const WheelPickerDemo({super.key});

  @override
  State<WheelPickerDemo> createState() => _WheelPickerDemoState();
}

class _WheelPickerDemoState extends State<WheelPickerDemo> {
  String month = 'June';
  String year = '2004';
  String day = '9';
  bool sound = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final monthIndex = _months.indexOf(month);
    final dayCount = _daysIn(monthIndex < 0 ? 0 : monthIndex, int.parse(year));
    final days = [for (var i = 1; i <= dayCount; i++) '$i'];
    final dayValue = int.parse(day) > dayCount ? '$dayCount' : day;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 14, color: colors.mutedForeground),
            children: [
              const TextSpan(text: 'Born '),
              TextSpan(
                text: '$month $dayValue, $year',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: colors.foreground,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 128,
                  child: BeuiWheelPicker(
                    options: [
                      for (final m in _months)
                        BeuiWheelPickerOption(value: m),
                    ],
                    value: month,
                    onChanged: (v) => setState(() => month = v),
                    visibleCount: 7,
                    itemHeight: 42,
                    sound: sound,
                    framed: false,
                    semanticLabel: 'Month',
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: BeuiWheelPicker(
                    options: [
                      for (final d in days) BeuiWheelPickerOption(value: d),
                    ],
                    value: dayValue,
                    onChanged: (v) => setState(() => day = v),
                    visibleCount: 7,
                    itemHeight: 42,
                    sound: sound,
                    framed: false,
                    semanticLabel: 'Day',
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: BeuiWheelPicker(
                    options: [
                      for (final y in _years)
                        BeuiWheelPickerOption(value: y),
                    ],
                    value: year,
                    onChanged: (v) => setState(() => year = v),
                    visibleCount: 7,
                    itemHeight: 42,
                    sound: sound,
                    framed: false,
                    semanticLabel: 'Year',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Transform.scale(
          alignment: Alignment.centerLeft,
          scale: 0.85,
          child: BeuiSwitch(
            value: sound,
            onChanged: (v) => setState(() => sound = v),
            label: 'Tick sound',
          ),
        ),
      ],
    );
  }
}

class _Update {
  const _Update({
    required this.id,
    required this.icon,
    required this.title,
    required this.detail,
    required this.time,
  });

  final Object id;
  final BeuiIconPainter icon;
  final String title;
  final String detail;
  final String time;
}

const _initialUpdates = [
  _Update(
    id: 1,
    icon: BeuiIcons.code,
    title: 'Motion review approved',
    detail: 'The pull request is ready to merge.',
    time: '4m',
  ),
  _Update(
    id: 2,
    icon: BeuiIcons.messageSquare,
    title: 'New component feedback',
    detail: 'The spring feels much closer to native now.',
    time: '18m',
  ),
  _Update(
    id: 3,
    icon: BeuiIcons.circleCheck,
    title: 'Registry checks passed',
    detail: 'All component files resolved successfully.',
    time: '31m',
  ),
  _Update(
    id: 4,
    icon: BeuiIcons.sparkles,
    title: 'Preview deployed',
    detail: 'The latest build is ready to inspect.',
    time: '1h',
  ),
  _Update(
    id: 5,
    icon: BeuiIcons.messageSquare,
    title: 'Docs comment resolved',
    detail: 'The usage example now covers async refreshes.',
    time: '2h',
  ),
];

class PullToRefreshDemo extends StatefulWidget {
  const PullToRefreshDemo({super.key});

  @override
  State<PullToRefreshDemo> createState() => _PullToRefreshDemoState();
}

class _PullToRefreshDemoState extends State<PullToRefreshDemo>
    with SingleTickerProviderStateMixin {
  int refreshCount = 0;
  _Update? latest;
  late final AnimationController _wait;

  @override
  void initState() {
    super.initState();
    _wait = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _wait.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    final done = Completer<void>();
    _wait.forward(from: 0).whenComplete(() {
      if (!mounted) {
        done.complete();
        return;
      }
      setState(() {
        refreshCount += 1;
        latest = _Update(
          id: DateTime.now().millisecondsSinceEpoch,
          icon: BeuiIcons.sparkles,
          title: 'You’re all caught up',
          detail: 'The activity feed was refreshed just now.',
          time: 'now',
        );
      });
      done.complete();
    });
    return done.future;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final updates = [?latest, ..._initialUpdates];

    return SizedBox(
      width: 384,
      height: 480,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D000000),
              blurRadius: 40,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BeuiPullToRefresh(
            semanticLabel: 'Activity feed',
            onRefresh: _refresh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(
                  color: colors.background.withValues(alpha: 0.9),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Activity',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.foreground,
                                ),
                              ),
                              Text(
                                'Pull down to check for updates',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.muted,
                            borderRadius: BorderRadius.circular(BeuiRadii.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              refreshCount == 0
                                  ? 'live'
                                  : '$refreshCount refreshed',
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: colors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final update in updates) _UpdateRow(update: update),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({required this.update});

  final _Update update;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: BeuiIcon(
                  update.icon,
                  size: 16,
                  color: colors.mutedForeground,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        update.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    Text(
                      update.time,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  update.detail,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
