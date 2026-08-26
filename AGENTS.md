# beUI Flutter — agent guide

Port of beUI (`ui-components`) to Flutter. Catalog, motion tokens, and interaction contracts come from the React library. Do not invent a parallel design system.

## Commands

```bash
# from packages/beui
flutter test
flutter analyze

# from apps/gallery — Chrome, not web-server
flutter run -d chrome --web-port 8095
```

Do not run `flutter build` unless asked. Do not use `-d web-server` for visual checks: it serves an empty document unless Dart Debug Chrome is attached.

## Fix constraints on the spot

When a constraint, assertion, frozen animation, stale process, or DevTools mismatch is detected, **stop the catalog work and fix it in the same change**. Do not document it for later, disable the motion to silence a test, or keep porting on top of a broken gallery.

Already-hit constraints — treat a recurrence as a bug, not a given:

| Detection | Fix immediately |
|---|---|
| `mouse_tracker.dart` `_debugDuringDeviceUpdate` | Never `setState` inside `MouseRegion`/`Listener` hover callbacks. Use `beuiAfterPointer`. |
| Catalog or agent controls have no motion | Do not wrap previews in `TickerMode(enabled: false)` to pass tests. Convert `Timer`/`Future.delayed` to `AnimationController` so dispose is clean. |
| `BeuiSpringBuilder` / pop-in never moves | A spring that starts at the target value is a no-op. Mount-only motion starts at 0 and `animateTo(1)` after the first frame (`BeuiPopIn`). |
| DevTools shows light list rows / "Soon" / old chrome | A stale `flutter run` is still bound to `:8095`. Kill it, restart with **current** `apps/gallery`, confirm the screenshot is the card catalog. |
| `flutter run -d web-server` paints a black/empty page | Switch to `-d chrome`. `web-server` is not a visual target. |
| Tests fail on pending timers after dispose | Cancel every ticker in `dispose`. Do not freeze the whole tree. |
| `defaultTargetPlatform` is Android on Flutter web | `kIsWeb` is hover-capable (`beuiHoverCapable`). |

If DevTools, `flutter test`, or `flutter analyze` disagrees with the intended UI, the test or the widget is wrong — fix that widget before adding the next slug.

## Motion

- Springs live in `lib/src/tokens/ease.dart`. Numbers must match `ui-components/lib/ease.ts`.
- Solver: `lib/src/physics/spring.dart`, a Dart port of `crates/ui_physics` (`spring_response` / `spring_ease`). Optional Rust FFI/WASM can replace the Dart fallback later; the math must stay identical.
- Named local springs stay next to the widget (tabs 170/24/1.2, switch 800/80/mass 4).
- Gate transform motion with `beuiReduceMotion`. Keep opacity/color.
- Gate decorative hover (magnetic, tilt, 1.02 scale) with `beuiHoverCapable`.
- Animate transform and opacity only. Blur ≤ 10px. Exits faster than entrances.
- Agent surfaces must move: shimmer, progress grid, reasoning cycle, bubble pop, disclosure clip/size, status morphs, send/stop swap.

## Theme

`BeuiTheme` + `BeuiColors` from `app/globals.css` / `lib/themes.ts`. Consume semantic colors (`background`, `foreground`, `primary`, …), never raw hex in widgets. Gallery is dark-only (`#151515` / `#1C1C1C`).

## Catalog

A new widget = source in `packages/beui/lib/src/widgets/{motion|agents|blocks}/` + gallery demo keyed to the React `previewKey` + `implemented: true` in `tools/export-catalog.mjs`.

Regenerate the gallery catalog after adding a key:

```bash
bun tools/export-catalog.mjs
```

Gallery cards are landing-style: live scaled preview, title, description. Agent pages group the same way as `beui.dev/components/agents`.

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
