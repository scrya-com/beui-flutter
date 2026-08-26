import 'dart:ui';

import 'oklch.dart';

/// Brand ramps. Mirrors `lib/themes.ts` `ColorTheme`.
enum BeuiColorTheme {
  mono,
  violet,
  blue,
  green,
  amber,
  bloodOrange,
  rose,
  red,
  teal,
  indigo,
  lime,
}

extension BeuiColorThemeX on BeuiColorTheme {
  String get id => switch (this) {
        BeuiColorTheme.mono => 'default',
        BeuiColorTheme.violet => 'violet',
        BeuiColorTheme.blue => 'blue',
        BeuiColorTheme.green => 'green',
        BeuiColorTheme.amber => 'amber',
        BeuiColorTheme.bloodOrange => 'blood-orange',
        BeuiColorTheme.rose => 'rose',
        BeuiColorTheme.red => 'red',
        BeuiColorTheme.teal => 'teal',
        BeuiColorTheme.indigo => 'indigo',
        BeuiColorTheme.lime => 'lime',
      };

  String get label => switch (this) {
        BeuiColorTheme.mono => 'Mono',
        BeuiColorTheme.violet => 'Violet',
        BeuiColorTheme.blue => 'Blue',
        BeuiColorTheme.green => 'Green',
        BeuiColorTheme.amber => 'Amber',
        BeuiColorTheme.bloodOrange => 'Blood Orange',
        BeuiColorTheme.rose => 'Rose',
        BeuiColorTheme.red => 'Red',
        BeuiColorTheme.teal => 'Teal',
        BeuiColorTheme.indigo => 'Indigo',
        BeuiColorTheme.lime => 'Lime',
      };
}

/// Semantic colors matching `app/globals.css` + `lib/themes.ts`.
class BeuiColors {
  const BeuiColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.border,
    required this.borderStrong,
    required this.input,
    required this.ring,
    required this.success,
    required this.warning,
    required this.violet,
    required this.neon,
    required this.glass,
    required this.glassBorder,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color border;
  final Color borderStrong;
  final Color input;
  final Color ring;
  final Color success;
  final Color warning;
  final Color violet;
  final Color neon;
  final Color glass;
  final Color glassBorder;

  static final BeuiColors light = BeuiColors(
    background: oklchPercent(lPercent: 99, c: 0, h: 0),
    foreground: oklchPercent(lPercent: 15, c: 0, h: 0),
    card: oklchPercent(lPercent: 97, c: 0, h: 0),
    cardForeground: oklchPercent(lPercent: 15, c: 0, h: 0),
    popover: oklchPercent(lPercent: 97, c: 0, h: 0),
    popoverForeground: oklchPercent(lPercent: 15, c: 0, h: 0),
    primary: oklchPercent(lPercent: 15, c: 0, h: 0),
    primaryForeground: oklchPercent(lPercent: 99, c: 0, h: 0),
    secondary: oklchPercent(lPercent: 97, c: 0, h: 0),
    secondaryForeground: oklchPercent(lPercent: 15, c: 0, h: 0),
    muted: oklchPercent(lPercent: 97, c: 0, h: 0),
    mutedForeground: oklchPercent(lPercent: 50, c: 0, h: 0),
    accent: oklchPercent(lPercent: 72, c: 0.18, h: 195),
    accentForeground: oklchPercent(lPercent: 15, c: 0, h: 0),
    destructive: oklchPercent(lPercent: 62, c: 0.22, h: 25),
    border: oklchPercent(lPercent: 15, c: 0, h: 0, alpha: 0.06),
    borderStrong: oklchPercent(lPercent: 15, c: 0, h: 0, alpha: 0.12),
    input: oklchPercent(lPercent: 15, c: 0, h: 0, alpha: 0.06),
    ring: oklchPercent(lPercent: 15, c: 0, h: 0, alpha: 0.12),
    success: oklchPercent(lPercent: 70, c: 0.18, h: 155),
    warning: oklchPercent(lPercent: 78, c: 0.18, h: 75),
    violet: oklchPercent(lPercent: 68, c: 0.22, h: 295),
    neon: oklchPercent(lPercent: 80, c: 0.22, h: 145),
    glass: oklchPercent(lPercent: 99, c: 0, h: 0, alpha: 0.55),
    glassBorder: oklchPercent(lPercent: 15, c: 0, h: 0, alpha: 0.08),
  );

  static final BeuiColors dark = BeuiColors(
    background: const Color(0xFF151515),
    foreground: oklchPercent(lPercent: 96, c: 0, h: 0),
    card: const Color(0xFF1C1C1C),
    cardForeground: oklchPercent(lPercent: 96, c: 0, h: 0),
    popover: const Color(0xFF1C1C1C),
    popoverForeground: oklchPercent(lPercent: 96, c: 0, h: 0),
    primary: oklchPercent(lPercent: 96, c: 0, h: 0),
    primaryForeground: const Color(0xFF151515),
    secondary: const Color(0xFF1C1C1C),
    secondaryForeground: oklchPercent(lPercent: 96, c: 0, h: 0),
    muted: const Color(0xFF1C1C1C),
    mutedForeground: oklchPercent(lPercent: 62, c: 0, h: 0),
    accent: oklchPercent(lPercent: 80, c: 0.18, h: 195),
    accentForeground: const Color(0xFF151515),
    destructive: oklchPercent(lPercent: 62, c: 0.22, h: 25),
    border: const Color.fromRGBO(255, 255, 255, 0.05),
    borderStrong: const Color.fromRGBO(255, 255, 255, 0.10),
    input: const Color.fromRGBO(255, 255, 255, 0.05),
    ring: const Color.fromRGBO(255, 255, 255, 0.10),
    success: oklchPercent(lPercent: 70, c: 0.18, h: 155),
    warning: oklchPercent(lPercent: 78, c: 0.18, h: 75),
    violet: oklchPercent(lPercent: 68, c: 0.22, h: 295),
    neon: oklchPercent(lPercent: 80, c: 0.22, h: 145),
    glass: const Color.fromRGBO(28, 28, 28, 0.55),
    glassBorder: const Color.fromRGBO(255, 255, 255, 0.08),
  );

  BeuiColors copyWithBrand({
    required Color hue,
    required Color onHue,
    required Color ringColor,
  }) {
    return BeuiColors(
      background: background,
      foreground: foreground,
      card: card,
      cardForeground: cardForeground,
      popover: popover,
      popoverForeground: popoverForeground,
      primary: hue,
      primaryForeground: onHue,
      secondary: secondary,
      secondaryForeground: secondaryForeground,
      muted: muted,
      mutedForeground: mutedForeground,
      accent: hue,
      accentForeground: onHue,
      destructive: destructive,
      border: border,
      borderStrong: borderStrong,
      input: input,
      ring: ringColor,
      success: success,
      warning: warning,
      violet: violet,
      neon: neon,
      glass: glass,
      glassBorder: glassBorder,
    );
  }

  static BeuiColors resolve({
    required Brightness brightness,
    BeuiColorTheme theme = BeuiColorTheme.mono,
  }) {
    final base = brightness == Brightness.dark ? dark : light;
    if (theme == BeuiColorTheme.mono) return base;
    final brand = _brand(theme, brightness);
    return base.copyWithBrand(
      hue: brand.hue,
      onHue: brand.onHue,
      ringColor: brand.ring,
    );
  }
}

({Color hue, Color onHue, Color ring}) _brand(
  BeuiColorTheme theme,
  Brightness brightness,
) {
  final dark = brightness == Brightness.dark;
  final white = oklchPercent(lPercent: 99, c: 0, h: 0);
  final black = oklchPercent(lPercent: 15, c: 0, h: 0);
  switch (theme) {
    case BeuiColorTheme.mono:
      return (hue: black, onHue: white, ring: black);
    case BeuiColorTheme.violet:
      return dark
          ? (
              hue: oklchPercent(lPercent: 72, c: 0.16, h: 290),
              onHue: black,
              ring: oklchPercent(lPercent: 72, c: 0.16, h: 290, alpha: 0.55),
            )
          : (
              hue: oklchPercent(lPercent: 55, c: 0.2, h: 290),
              onHue: white,
              ring: oklchPercent(lPercent: 55, c: 0.2, h: 290, alpha: 0.5),
            );
    case BeuiColorTheme.blue:
      return dark
          ? (
              hue: oklchPercent(lPercent: 70, c: 0.15, h: 255),
              onHue: black,
              ring: oklchPercent(lPercent: 70, c: 0.15, h: 255, alpha: 0.55),
            )
          : (
              hue: oklchPercent(lPercent: 55, c: 0.18, h: 255),
              onHue: white,
              ring: oklchPercent(lPercent: 55, c: 0.18, h: 255, alpha: 0.5),
            );
    case BeuiColorTheme.green:
      return dark
          ? (
              hue: oklchPercent(lPercent: 72, c: 0.15, h: 150),
              onHue: black,
              ring: oklchPercent(lPercent: 72, c: 0.15, h: 150, alpha: 0.55),
            )
          : (
              hue: oklchPercent(lPercent: 56, c: 0.14, h: 150),
              onHue: white,
              ring: oklchPercent(lPercent: 56, c: 0.14, h: 150, alpha: 0.5),
            );
    case BeuiColorTheme.amber:
      return dark
          ? (
              hue: oklchPercent(lPercent: 80, c: 0.15, h: 75),
              onHue: oklchPercent(lPercent: 18, c: 0.02, h: 75),
              ring: oklchPercent(lPercent: 80, c: 0.15, h: 75, alpha: 0.55),
            )
          : (
              hue: oklchPercent(lPercent: 74, c: 0.15, h: 70),
              onHue: oklchPercent(lPercent: 20, c: 0.02, h: 70),
              ring: oklchPercent(lPercent: 74, c: 0.15, h: 70, alpha: 0.5),
            );
    case BeuiColorTheme.bloodOrange:
      return dark
          ? (
              hue: oklchPercent(lPercent: 72, c: 0.17, h: 42),
              onHue: black,
              ring: oklchPercent(lPercent: 72, c: 0.17, h: 42, alpha: 0.55),
            )
          : (
              hue: oklchPercent(lPercent: 60, c: 0.19, h: 40),
              onHue: white,
              ring: oklchPercent(lPercent: 60, c: 0.19, h: 40, alpha: 0.5),
            );
    case BeuiColorTheme.rose:
      return dark
          ? (
              hue: oklchPercent(lPercent: 70, c: 0.17, h: 12),
              onHue: black,
              ring: oklchPercent(lPercent: 70, c: 0.17, h: 12, alpha: 0.55),
            )
          : (
              hue: oklchPercent(lPercent: 58, c: 0.2, h: 12),
              onHue: white,
              ring: oklchPercent(lPercent: 58, c: 0.2, h: 12, alpha: 0.5),
            );
    case BeuiColorTheme.red:
      return dark
          ? (
              hue: oklchPercent(lPercent: 68, c: 0.19, h: 25),
              onHue: black,
              ring: oklchPercent(lPercent: 68, c: 0.19, h: 25, alpha: 0.55),
            )
          : (
              hue: oklchPercent(lPercent: 55, c: 0.22, h: 25),
              onHue: white,
              ring: oklchPercent(lPercent: 55, c: 0.22, h: 25, alpha: 0.5),
            );
    case BeuiColorTheme.teal:
      return dark
          ? (
              hue: oklchPercent(lPercent: 72, c: 0.13, h: 185),
              onHue: black,
              ring: oklchPercent(lPercent: 72, c: 0.13, h: 185, alpha: 0.55),
            )
          : (
              hue: oklchPercent(lPercent: 55, c: 0.12, h: 185),
              onHue: white,
              ring: oklchPercent(lPercent: 55, c: 0.12, h: 185, alpha: 0.5),
            );
    case BeuiColorTheme.indigo:
      return dark
          ? (
              hue: oklchPercent(lPercent: 70, c: 0.16, h: 275),
              onHue: black,
              ring: oklchPercent(lPercent: 70, c: 0.16, h: 275, alpha: 0.55),
            )
          : (
              hue: oklchPercent(lPercent: 50, c: 0.2, h: 275),
              onHue: white,
              ring: oklchPercent(lPercent: 50, c: 0.2, h: 275, alpha: 0.5),
            );
    case BeuiColorTheme.lime:
      return dark
          ? (
              hue: oklchPercent(lPercent: 80, c: 0.18, h: 130),
              onHue: oklchPercent(lPercent: 18, c: 0.04, h: 130),
              ring: oklchPercent(lPercent: 80, c: 0.18, h: 130, alpha: 0.55),
            )
          : (
              hue: oklchPercent(lPercent: 72, c: 0.18, h: 130),
              onHue: oklchPercent(lPercent: 20, c: 0.04, h: 130),
              ring: oklchPercent(lPercent: 72, c: 0.18, h: 130, alpha: 0.5),
            );
  }
}
