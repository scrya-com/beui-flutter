import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/ease.dart';

/// Shared transform-only reveal for collapsible agent content.
/// Port of `AgentDisclosure`.
class BeuiAgentDisclosure extends StatelessWidget {
  const BeuiAgentDisclosure({
    super.key,
    required this.open,
    required this.child,
  });

  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = beuiReduceMotion(context);
    return ClipRect(
      child: IgnorePointer(
        ignoring: !open,
        child: ExcludeSemantics(
          excluding: !open,
          child: AnimatedSize(
            duration: Duration(milliseconds: reduce ? 0 : (open ? 220 : 140)),
            curve: BeuiCurves.easeOut,
            alignment: Alignment.topCenter,
            child: open
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: reduce ? 1 : 0, end: 1),
                    duration: Duration(milliseconds: reduce ? 0 : 220),
                    curve: BeuiCurves.easeOut,
                    builder: (context, t, child) {
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, reduce ? 0 : -4 * (1 - t)),
                          child: child,
                        ),
                      );
                    },
                    child: child,
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ),
      ),
    );
  }
}
