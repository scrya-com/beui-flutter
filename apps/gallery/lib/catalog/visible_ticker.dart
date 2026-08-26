import 'package:flutter/widgets.dart';

/// Gallery-only: run [child] tickers only while this box intersects the window.
///
/// Catalog cards mount full demos. Leaving them ticking off-screen blocks
/// the UI thread (Chrome long tasks > 50ms while scrolling). Do not use this
/// on the opened demo page or in product UI.
class VisibleTicker extends StatefulWidget {
  const VisibleTicker({super.key, required this.child});

  final Widget child;

  @override
  State<VisibleTicker> createState() => _VisibleTickerState();
}

class _VisibleTickerState extends State<VisibleTicker> {
  bool _visible = true;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _position) {
      _position?.removeListener(_check);
      _position = next;
      _position?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screen = MediaQuery.sizeOf(context);
    const pad = 64.0;
    final vis =
        origin.dy < screen.height + pad && origin.dy + size.height > -pad;
    if (vis != _visible) setState(() => _visible = vis);
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: _visible,
      child: RepaintBoundary(child: widget.child),
    );
  }
}
