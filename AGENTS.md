# beUI Flutter — agent guide

Port of beUI (`ui-components`) to Flutter. Catalog, motion tokens, and interaction contracts come from the React library. Do not invent a parallel design system.

## Reference implementations

Read the source first. Do not invent a widget from a screenshot, the docs chrome, or a remembered API.

| What | Where |
|---|---|
| Free catalog | Sibling `../ui-components` — `components/{motion,agents,blocks}/`, matching `components/previews/`. Live copies: `https://beui.dev/r/{slug}` and `https://beui.dev/r/{slug}/raw`. |
| Motion numbers | `../ui-components/lib/ease.ts`. Solver: vendored `crates/ui_physics` (from `../uikit`). |
| Flutter animation / gesture patterns | `../uikit/ui/lib/uikit/` when a UIView-style animator or physics helper already exists. Reuse; do not re-derive. |
| Pro | `https://pro.beui.dev/r/{name}.json` with `BEUI_PRO_TOKEN`. A public preview is not the source. Do not approximate a Pro block. |

`get_component` / `npx shadcn@latest view @beui/<slug>` is the same source as the sibling files. If the registry 401s, stop and ask for the token.

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
| Catalog or opened demo has no motion | Do not freeze the **demo page** or tests with `TickerMode(enabled: false)`. Convert `Timer`/`Future.delayed` to `AnimationController`. Catalog **cards** wrap the live preview in `VisibleTicker` so off-screen demos stop ticking. |
| `BeuiSpringBuilder` / pop-in never moves | A spring that starts at the target value is a no-op. Mount-only motion starts at 0 and `animateTo(1)` after the first frame (`BeuiPopIn`). |
| DevTools shows light list rows / "Soon" / old chrome | A stale `flutter run` is still bound to `:8095`. Kill it, restart with **current** `apps/gallery`, confirm the screenshot is the card catalog. |
| `flutter run -d web-server` paints a black/empty page | Switch to `-d chrome`. `web-server` is not a visual target. |
| Tests fail on pending timers after dispose | Cancel every ticker in `dispose`. Do not freeze the whole tree. |
| `defaultTargetPlatform` is Android on Flutter web | `kIsWeb` is hover-capable (`beuiHoverCapable`). |
| `A ticker was started twice` | `BeuiSpringValue.animateTo` must stop-then-start. Hover (`beuiAfterPointer`) and press both retarget in one frame. |
| `State no longer has a context` after hover | `beuiAfterPointer` can run after dispose. Return if `!mounted` before reading `context`. |
| `RenderFlex overflowed` on a catalog card | `Transform.scale` does not shrink layout. Wrap the scaled stage in `OverflowBox` + `ClipRect` (`CatalogPreviewFit`). |
| Chrome long tasks while scrolling the catalog | Off-screen cards must not keep tickers. `addAutomaticKeepAlives: false` + `VisibleTicker`. |
| Motion feels faster, slower, or denser than beui.dev | The clock drifted. Copy duration, delay, stagger, ease, offset, and spring k/c/m from the React component **and** its preview. Do not substitute `BeuiPopIn` for a `y` slide. |

If DevTools, `flutter test`, or `flutter analyze` disagrees with the intended UI, the test or the widget is wrong — fix that widget before adding the next slug.

## Logs

Yellow/black stripes and frozen press springs dump here — read them, then fix the widget:

1. **Chrome DevTools → Console** on the Flutter tab (`http://127.0.0.1:8095/`). Filter Errors. Flutter prints the owning `State` (`_BeuiButtonState`) and the Dart frame (`spring_motion.dart:64`).
2. **`flutter run` terminal** — same dump, including the widget that created the ticker.
3. **Agent:** `chrome-devtools__list_pages`, then `chrome-devtools__list_console_messages` with `types: ["error","warn"]` and `includeStackTraces: true`.

Do not guess from a screenshot. The console names the widget; the stack names the line.

## Motion

- Springs live in `lib/src/tokens/ease.dart`. Numbers must match `ui-components/lib/ease.ts`.
- Solver: `lib/src/physics/spring.dart`, a Dart port of `crates/ui_physics` (`spring_response` / `spring_ease`). Optional Rust FFI/WASM can replace the Dart fallback later; the math must stay identical.
- Named local springs stay next to the widget (tabs 170/24/1.2, switch 800/80/mass 4).
- Gate transform motion with `beuiReduceMotion`. Keep opacity/color.
- Gate decorative hover (magnetic, tilt, 1.02 scale) with `beuiHoverCapable`.
- Animate transform and opacity only. Blur ≤ 10px. Exits faster than entrances.
- Agent surfaces must move: shimmer, progress grid, reasoning cycle, bubble pop, disclosure clip/size, status morphs, send/stop swap.

## React timing is the contract

Copy timing from the React **component and its preview**. Do not invent a Flutter cadence, round milliseconds, or “feel it in.”

Read both files before writing motion:

| Clock | React source |
|---|---|
| Spring k / c / m, duration, ease, blur, y/x offset | `components/{motion,agents,blocks}/…` |
| Stagger, stream interval, first delay, replay | `components/previews/…` matching `previewKey` |

Port literally:

- `duration: 0.18` → `Duration(milliseconds: 180)` (seconds × 1000, no rounding)
- `delay: 0.5` / `setTimeout(..., 500 + index * 700)` → the same numbers on an `AnimationController`
- `stagger: 0.09` → 90ms between units
- `transition: SPRING_LAYOUT` (or a local `{ stiffness, damping, mass }`) → that exact `BeuiSpringSpec`
- `ease: EASE_OUT` / `EASE_IN_OUT` / `EASE_DRAWER` → `BeuiCurves.*`
- Enter offset `y: 6` stays **6 logical pixels**, not a scale pop, unless the React file scales
- Exit duration stays shorter only when the React file already does

Gallery demos must use the preview’s clock, not “show the final state.” If the React preview streams items, the Flutter demo streams at the same offsets. Convert `setTimeout` / `setInterval` to `AnimationController` so tests can dispose them; the **deadlines stay the React numbers**.

A port that uses the right springs but the wrong stagger is wrong. Fix the clock before adding the next slug.

## Theme

`BeuiTheme` + `BeuiColors` from `app/globals.css` / `lib/themes.ts`. Consume semantic colors (`background`, `foreground`, `primary`, …), never raw hex in widgets. Gallery is dark-only (`#151515` / `#1C1C1C`).

## Catalog

A new widget = source in `packages/beui/lib/src/widgets/{motion|agents|blocks}/` + gallery demo keyed to the React `previewKey` + `implemented: true` in `tools/export-catalog.mjs`.

Regenerate the gallery catalog after adding a key:

```bash
bun tools/export-catalog.mjs
```

Gallery cards are landing-style: live scaled preview, title, description. Agent pages group the same way as `beui.dev/components/agents`.

### Usage

| Surface | Recommendation |
|---|---|
| Catalog card grid | Live preview inside `VisibleTicker` → `CatalogPreviewFit` → `IgnorePointer`. Off-screen cards must not keep `AutomaticKeepAlive`. Chrome long tasks while scrolling mean a demo is still ticking in the cache. |
| Opened demo page | Full tickers, no `VisibleTicker`. This is the copyable usage surface — follow, stream, hover, and press must run. |
| App embedding | Same as the demo page. Do not copy `VisibleTicker` into product UI unless the host is a scrolling wall of live previews. |
| Tests | Do not wrap the tree in `TickerMode(enabled: false)` to hide pending timers. Cancel controllers in `dispose`. |

`VisibleTicker` is gallery chrome, not a library widget. It only pauses motion when the card leaves the window; it does not replace `beuiReduceMotion`.

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
