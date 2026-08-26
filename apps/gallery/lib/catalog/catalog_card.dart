import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

import '../demo_registry.dart';
import 'catalog.dart';
import 'preview_fit.dart';

/// Landing-style catalog tile: live preview well + title + description.
class CatalogCard extends StatefulWidget {
  const CatalogCard({
    super.key,
    required this.entry,
    required this.onOpen,
  });

  final CatalogEntry entry;
  final VoidCallback? onOpen;

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
  bool _hover = false;

  void _setHover(bool value) {
    if (_hover == value) return;
    _hover = value;
    beuiAfterPointer(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final live = widget.entry.implemented && demoBuilders[widget.entry.key] != null;
    final preview = demoBuilders[widget.entry.key];

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: BeuiCurves.easeOut,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hover ? colors.borderStrong : colors.border,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: live
                        ? CatalogPreviewFit(
                            hover: _hover,
                            child: preview!(),
                          )
                        : ColoredBox(
                            color: colors.background,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  widget.entry.description.isEmpty
                                      ? widget.entry.key
                                      : widget.entry.description,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: colors.foreground,
                            ),
                          ),
                          if (widget.entry.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                widget.entry.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _hover ? 1 : 0,
                      child: BeuiIcon(
                        BeuiIcons.arrowUpRight,
                        size: 16,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
