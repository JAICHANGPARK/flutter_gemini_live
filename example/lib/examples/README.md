# Example architecture convention

Each demo lives in its own folder under `lib/examples/<example_name>/` and
follows Flutter's recommended app architecture
(https://docs.flutter.dev/app-architecture/guide): a UI layer (views + view
models) on top of a data layer (repositories + services), with plain domain
models in between. No new dependencies: view models are plain `ChangeNotifier`s
and views use `ListenableBuilder` / `ValueListenableBuilder`.

```
examples/<example_name>/
  data/
    services/        # Wrap one external thing: Gemini Live session, audio
                     # player/recorder, camera, image picker. Stateless or
                     # hold only the handle they wrap. No BuildContext.
    repositories/    # Source of truth for app data: SharedPreferences
                     # persistence, in-memory logs. Expose domain models.
  domain/
    models/          # Immutable-ish data classes and enums (+ toJson/fromJson).
    *.dart           # Optional pure logic (parsers, prompt builders).
  ui/<screen_name>/
    <screen_name>_screen.dart   # The view (StatefulWidget only if it owns
                                # UI objects such as AnimationControllers).
    <screen_name>_i18n.dart     # Localized strings (ko/en/ja/zh).
    view_models/<screen_name>_view_model.dart
    widgets/                    # One widget per file; dialogs, snackbars,
                                # panes, tabs, markdown builders.
```

## Rules

- **View model** owns all state and logic. It must not import widgets or use a
  `BuildContext`. To trigger UI it exposes callbacks (`onNotice`,
  `requestApiKeySetup`, ...) that the screen wires up in `initState`. It guards
  against use after `dispose` (override `notifyListeners`).
- **Coarse state** (connected, camera ready, history, active tab) goes through
  `notifyListeners()`; the screen wraps its tree in one `ListenableBuilder`.
- **High-frequency streaming state** (subtitles, streamed text, mic level)
  stays on dedicated `ValueNotifier`s exposed by the view model so only small
  subtrees rebuild. Do not route these through `notifyListeners()`.
- **Services/repositories** are constructor-injected into the view model with
  defaults (`audioService ?? MathTutorAudioService()`), which keeps the view
  model unit-testable with fakes.
- **Widgets** take the view model (or plain values + callbacks) as arguments
  and never reach into services. Dialogs return their result; the screen
  forwards it to the view model.
- Shared helpers stay in `lib/` (`api_key_store.dart`, `app_settings_dialog.dart`,
  `app_translations.dart`, `live_audio_player.dart`,
  `soloud_live_audio_player.dart`, `scrollable_app_bar_actions.dart`,
  `foldable_utils.dart`). Import them as `package:example/<file>.dart`; use
  relative imports inside an example folder.
- File naming: `<example>_<thing>_service.dart`, `<thing>_repository.dart`,
  snake_case widget files. Keep files small (aim for < 500 lines).

## Adding a new example

1. Create `lib/examples/<name>/` with the folders above.
2. Put models in `domain/models/`, then repositories/services in `data/`.
3. Write the view model (state + logic), then widgets, then the screen.
4. Keep the public page class name stable (e.g. `LiveFooPage`) exported from
   the screen file and update the import in `lib/main.dart`.
5. Run `dart analyze lib` and `flutter test` from `example/`.

Reference implementation: `math_tutor/`.
