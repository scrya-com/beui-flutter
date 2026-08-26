import 'package:beui/beui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalog/catalog.dart';
import 'catalog/catalog_card.dart';
import 'demo_registry.dart';

void main() {
  runApp(const BeuiGalleryApp());
}

class BeuiGalleryApp extends StatefulWidget {
  const BeuiGalleryApp({super.key});

  @override
  State<BeuiGalleryApp> createState() => _BeuiGalleryAppState();
}

class _BeuiGalleryAppState extends State<BeuiGalleryApp> {
  BeuiColorTheme colorTheme = BeuiColorTheme.mono;
  String category = 'agents';
  String? selectedKey;

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
                height: 1.45,
              ),
              child: BeuiKeyboardAvoid(
                child: Column(
                  children: [
                    _SiteHeader(
                      category: category,
                      colorTheme: colorTheme,
                      onCategory: (v) => setState(() {
                        category = v;
                        selectedKey = null;
                      }),
                      onColorTheme: (t) => setState(() => colorTheme = t),
                    ),
                    Expanded(
                      child: NotificationListener<UserScrollNotification>(
                        onNotification: (n) {
                          if (n.direction != ScrollDirection.idle) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          }
                          return false;
                        },
                        child: selectedKey == null
                            ? _CatalogBody(
                                category: category,
                                onSelect: (k) => setState(() => selectedKey = k),
                              )
                            : _DemoPage(
                                entry: catalog.firstWhere((e) => e.key == selectedKey),
                                category: category,
                                onBack: () => setState(() => selectedKey = null),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SiteHeader extends StatelessWidget {
  const _SiteHeader({
    required this.category,
    required this.colorTheme,
    required this.onCategory,
    required this.onColorTheme,
  });

  final String category;
  final BeuiColorTheme colorTheme;
  final ValueChanged<String> onCategory;
  final ValueChanged<BeuiColorTheme> onColorTheme;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final tab = switch (category) {
      'blocks' => 'blocks',
      'agents' => 'agents',
      _ => 'components',
    };
    return ColoredBox(
      color: colors.background.withValues(alpha: 0.7),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const _Mark(),
                const SizedBox(width: 10),
                Text(
                  'beUI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        BeuiTabs(
                          value: tab,
                          onChanged: (v) => onCategory(switch (v) {
                            'blocks' => 'blocks',
                            'agents' => 'agents',
                            _ => 'motion',
                          }),
                          child: const BeuiTabsList(
                            children: [
                              BeuiTabsTrigger(
                                value: 'components',
                                child: Text('Components'),
                              ),
                              BeuiTabsTrigger(
                                value: 'agents',
                                child: Text('Agents'),
                              ),
                              BeuiTabsTrigger(
                                value: 'blocks',
                                child: Text('Blocks'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        for (final theme in BeuiColorTheme.values)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _Swatch(
                              theme: theme,
                              selected: colorTheme == theme,
                              onTap: () => onColorTheme(theme),
                            ),
                          ),
                      ],
                    ),
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

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        'assets/beui-mark.png',
        width: 24,
        height: 24,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, _, _) {
          return ColoredBox(
            color: context.beuiColors.foreground,
            child: const SizedBox(width: 24, height: 24),
          );
        },
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final BeuiColorTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sample = BeuiColors.resolve(
      brightness: Brightness.dark,
      theme: theme,
    );
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: sample.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? context.beuiColors.foreground : sample.borderStrong,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class _CatalogBody extends StatelessWidget {
  const _CatalogBody({
    required this.category,
    required this.onSelect,
  });

  final String category;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final copy = categoryCopy[category]!;
    final live = catalogFor(category, liveOnly: true);
    final label = switch (category) {
      'blocks' => 'Blocks',
      'agents' => 'AI Agents',
      _ => 'Components',
    };

    final sections = <(String, String, List<CatalogEntry>)>[];
    if (category == 'agents') {
      for (final group in agentGroups) {
        final items = live.where((e) => _inGroup(e, group)).toList();
        if (items.isEmpty) continue;
        sections.add((group.title, group.description, items));
      }
      final used = sections.expand((s) => s.$3.map((e) => e.key)).toSet();
      final leftover = live.where((e) => !used.contains(e.key)).toList();
      if (leftover.isNotEmpty) {
        sections.add(('Also live', '', leftover));
      }
    } else {
      sections.add(('', '', live));
    }

    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(160),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          sliver: SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    copy.heading,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      letterSpacing: -0.6,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Text(
                      copy.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (final section in sections) ...[
          if (section.$1.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
              sliver: SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.$1,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: colors.foreground,
                        ),
                      ),
                      if (section.$2.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          section.$2,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 1200
                    ? 4
                    : width >= 900
                        ? 3
                        : width >= 600
                            ? 2
                            : 1;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 304,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final entry = section.$3[i];
                      return CatalogCard(
                        entry: entry,
                        onOpen: entry.implemented ? () => onSelect(entry.key) : null,
                      );
                    },
                    childCount: section.$3.length,
                    addAutomaticKeepAlives: false,
                  ),
                );
              },
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

bool _inGroup(CatalogEntry entry, CatalogGroup group) {
  for (final slug in group.slugs) {
    if (entry.slug == slug || entry.slug.startsWith('$slug-')) return true;
  }
  return false;
}

class _DemoPage extends StatefulWidget {
  const _DemoPage({
    required this.entry,
    required this.category,
    required this.onBack,
  });

  final CatalogEntry entry;
  final String category;
  final VoidCallback onBack;

  @override
  State<_DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<_DemoPage> {
  int _run = 0;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final category = widget.category;
    final colors = context.beuiColors;
    final builder = demoBuilders[entry.key];
    final catLabel = switch (category) {
      'blocks' => 'Blocks',
      'agents' => 'AI Agents',
      _ => 'Components',
    };
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onBack,
                      child: Text(
                        catLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '/',
                        style: TextStyle(color: colors.mutedForeground),
                      ),
                    ),
                    Text(
                      entry.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.foreground,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(entry.reactUrl)),
                      child: Text(
                        'React ↗',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                    color: colors.foreground,
                  ),
                ),
                if (entry.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Text(
                      entry.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ColoredBox(
                        color: colors.background,
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 48,
                              ),
                              child: Center(
                                child: KeyedSubtree(
                                  key: ValueKey(_run),
                                  child: builder?.call() ?? const SizedBox(),
                                ),
                              ),
                            ),
                            if (category == 'agents')
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => setState(() => _run++),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      spacing: 6,
                                      children: [
                                        BeuiIcon(
                                          BeuiIcons.rotateCcw,
                                          size: 12,
                                          color: colors.mutedForeground,
                                        ),
                                        Text(
                                          'Replay',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
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
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
