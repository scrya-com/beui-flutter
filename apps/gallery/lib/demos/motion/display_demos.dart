import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

/// Port of `TooltipPreview`.
class TooltipDemo extends StatelessWidget {
  const TooltipDemo({super.key});

  static const _items = <(String, String, BeuiTooltipSide, BeuiIconPainter)>[
    ('Like this post', 'Like this post', BeuiTooltipSide.top, BeuiIcons.thumbsUp),
    ('Share', 'Share', BeuiTooltipSide.bottom, BeuiIcons.arrowUpRight),
    ('Open settings', 'Open settings', BeuiTooltipSide.left, BeuiIcons.settings),
    ('Move to trash', 'Move to trash', BeuiTooltipSide.right, BeuiIcons.trash),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 48,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            for (final item in _items)
              BeuiTooltip(
                content: Text(item.$1),
                side: item.$3,
                semanticLabel: item.$2,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Semantics(
                    button: true,
                    label: item.$2,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border),
                        ),
                        child: Center(
                          child: BeuiIcon(
                            item.$4,
                            size: 16,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Text(
          'Hover or focus each button. Content fades and un-blurs in.',
          style: TextStyle(fontSize: 12, color: colors.mutedForeground),
        ),
      ],
    );
  }
}

/// Port of `MarqueePreview`.
class MarqueeDemo extends StatelessWidget {
  const MarqueeDemo({super.key});

  static const logos = [
    'Vercel',
    'Linear',
    'Stripe',
    'Figma',
    'GitHub',
    'Notion',
    'Loom',
    'Raycast',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return BeuiMarquee(
      speed: 25,
      children: [
        for (final name in logos)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(BeuiRadii.md),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: SizedBox(
                  height: 24,
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Port of `AnimatedBadgePreview`.
class AnimatedBadgeDemo extends StatefulWidget {
  const AnimatedBadgeDemo({super.key});

  @override
  State<AnimatedBadgeDemo> createState() => _AnimatedBadgeDemoState();
}

class _AnimatedBadgeDemoState extends State<AnimatedBadgeDemo>
    with SingleTickerProviderStateMixin {
  static const _states = <(BeuiAnimatedBadgeStatus, String)>[
    (BeuiAnimatedBadgeStatus.loading, 'Syncing'),
    (BeuiAnimatedBadgeStatus.success, 'Synced'),
    (BeuiAnimatedBadgeStatus.warning, 'Review'),
    (BeuiAnimatedBadgeStatus.danger, 'Failed'),
  ];

  late final AnimationController _cycle;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _cycle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() => _active = (_active + 1) % _states.length);
        _cycle.forward(from: 0);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled && !_cycle.isAnimating) {
      _cycle.forward();
    }
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _states[_active];
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 24,
      children: [
        SizedBox(
          height: 64,
          child: Center(
            child: BeuiAnimatedBadge(
              status: state.$1,
              size: BeuiAnimatedBadgeSize.md,
              label: state.$2,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            BeuiAnimatedBadge(
              status: BeuiAnimatedBadgeStatus.neutral,
              size: BeuiAnimatedBadgeSize.sm,
              label: 'Queued',
            ),
            BeuiAnimatedBadge(
              status: BeuiAnimatedBadgeStatus.info,
              size: BeuiAnimatedBadgeSize.sm,
              label: 'Live',
            ),
            BeuiAnimatedBadge(
              status: BeuiAnimatedBadgeStatus.loading,
              size: BeuiAnimatedBadgeSize.sm,
              label: 'Indexing',
            ),
            BeuiAnimatedBadge(
              status: BeuiAnimatedBadgeStatus.success,
              size: BeuiAnimatedBadgeSize.sm,
              label: 'Verified',
            ),
            BeuiAnimatedBadge(
              status: BeuiAnimatedBadgeStatus.warning,
              size: BeuiAnimatedBadgeSize.sm,
              label: 'Pending',
            ),
            BeuiAnimatedBadge(
              status: BeuiAnimatedBadgeStatus.danger,
              size: BeuiAnimatedBadgeSize.sm,
              label: 'Blocked',
            ),
          ],
        ),
      ],
    );
  }
}

/// Port of `LoaderPreview`.
class LoaderDemo extends StatelessWidget {
  const LoaderDemo({super.key});

  static const _variants = <(BeuiLoaderVariant, String)>[
    (BeuiLoaderVariant.spinner, 'Spinner'),
    (BeuiLoaderVariant.dots, 'Dots'),
    (BeuiLoaderVariant.bars, 'Bars'),
    (BeuiLoaderVariant.dotMatrix, 'Dot Matrix'),
    (BeuiLoaderVariant.dither, 'Dither'),
    (BeuiLoaderVariant.morph, 'Morph'),
    (BeuiLoaderVariant.comet, 'Comet'),
    (BeuiLoaderVariant.metaballs, 'Metaballs'),
    (BeuiLoaderVariant.newton, 'Newton'),
    (BeuiLoaderVariant.helix, 'Helix'),
    (BeuiLoaderVariant.scramble, 'Scramble'),
    (BeuiLoaderVariant.percent, 'Percent'),
    (BeuiLoaderVariant.ascii, 'ASCII'),
    (BeuiLoaderVariant.asciiLine, 'ASCII Line'),
    (BeuiLoaderVariant.asciiBraille, 'ASCII Braille'),
    (BeuiLoaderVariant.asciiBlocks, 'ASCII Blocks'),
    (BeuiLoaderVariant.asciiBounce, 'ASCII Bounce'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Wrap(
        spacing: 32,
        runSpacing: 32,
        alignment: WrapAlignment.center,
        children: [
          for (final item in _variants)
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                BeuiLoader(variant: item.$1, size: 36),
                Text(
                  item.$2,
                  style: TextStyle(fontSize: 12, color: colors.mutedForeground),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
