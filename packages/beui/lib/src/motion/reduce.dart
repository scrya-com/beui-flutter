import 'package:flutter/widgets.dart';

/// True when the user asked for reduced motion (`prefers-reduced-motion`).
///
/// Keep opacity / color. Drop transform travel, scale, blur, magnetic, tilt.
bool beuiReduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);
