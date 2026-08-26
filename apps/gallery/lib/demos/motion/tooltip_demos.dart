import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

/// Public preview of beUI Pro Morphic Tooltip.
class MorphicTooltipDemo extends StatelessWidget {
  const MorphicTooltipDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    const items = <(String, String, BeuiIconPainter)>[
      ('Think', 'Switch to a deeper reasoning pass', BeuiIcons.settings),
      ('Review', 'Review queued', BeuiIcons.circleCheck),
      ('Code', 'Ask the coding agent to implement the change', BeuiIcons.code),
      ('Message', 'Open the active', BeuiIcons.messageSquare),
    ];

    return BeuiMorphicTooltipScope(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(BeuiRadii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in items)
                    BeuiMorphicTooltip(
                      semanticLabel: item.$1,
                      content: Text(item.$2),
                      child: _ToolbarIcon(icon: item.$3, label: item.$1),
                    ),
                ],
              ),
            ),
          ),
          BeuiMorphicTooltip(
            content: const Text('Hover the toolbar'),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(BeuiRadii.pill),
                border: Border.all(color: colors.border),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Hover the toolbar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarIcon extends StatefulWidget {
  const _ToolbarIcon({required this.icon, required this.label});

  final BeuiIconPainter icon;
  final String label;

  @override
  State<_ToolbarIcon> createState() => _ToolbarIconState();
}

class _ToolbarIconState extends State<_ToolbarIcon> {
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
      child: Semantics(
        button: true,
        label: widget.label,
        child: SizedBox(
          width: 40,
          height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _hover
                  ? colors.primary.withValues(alpha: 0.05)
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(BeuiRadii.card),
            ),
            child: Center(
              child: BeuiIcon(
                widget.icon,
                size: 16,
                color: _hover ? colors.foreground : colors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
