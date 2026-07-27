# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                              # Install dependencies
flutter pub run build_runner build           # Regenerate Hive model adapters (*.g.dart files)
flutter pub run build_runner build --delete-conflicting-outputs  # Regenerate, force overwrite
flutter run                                  # Run on connected device/emulator
flutter analyze                              # Lint
dart format lib/                             # Format code
flutter test                                 # Run all tests
flutter test test/widget_test.dart           # Run a specific test file
flutter build apk                            # Build Android APK
flutter clean                               # Clean build cache
```

**Important:** After modifying any `@HiveType`-annotated model in `lib/models/`, always re-run `build_runner` to update the generated `*.g.dart` adapter files.

## Architecture

**Her Şeyim** is a Flutter personal productivity app (Turkish: "Everything About Me") targeting Android, iOS, Web, and Desktop. Primary locale is Turkish (`tr_TR`) with English fallback.

### State Management
Provider pattern (`ChangeNotifier` + `MultiProvider`). All providers are registered at app startup in `main.dart` and wrap the entire widget tree. Each domain (tasks, notes, reminders, profile) has its own provider that owns both the in-memory state and persistence calls.

### Persistence
Hive (local NoSQL). Each model type has its own named Hive box opened in `main.dart` before `runApp`. Type adapters are code-generated — the `*.g.dart` files in `lib/models/` must not be edited by hand.

### Navigation
`MainScreen` (`lib/screens/main_screen.dart`) hosts a `BottomNavigationBar` over an `IndexedStack` with six tabs: Briefing, Tasks, Calendar, Notes, Reminders, Profile.

### Key directories

| Path | Purpose |
|---|---|
| `lib/models/` | Hive data models + generated adapters (`*.g.dart`) |
| `lib/providers/` | ChangeNotifier providers, one per domain |
| `lib/screens/` | Feature screens, grouped by domain subfolder |
| `lib/theme/` | `AppTheme` — Material 3 theme definition |
| `lib/widgets/` | Reusable widgets (currently minimal) |
| `lib/main.dart` | App entry: Hive init, box opens, MultiProvider root |

### Data flow pattern
Screen widget → reads/calls Provider via `context.watch` / `context.read` → Provider mutates model list and writes to Hive box → notifies listeners → UI rebuilds.

### IDs
All entities use `uuid` package (`Uuid().v4()`) for unique string IDs. Never use sequential integers as IDs.
