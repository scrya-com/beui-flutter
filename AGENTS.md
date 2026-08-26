# beUI Flutter — agent guide

Port of beUI (`ui-components`) to Flutter. Catalog, motion tokens, and interaction contracts come from the React library. Do not invent a parallel design system.

## Commands

```bash
# from packages/beui
flutter test
flutter analyze

# from apps/gallery
flutter run -d chrome
flutter run -d ios
```

Do not run `flutter build` unless asked.

## Motion

- Springs live in `lib/src/tokens/ease.dart`. Numbers must match `ui-components/lib/ease.ts`.
- Solver: `lib/src/physics/spring.dart`, a Dart port of `crates/ui_physics` (`spring_response` / `spring_ease`). Optional Rust FFI/WASM can replace the Dart fallback later; the math must stay identical.
- Named local springs stay next to the widget (tabs 170/24/1.2, switch 800/80/mass 4).
- Gate transform motion with `beuiReduceMotion`. Keep opacity/color.
- Gate decorative hover (magnetic, tilt, 1.02 scale) with `beuiHoverCapable`.
- Animate transform and opacity only. Blur ≤ 10px. Exits faster than entrances.

## Theme

`BeuiTheme` + `BeuiColors` from `app/globals.css` / `lib/themes.ts`. Consume semantic colors (`background`, `foreground`, `primary`, …), never raw hex in widgets.

## Catalog

A new widget = source in `packages/beui/lib/src/widgets/{motion|agents|blocks}/` + gallery demo keyed to the React `previewKey` + `implemented: true` in `tools/export-catalog.mjs`.

Regenerate the gallery catalog after adding a key:

```bash
bun tools/export-catalog.mjs
```

## API mapping

| React | Dart |
|---|---|
| `onChange` / `onCheckedChange` / `onValueChange` | `onChanged` |
| `className` | omitted — wrap or pass `style` |
| `value` / `defaultValue` | `value` / `initialValue` |
| `disabled` | `enabled: false` |
| `aria-label` | `semanticLabel` |

Controlled: if `value` is non-null, never write it internally.

## Out of scope

React docs site, shadcn `/r/{name}.json`, playground, beUI Pro.
