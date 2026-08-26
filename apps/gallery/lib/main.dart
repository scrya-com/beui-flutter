import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalog/catalog.dart';
import 'demo_registry.dart';

void main() {
  runApp(const BeuiGalleryApp());
}

/// Dark-only gallery. Matches beUI's dark tokens (`#151515` / `#1C1C1C`).
class BeuiGalleryApp extends StatefulWidget {
  const BeuiGalleryApp({super.key});

  @override
  State<BeuiGalleryApp> createState() => _BeuiGalleryAppState();
}

class _BeuiGalleryAppState extends State<BeuiGalleryApp> {
  BeuiColorTheme colorTheme = BeuiColorTheme.mono;
  String category = 'motion';
  String? selectedKey;
  bool showRemaining = false;

  @override
  Widget build(BuildContext context) {
    const brightness = Brightness.dark;
    final colors = BeuiColors.resolve(
      brightness: brightness,
      theme: colorTheme,
    );
    return BeuiPointerScope(
      child: BeuiTheme.wrap(
        brightness: brightness,
        colorTheme: colorTheme,
        child: WidgetsApp(
          color: colors.background,
          debugShowCheckedModeBanner: false,
          pageRouteBuilder: <T>(settings, builder) {
            return PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, _) => builder(context),
            );
          },
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(platformBrightness: Brightness.dark),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: ColoredBox(
            color: colors.background,
            child: DefaultTextStyle(
              style: TextStyle(
                color: colors.foreground,
                fontSize: 14,
              ),
              child: selectedKey == null
                  ? _CatalogPage(
                      category: category,
                      colorTheme: colorTheme,
                      showRemaining: showRemaining,
                      onCategory: (v) => setState(() => category = v),
                      onSelect: (k) => setState(() => selectedKey = k),
                      onColorTheme: (t) => setState(() => colorTheme = t),
                      onToggleRemaining: () =>
                          setState(() => showRemaining = !showRemaining),
                    )
                  : _DemoPage(
                      entry: catalog.firstWhere((e) => e.key == selectedKey),
                      onBack: () => setState(() => selectedKey = null),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogPage extends StatelessWidget {
  const _CatalogPage({
    required this.category,
    required this.colorTheme,
    required this.showRemaining,
    required this.onCategory,
    required this.onSelect,
    required this.onColorTheme,
    required this.onToggleRemaining,
  });

  final String category;
  final BeuiColorTheme colorTheme;
  final bool showRemaining;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onSelect;
  final ValueChanged<BeuiColorTheme> onColorTheme;
  final VoidCallback onToggleRemaining;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final live = catalogFor(category, liveOnly: true);
    final rest = catalogFor(category, liveOnly: false)
        .where((e) => !e.implemented)
        .toList();
    final items = showRemaining ? [...live, ...rest] : live;
    final done = live.length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'beUI for Flutter',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$done live in this category · ${catalog.where((e) => e.implemented).length} / ${catalog.length} catalog',
              style: TextStyle(fontSize: 12, color: colors.mutedForeground),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              spacing: 8,
              children: [
                for (final c in const ['motion', 'agents', 'blocks'])
                  _Chip(
                    label: switch (c) {
                      'motion' => 'Components',
                      'agents' => 'AI Agents',
                      _ => 'Blocks',
                    },
                    selected: category == c,
                    onTap: () => onCategory(c),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final t in BeuiColorTheme.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      label: t.label,
                      selected: colorTheme == t,
                      onTap: () => onColorTheme(t),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: items.length + (rest.isEmpty ? 0 : 1),
              itemBuilder: (context, i) {
                if (i == items.length) {
                  return GestureDetector(
                    onTap: onToggleRemaining,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        showRemaining
                            ? 'Hide remaining (${rest.length})'
                            : 'Show remaining ${rest.length} not ported yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                  );
                }
                final e = items[i];
                final liveItem = e.implemented;
                return GestureDetector(
                  onTap: liveItem ? () => onSelect(e.key) : null,
                  child: Opacity(
                    opacity: liveItem ? 1 : 0.45,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(BeuiRadii.card),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2,
                              children: [
                                Text(
                                  e.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: colors.foreground,
                                  ),
                                ),
                                Text(
                                  e.key,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (liveItem)
                            Text(
                              'Live',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.success,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoPage extends StatelessWidget {
  const _DemoPage({required this.entry, required this.onBack});

  final CatalogEntry entry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final builder = demoBuilders[entry.key];
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Back',
                      style: TextStyle(color: colors.mutedForeground),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    launchUrl(Uri.parse(entry.reactUrl));
                  },
                  child: Text(
                    'React ↗',
                    style: TextStyle(color: colors.accent),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: colors.background,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: builder?.call() ??
                      Text(
                        'Not ported yet.\n${entry.key}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.mutedForeground),
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.card,
          borderRadius: BorderRadius.circular(BeuiRadii.pill),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? colors.primaryForeground : colors.foreground,
          ),
        ),
      ),
    );
  }
}
