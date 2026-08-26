import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Radii from component usage (beUI has no `--radius` token).
class BeuiRadii {
  BeuiRadii._();

  static const double pill = 999;
  static const double icon = 8;
  static const double md = 8;
  static const double lg = 12;
  static const double card = 16;
  static const double popover = 16;
  static const double sheet = 24;
  static const double island = 32;
}

class BeuiTheme extends InheritedWidget {
  const BeuiTheme({
    super.key,
    required this.colors,
    required this.brightness,
    required this.colorTheme,
    required super.child,
  });

  final BeuiColors colors;
  final Brightness brightness;
  final BeuiColorTheme colorTheme;

  static BeuiTheme of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<BeuiTheme>();
    assert(theme != null, 'BeuiTheme missing. Wrap the app in BeuiTheme.');
    return theme!;
  }

  static BeuiTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BeuiTheme>();

  @override
  bool updateShouldNotify(BeuiTheme oldWidget) =>
      colors != oldWidget.colors ||
      brightness != oldWidget.brightness ||
      colorTheme != oldWidget.colorTheme;

  static Widget wrap({
    Brightness brightness = Brightness.dark,
    BeuiColorTheme colorTheme = BeuiColorTheme.mono,
    required Widget child,
  }) {
    return BeuiTheme(
      colors: BeuiColors.resolve(brightness: brightness, theme: colorTheme),
      brightness: brightness,
      colorTheme: colorTheme,
      child: child,
    );
  }
}

extension BeuiThemeContext on BuildContext {
  BeuiColors get beuiColors => BeuiTheme.of(this).colors;
  BeuiTheme get beuiTheme => BeuiTheme.of(this);
}
