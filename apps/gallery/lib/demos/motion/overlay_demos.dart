import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

class ThemeToggleDemo extends StatelessWidget {
  const ThemeToggleDemo({super.key});

  static const _variants = <(BeuiThemeToggleVariant, String)>[
    (BeuiThemeToggleVariant.rectangle, 'Rectangle'),
    (BeuiThemeToggleVariant.circle, 'Circle'),
    (BeuiThemeToggleVariant.circleBlur, 'Circle blur'),
    (BeuiThemeToggleVariant.blinds, 'Blinds'),
  ];

  @override
  Widget build(BuildContext context) {
    return BeuiThemeToggleScope(
      child: Builder(
        builder: (context) {
          final colors = context.beuiColors;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(BeuiRadii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 20,
                children: [
                  for (final item in _variants)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        BeuiThemeToggle(
                          variant: item.$1,
                          start: BeuiThemeToggleStart.bottomUp,
                        ),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ScrollRevealDemo extends StatelessWidget {
  const ScrollRevealDemo({super.key});

  static const _cards = [
    'Spring slide',
    'Blur in',
    'Staggered by delay',
    'Reveal once',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return SizedBox(
      width: double.infinity,
      height: 320,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(BeuiRadii.card),
          border: Border.all(color: colors.border),
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Scroll ↓',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.mutedForeground),
            ),
            for (var i = 0; i < _cards.length; i++) ...[
              const SizedBox(height: 64),
              BeuiScrollReveal(
                once: false,
                delay: Duration(milliseconds: i * 50),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.muted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(BeuiRadii.lg),
                    border: Border.all(color: colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64),
                    child: Text(
                      _cards[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 64),
            Text(
              'End',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomSheetDemo extends StatefulWidget {
  const BottomSheetDemo({super.key});

  @override
  State<BottomSheetDemo> createState() => _BottomSheetDemoState();
}

class _BottomSheetDemoState extends State<BottomSheetDemo> {
  bool _open = false;

  static const _items = [
    'Share',
    'Duplicate',
    'Move to folder',
    'Rename',
    'Archive',
    'Delete',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BeuiButton(
          variant: BeuiButtonVariant.outline,
          onPressed: () => setState(() => _open = true),
          child: const Text('Open bottom sheet'),
        ),
        BeuiBottomSheet(
          open: _open,
          onOpenChange: (v) => setState(() => _open = v),
          snapPoints: const [0.4, 0.85],
          title: 'Quick actions',
          description: 'Drag the handle, fling, or swipe down to dismiss.',
          child: Column(
            children: [
              for (final item in _items)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.border)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  'Fling up to expand, fling down to dismiss.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.mutedForeground),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DrawerDemo extends StatefulWidget {
  const DrawerDemo({super.key});

  @override
  State<DrawerDemo> createState() => _DrawerDemoState();
}

class _DrawerDemoState extends State<DrawerDemo> {
  bool _open = false;
  BeuiDrawerSide _side = BeuiDrawerSide.right;

  void _openWith(BeuiDrawerSide side) {
    setState(() {
      _side = side;
      _open = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final sideLabel = _side == BeuiDrawerSide.right ? 'right' : 'left';
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        BeuiButton(
          variant: BeuiButtonVariant.outline,
          onPressed: () => _openWith(BeuiDrawerSide.left),
          child: const Text('Open left'),
        ),
        BeuiButton(
          onPressed: () => _openWith(BeuiDrawerSide.right),
          child: const Text('Open right'),
        ),
        BeuiDrawer(
          open: _open,
          onOpenChange: (v) => setState(() => _open = v),
          side: _side,
          semanticLabel: 'Demo drawer',
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Text(
                  'Drawer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                Text(
                  'Slides in from the $sideLabel. Press Esc or click outside to close.',
                  style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ScrollProgressDemo extends StatefulWidget {
  const ScrollProgressDemo({super.key});

  @override
  State<ScrollProgressDemo> createState() => _ScrollProgressDemoState();
}

class _ScrollProgressDemoState extends State<ScrollProgressDemo> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return SizedBox(
      width: double.infinity,
      height: 256,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(BeuiRadii.card),
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BeuiRadii.card),
          child: Stack(
            children: [
              Positioned.fill(
                child: ListView.separated(
                  controller: _controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: 18,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.muted.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(BeuiRadii.md),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        child: Text(
                          'Section ${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: BeuiScrollProgress(controller: _controller, height: 3),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.background.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(BeuiRadii.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: BeuiScrollProgress(
                      variant: BeuiScrollProgressVariant.circle,
                      controller: _controller,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedToastStackDemo extends StatefulWidget {
  const AnimatedToastStackDemo({super.key});

  @override
  State<AnimatedToastStackDemo> createState() => _AnimatedToastStackDemoState();
}

class _AnimatedToastStackDemoState extends State<AnimatedToastStackDemo>
    with TickerProviderStateMixin {
  static const _positions = BeuiToastPosition.values;

  late final BeuiAnimatedToastController _toasts;
  BeuiToastPosition _position = BeuiToastPosition.bottomRight;
  final List<AnimationController> _pending = [];

  @override
  void initState() {
    super.initState();
    _toasts = BeuiAnimatedToastController(
      vsync: this,
      defaultDuration: const Duration(milliseconds: 3600),
      limit: 5,
    )..addListener(_onToasts);
  }

  void _onToasts() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _pending) {
      c.dispose();
    }
    _toasts
      ..removeListener(_onToasts)
      ..dispose();
    super.dispose();
  }

  void _openToast({
    required BeuiToastStatus status,
    required String title,
    required String description,
    Duration? duration,
  }) {
    final id = _toasts.showToast(
      BeuiToastInput(
        status: status,
        title: title,
        description: description,
        duration: duration,
      ),
    );
    if (status != BeuiToastStatus.loading) return;
    final wait = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pending.add(wait);
    wait
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _toasts.updateToast(
            id,
            status: BeuiToastStatus.success,
            title: 'Publish complete',
            description: 'Toast updated in-place from loading to success.',
            duration: const Duration(milliseconds: 3200),
          );
          wait.dispose();
          _pending.remove(wait);
        }
      })
      ..forward();
  }

  void _moveStack(BeuiToastPosition next) {
    setState(() => _position = next);
    _toasts.showToast(
      BeuiToastInput(
        status: BeuiToastStatus.info,
        title: 'Position changed',
        description: 'New toasts open from ${_label(next)}.',
      ),
    );
  }

  String _label(BeuiToastPosition p) {
    return switch (p) {
      BeuiToastPosition.topLeft => 'top-left',
      BeuiToastPosition.topCenter => 'top-center',
      BeuiToastPosition.topRight => 'top-right',
      BeuiToastPosition.bottomLeft => 'bottom-left',
      BeuiToastPosition.bottomCenter => 'bottom-center',
      BeuiToastPosition.bottomRight => 'bottom-right',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Open a real toast',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 384),
                  child: Text(
                    'Toasts render fixed on the screen. Change position to open a toast from that edge.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 20 / 12,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _ToastChip(
                      icon: BeuiIcons.loader,
                      label: 'Promise',
                      onTap: () => _openToast(
                        status: BeuiToastStatus.loading,
                        title: 'Publishing component',
                        description:
                            'Bundling source, preview, and registry metadata.',
                        duration: Duration.zero,
                      ),
                    ),
                    _ToastChip(
                      icon: BeuiIcons.check,
                      label: 'Success',
                      onTap: () => _openToast(
                        status: BeuiToastStatus.success,
                        title: 'Component published',
                        description:
                            'Registry endpoint and raw source are available.',
                      ),
                    ),
                    _ToastChip(
                      icon: BeuiIcons.x,
                      label: 'Error',
                      onTap: () => _openToast(
                        status: BeuiToastStatus.error,
                        title: 'Snapshot failed',
                        description: 'Retry after the browser target settles.',
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toasts.clearToasts,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final pos in _positions)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _moveStack(pos),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: pos == _position
                                ? colors.foreground
                                : colors.foreground.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(BeuiRadii.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              _label(pos),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: pos == _position
                                    ? colors.background
                                    : colors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        BeuiAnimatedToastStack(
          toasts: _toasts.toasts,
          onDismiss: _toasts.dismissToast,
          position: _position,
          placement: BeuiToastPlacement.fixed,
          maxVisible: 4,
          icons: {
            BeuiToastStatus.neutral: BeuiIcon(
              BeuiIcons.sparkles,
              size: 14,
              color: colors.mutedForeground,
            ),
          },
        ),
      ],
    );
  }
}

class _ToastChip extends StatelessWidget {
  const _ToastChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final BeuiIconPainter icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(BeuiRadii.pill),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              BeuiIcon(icon, size: 14, color: colors.foreground),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
