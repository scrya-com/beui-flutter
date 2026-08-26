import 'package:flutter/widgets.dart';

import '../../motion/pop_in.dart';
import '../../motion/reduce.dart';
import '../../motion/spring_motion.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

enum BeuiMessageBubbleVariant { solid, soft, tint, outline, ghost, danger }

enum BeuiMessageAlign { start, end }

/// Port of `MessageBubble` / `MessageBubbleContent` / `MessageBubbleGroup`.
class BeuiMessageBubble extends StatelessWidget {
  const BeuiMessageBubble({
    super.key,
    required this.child,
    this.variant = BeuiMessageBubbleVariant.soft,
    this.align = BeuiMessageAlign.start,
    this.animateIn = false,
  });

  final Widget child;
  final BeuiMessageBubbleVariant variant;
  final BeuiMessageAlign align;
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: align == BeuiMessageAlign.end
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: BeuiMessageBubbleContent(
        variant: variant,
        align: align,
        animateIn: animateIn,
        child: child,
      ),
    );
  }
}

class BeuiMessageBubbleContent extends StatelessWidget {
  const BeuiMessageBubbleContent({
    super.key,
    required this.child,
    this.variant = BeuiMessageBubbleVariant.soft,
    this.align = BeuiMessageAlign.start,
    this.animateIn = false,
  });

  final Widget child;
  final BeuiMessageBubbleVariant variant;
  final BeuiMessageAlign align;
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final (Color? bg, Color fg, BoxBorder? border) = switch (variant) {
      BeuiMessageBubbleVariant.solid => (
          colors.foreground,
          colors.background,
          null,
        ),
      BeuiMessageBubbleVariant.soft => (colors.muted, colors.foreground, null),
      BeuiMessageBubbleVariant.tint => (
          colors.primary.withValues(alpha: 0.10),
          colors.foreground,
          null,
        ),
      BeuiMessageBubbleVariant.outline => (
          colors.background,
          colors.foreground,
          Border.all(color: colors.border.withValues(alpha: 0.7)),
        ),
      BeuiMessageBubbleVariant.ghost => (null, colors.foreground, null),
      BeuiMessageBubbleVariant.danger => (
          colors.destructive.withValues(alpha: 0.10),
          colors.destructive,
          null,
        ),
    };

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: variant == BeuiMessageBubbleVariant.ghost
            ? double.infinity
            : MediaQuery.sizeOf(context).width * 0.82,
        minWidth: variant == BeuiMessageBubbleVariant.ghost ? 0 : 36,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: variant == BeuiMessageBubbleVariant.ghost
              ? BorderRadius.zero
              : BorderRadius.circular(16),
        ),
        child: Padding(
          padding: variant == BeuiMessageBubbleVariant.ghost
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: fg,
            ),
            child: child,
          ),
        ),
      ),
    );

    return BeuiPopIn(
      enabled: animateIn && !reduce,
      spec: const BeuiSpringSpec(stiffness: 520, damping: 27, mass: 0.52),
      alignment: align == BeuiMessageAlign.end
          ? Alignment.bottomRight
          : Alignment.bottomLeft,
      fromScale: 0.92,
      child: bubble,
    );
  }
}

class BeuiMessageBubbleGroup extends StatelessWidget {
  const BeuiMessageBubbleGroup({
    super.key,
    required this.children,
    this.spacing = 12,
    this.compact = false,
  });

  final List<Widget> children;
  final double spacing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: compact ? 6 : spacing,
      children: children,
    );
  }
}

class BeuiMessageBubbleCollapsible extends StatefulWidget {
  const BeuiMessageBubbleCollapsible({
    super.key,
    required this.child,
    this.open,
    this.initialOpen = false,
    this.onOpenChanged,
    this.collapsedHeight = 88,
    this.moreLabel = 'Show more',
    this.lessLabel = 'Show less',
  });

  final Widget child;
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChanged;
  final double collapsedHeight;
  final String moreLabel;
  final String lessLabel;

  @override
  State<BeuiMessageBubbleCollapsible> createState() =>
      _BeuiMessageBubbleCollapsibleState();
}

class _BeuiMessageBubbleCollapsibleState
    extends State<BeuiMessageBubbleCollapsible> {
  late bool _internal;

  bool get _controlled => widget.open != null;
  bool get _open => _controlled ? widget.open! : _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialOpen;
  }

  void _toggle() {
    final next = !_open;
    if (!_controlled) setState(() => _internal = next);
    widget.onOpenChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: BeuiCurves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? widget.child
                : ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF000000), Color(0x00000000)],
                        stops: [0.68, 1],
                      ).createShader(rect);
                    },
                    child: SizedBox(
                      height: widget.collapsedHeight,
                      child: widget.child,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Text(
                  _open ? widget.lessLabel : widget.moreLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.mutedForeground,
                  ),
                ),
                BeuiSpringBuilder(
                  value: _open ? 1 : 0,
                  spec: BeuiSpringSpec.swap,
                  builder: (context, t) {
                    return Transform.rotate(
                      angle: t * 3.14159,
                      child: BeuiIcon(
                        BeuiIcons.chevronDown,
                        size: 14,
                        color: colors.mutedForeground,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
