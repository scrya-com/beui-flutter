# beUI for Flutter

Animated Flutter widgets ported from [beUI](https://beui.dev). Same springs, same interaction contracts, same catalog.

This is a **new repository**, sibling to [`ui-components`](https://github.com/starc007/ui-components). The React docs site and shadcn registry stay there.

Live gallery: [https://scrya-com.github.io/beui-flutter/](https://scrya-com.github.io/beui-flutter/)

## Status

**73 of 124** catalog previews are live. The rest show as Soon.

| Area | Live | Still Soon |
|---|---|---|
| **AI Agents** | Chat app, AI sidebar, messages, scroller, prompt input, todo list, code block, file diff, tool result (terminal), streaming response, image generation, tool approval, citations, mixed agent activity, thinking shimmer, agent progress, reasoning text | Approval card (questions / review), tool-result request, agent activity (text / steps / search / tools), agent trace |
| **Components (motion)** | Buttons, switch, checkbox, radio, input, tabs, select, combobox, sliders (all five), wheel picker, accordion, tilt card, marquee, text/number motion, badges, action-swap, animated toast stack, dock, tooltip, loader, expandable control, CTAs (arrow / hold / slide), theme toggle, bottom sheet, drawer, pull-to-refresh, scroll progress / reveal, shared-layout bg | Tables, morph select, gooey + morph popovers, context menu, morphing / center modals, bounce / animated sidebar, preview rail, shader background, cylinder carousel, smooth-scroll / parallax / scroll-to |
| **Blocks** | File upload, attachment upload | Masonry, notification stack, project folder, swap, dynamic island, command palette, morphing search, action bars, swipeable list, knockout bracket / wheel, prediction market, wallet, scheduler, OTP, signup, 404 variants |

Known limits (not Soon — live, but incomplete vs React):

- **Prompt Input** plus-menu items (`Attach image`, `Use a skill`, `Add context`) are demo `onAction` labels. The React component has no file picker or skill runner either.
- **Morphic tooltip** is a public-preview port. Licensed Pro registry JSON needs `BEUI_PRO_TOKEN`.
- **Chat App** omits Approval Card (unported).
- **Select / Combobox** on mobile: tap-to-open was broken when children were `const` (inherited `open` did not notify). Fixed — redeploy to see it.
- **Tool Approval** on a narrow phone: a 360px preview stack plus two Replay controls sat on top of Allow / Deny. The card now sizes to its content; Replay sits below the well, not over the actions.

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

## Gallery demo (CI artifact + Pages)

Each push and pull request builds the Flutter **web** gallery and uploads a **`beui-gallery`** artifact. On `main`, that build is also deployed to GitHub Pages.

- Live: [https://scrya-com.github.io/beui-flutter/](https://scrya-com.github.io/beui-flutter/)
- Artifact: Actions → latest run → `beui-gallery`. Unzip, then `python3 serve.py` and open `http://127.0.0.1:8080/beui-flutter/`.

Do **not** add a custom domain in GitHub Pages unless you own the hostname. The default `*.github.io` URL is enough. Source must be **GitHub Actions**, not “Deploy from a branch”.

Each push also builds a release **Android APK** (`beui-gallery-android` artifact, `app-release.apk`). Sideload with `adb install app-release.apk`. It is signed with the debug keystore so CI and `flutter run --release` stay installable without a Play upload key.

## Run the gallery

```bash
cd apps/gallery
flutter pub get
flutter run -d chrome
flutter run -d ios                 # connected iPhone, or
open -a Simulator && flutter run   # iOS Simulator
```

Physical iPhone (release):

```bash
cd apps/gallery
flutter run --release -d 00008140-00161C440C33001C
```

Android APK:

```bash
cd apps/gallery
flutter build apk --release
# apps/gallery/build/app/outputs/flutter-apk/app-release.apk
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Each demo has a **React ↗** link to the matching page on beui.dev. Agent demos have a **Replay** control under the preview well that remounts the example.

Catalog **cards** pause off-screen tickers (`VisibleTicker`). Open a card for the full, copyable usage. Do not port `VisibleTicker` into an app unless you are also rendering a grid of live previews.

## Checks

```bash
cd packages/beui && flutter test && flutter analyze
cd ../../apps/gallery && flutter analyze
```

## Parity

100% means the Flutter widget **does the same thing** as the React component (API, physics, reduced motion, controlled state, gestures). It does not mean CSS pixels match Skia glyphs. React milliseconds, delays, staggers, and spring k/c/m are the contract. See `AGENTS.md`.
