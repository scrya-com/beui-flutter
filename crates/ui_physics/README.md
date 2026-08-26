# ui_physics

Vendored from [uikit](https://github.com/johndpope/uikit) (`ui_physics/`).

Damped-harmonic-oscillator springs (`spring_response`, `spring_ease`) plus iOS-style deceleration. The Flutter package uses a Dart port of the same closed form in `packages/beui/lib/src/physics/spring.dart` so every platform works without linking. Compile this crate to:

- **Web** — `wasm-pack build --target web`
- **iOS** — `staticlib` via `dart:ffi` (`DynamicLibrary.process()`)

when native/WASM acceleration is wired up. Do not change the spring math without updating the Dart fallback and the beUI token tests.
