# beUI for Flutter

Animated Flutter widgets ported from [beUI](https://beui.dev). Same springs, same interaction contracts, same catalog.

This is a **new repository**, sibling to [`ui-components`](https://github.com/starc007/ui-components). The React docs site and shadcn registry stay there.

## Status

Wave 0+1 is in tree: motion kernel, theme (11 × light/dark), and the first form primitives.

| Preview key | Widget |
|---|---|
| `motion/button-base` | `BeuiButton` |
| `motion/button-stateful` | `BeuiStatefulButton` |
| `motion/button-magnetic` | `BeuiMagneticButton` |
| `motion/button-metallic` | `BeuiMetallicButton` |
| `motion/switch` | `BeuiSwitch` |
| `motion/checkbox` | `BeuiCheckbox` |
| `motion/radio` | `BeuiRadioGroup` / `BeuiRadio` |
| `motion/input` | `BeuiInput` |
| `motion/tabs` | `BeuiTabs` |

The gallery lists all **123** React preview keys. Unported entries show as Soon.

## Layout

```
packages/beui/     publishable widget package
apps/gallery/      iOS / Android / Flutter web catalog
crates/ui_physics/ vendored from uikit — damped-spring closed form
tools/             catalog export from the React registry
```

## Motion kernel

Springs are the same mass / stiffness / damping as `lib/ease.ts` in the React library. The solver is the damped harmonic oscillator from [`uikit`](https://github.com/johndpope/uikit) (`crates/ui_physics`, `spring_response` / `spring_ease`), with a Dart fallback of the identical closed form so tests, Android, and web work without linking Rust.

```dart
BeuiButton(                         // SPRING_PRESS  500 / 30 / 0.6
  variant: BeuiButtonVariant.primary,
  size: BeuiButtonSize.md,
  ripple: true,
  onPressed: () {},
  child: Text('Continue'),
)

BeuiSwitch(
  value: on,
  onChanged: (v) => setState(() => on = v),
  label: 'Enable notifications',
)
```

## Run the gallery

```bash
cd apps/gallery
flutter pub get
flutter run -d chrome
flutter run -d ios
```

Each demo has a **React ↗** link to the matching page on beui.dev.

Catalog **cards** pause off-screen tickers (`VisibleTicker`). Open a card for the full, copyable usage. Do not port `VisibleTicker` into an app unless you are also rendering a grid of live previews.

## Checks

```bash
cd packages/beui && flutter test && flutter analyze
cd ../../apps/gallery && flutter analyze
```

## Parity

100% means the Flutter widget **does the same thing** as the React component (API, physics, reduced motion, controlled state, gestures). It does not mean CSS pixels match Skia glyphs. See `AGENTS.md`.
