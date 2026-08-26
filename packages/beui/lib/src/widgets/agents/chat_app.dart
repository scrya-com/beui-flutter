import 'package:flutter/widgets.dart';

import '../../tokens/theme.dart';

const beuiChatAppMinDockedWidth = 600.0;

/// Agent workspace shell. Port of `components/agents/chat-app.tsx`.
///
/// Folds [sidebar] off-canvas when the shell is narrower than
/// [collapseBelow] unless [sidebarOpen] is controlled.
class BeuiChatApp extends StatefulWidget {
  const BeuiChatApp({
    super.key,
    required this.sidebar,
    required this.child,
    this.sidebarWidth = 272,
    this.collapseBelow = beuiChatAppMinDockedWidth,
    this.sidebarOpen,
    this.onSidebarOpenChanged,
    this.initialSidebarOpen = true,
  });

  final Widget sidebar;
  final Widget child;
  final double sidebarWidth;
  final double collapseBelow;
  final bool? sidebarOpen;
  final ValueChanged<bool>? onSidebarOpenChanged;
  final bool initialSidebarOpen;

  @override
  State<BeuiChatApp> createState() => _BeuiChatAppState();
}

class _BeuiChatAppState extends State<BeuiChatApp> {
  late bool _internalOpen;
  bool? _narrow;

  bool get _controlled => widget.sidebarOpen != null;
  bool get _open => _controlled ? widget.sidebarOpen! : _internalOpen;

  @override
  void initState() {
    super.initState();
    _internalOpen = widget.initialSidebarOpen;
  }

  void _setOpen(bool next) {
    if (_open == next) return;
    if (!_controlled) setState(() => _internalOpen = next);
    widget.onSidebarOpenChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final narrow = width < widget.collapseBelow && width.isFinite;
        if (!_controlled) {
          if (_narrow == null) {
            _narrow = narrow;
            if (narrow) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _setOpen(false);
              });
            }
          } else if (_narrow != narrow) {
            _narrow = narrow;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _setOpen(!narrow);
            });
          }
        }

        final docked = !narrow && _open;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                if (docked)
                  SizedBox(
                    width: widget.sidebarWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: colors.border),
                        ),
                      ),
                      child: widget.sidebar,
                    ),
                  ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        );
      },
    );
  }
}
