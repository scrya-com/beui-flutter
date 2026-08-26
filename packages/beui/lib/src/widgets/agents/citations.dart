import 'package:flutter/widgets.dart';

import '../../favicon.dart';
import '../../motion/hover.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import 'disclosure.dart';

class BeuiCitationItem {
  const BeuiCitationItem({
    required this.id,
    required this.title,
    this.domain,
    this.url,
  });

  final String id;
  final String title;
  final String? domain;
  final String? url;
}

/// Inline numbered marker. Port of `Citation`.
class BeuiCitation extends StatelessWidget {
  const BeuiCitation({
    super.key,
    required this.index,
    this.semanticLabel,
  });

  final int index;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Semantics(
      label: semanticLabel ?? 'View citation $index',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Transform.translate(
          offset: const Offset(0, -2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.muted.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  color: colors.mutedForeground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Site favicon with a globe fallback. Port of `CitationFavicon`.
class BeuiCitationFavicon extends StatefulWidget {
  const BeuiCitationFavicon({
    super.key,
    this.url,
    this.size = 20,
  });

  final String? url;
  final double size;

  @override
  State<BeuiCitationFavicon> createState() => _BeuiCitationFaviconState();
}

class _BeuiCitationFaviconState extends State<BeuiCitationFavicon> {
  late List<String> _srcs;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _srcs = _resolve(widget.url);
  }

  @override
  void didUpdateWidget(BeuiCitationFavicon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _srcs = _resolve(widget.url);
      _index = 0;
    }
  }

  List<String> _resolve(String? url) {
    final primary = beuiFaviconUrl(url);
    final fallback = beuiFaviconFallbackUrl(url);
    return [
      ?primary,
      if (fallback != primary) ?fallback,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final box = widget.size;
    final glyph = BeuiIcon(
      BeuiIcons.globe,
      size: widget.size * 0.7,
      color: colors.mutedForeground,
    );
    final src = _index < _srcs.length ? _srcs[_index] : null;
    return SizedBox(
      width: box,
      height: box,
      child: Center(
        child: src == null
            ? glyph
            : ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Image.network(
                  src,
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stack) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (_index < _srcs.length - 1) {
                        setState(() => _index += 1);
                      }
                    });
                    if (_index >= _srcs.length - 1) return glyph;
                    return const SizedBox.shrink();
                  },
                ),
              ),
      ),
    );
  }
}

/// Overlapping favicon pile. Port of `CitationStack`.
class BeuiCitationStack extends StatelessWidget {
  const BeuiCitationStack({
    super.key,
    required this.citations,
    this.limit = 3,
  });

  final List<BeuiCitationItem> citations;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final items = citations.take(limit).toList();
    return SizedBox(
      width: items.isEmpty ? 0 : 24 + (items.length - 1) * 18.0,
      height: 24,
      child: Stack(
        children: [
          for (var i = 0; i < items.length; i++)
            Positioned(
              left: i * 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.background, width: 2),
                ),
                child: BeuiCitationFavicon(url: items[i].url, size: 24),
              ),
            ),
        ],
      ),
    );
  }
}

/// Collapsible citation collection. Port of `Citations`.
class BeuiCitations extends StatefulWidget {
  const BeuiCitations({
    super.key,
    required this.citations,
    this.title = 'Sources',
    this.open,
    this.initialOpen = false,
    this.onOpenChanged,
    this.onOpenUrl,
  });

  final List<BeuiCitationItem> citations;
  final String title;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;
  final ValueChanged<String>? onOpenUrl;

  @override
  State<BeuiCitations> createState() => _BeuiCitationsState();
}

class _BeuiCitationsState extends State<BeuiCitations> {
  late bool _internal;

  bool get _controlled => widget.open != null;
  bool get _open => _controlled ? widget.open! : _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialOpen;
  }

  void _setOpen(bool next) {
    if (!_controlled) setState(() => _internal = next);
    widget.onOpenChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _setOpen(!_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                BeuiIcon(
                  BeuiIcons.book,
                  size: 16,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: BorderRadius.circular(BeuiRadii.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      '${widget.citations.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BeuiSpringBuilder(
                  value: _open ? 1 : 0,
                  spec: BeuiSpringSpec.swap,
                  builder: (context, t) {
                    return Transform.rotate(
                      angle: t * 3.14159,
                      child: BeuiIcon(
                        BeuiIcons.chevronDown,
                        size: 14,
                        color: colors.mutedForeground.withValues(alpha: 0.6),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        BeuiAgentDisclosure(
          open: _open,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                for (var i = 0; i < widget.citations.length; i++)
                  _CitationEnter(
                    key: ValueKey(widget.citations[i].id),
                    child: _CitationRow(
                      index: i + 1,
                      item: widget.citations[i],
                      onOpenUrl: widget.onOpenUrl,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Mount enter: opacity 180ms EASE_OUT, y 6px on SPRING_LAYOUT.
class _CitationEnter extends StatefulWidget {
  const _CitationEnter({super.key, required this.child});

  final Widget child;

  @override
  State<_CitationEnter> createState() => _CitationEnterState();
}

class _CitationEnterState extends State<_CitationEnter>
    with TickerProviderStateMixin {
  late final BeuiSpringValue _y;
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _y = BeuiSpringValue(value: 0, spec: BeuiSpringSpec.layout)..attach(this);
    _y.addListener(_onTick);
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = beuiReduceMotion(context);
    _y.reducedMotion = reduce;
    if (reduce) {
      _y.jump(1);
      _fade.value = 1;
      return;
    }
    if (TickerMode.valuesOf(context).enabled &&
        _y.value == 0 &&
        !_y.isAnimating) {
      _y.animateTo(1);
      _fade.forward();
    }
  }

  @override
  void dispose() {
    _y
      ..removeListener(_onTick)
      ..dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _y.value;
    final opacity = beuiReduceMotion(context)
        ? 1.0
        : BeuiCurves.easeOut.transform(_fade.value.clamp(0.0, 1.0));
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, 6 * (1 - t)),
        child: widget.child,
      ),
    );
  }
}

class _CitationRow extends StatefulWidget {
  const _CitationRow({
    required this.index,
    required this.item,
    this.onOpenUrl,
  });

  final int index;
  final BeuiCitationItem item;
  final ValueChanged<String>? onOpenUrl;

  @override
  State<_CitationRow> createState() => _CitationRowState();
}

class _CitationRowState extends State<_CitationRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final item = widget.item;
    final hover = _hover && beuiHoverCapable(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          BeuiCitationFavicon(url: item.url),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 2,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: hover
                        ? colors.foreground
                        : colors.foreground.withValues(alpha: 0.8),
                  ),
                ),
                if (item.domain != null)
                  Text(
                    item.domain!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.mutedForeground.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.foreground.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: Text(
                  '${widget.index}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
          if (item.url != null) ...[
            const SizedBox(width: 6),
            BeuiIcon(
              BeuiIcons.externalLink,
              size: 14,
              color: hover
                  ? colors.mutedForeground
                  : colors.mutedForeground.withValues(alpha: 0.4),
            ),
          ],
        ],
      ),
    );

    return MouseRegion(
      cursor: item.url != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => beuiAfterPointer(() {
        if (mounted) setState(() => _hover = true);
      }),
      onExit: (_) => beuiAfterPointer(() {
        if (mounted) setState(() => _hover = false);
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: item.url == null
            ? null
            : () => widget.onOpenUrl?.call(item.url!),
        child: row,
      ),
    );
  }
}
