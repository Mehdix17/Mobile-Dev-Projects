# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## High‑level Architecture

- **Entry point**: `lib/main.dart` initializes Firebase (including anonymous sign‑in fallback), sets up the `NotificationService`, and runs the app inside a `ProviderScope`.
- **Root widget**: `lib/app.dart` defines `CardlyApp`, a `ConsumerWidget` that watches the `appRouterProvider` (GoRouter) and the `settingsProvider` (Riverpod) to configure `MaterialApp.router` with light/dark themes.
- **Feature‑first organization** under `lib/features/`:
  - `auth`: authentication screens and provider.
  - `decks`: UI for deck list, detail, editor, plus repository/provider for persisting decks.
  - `cards`: card editor, detail, provider/repository.
  - `study`: multiple study mode screens, session provider/repository, SM‑2 algorithm helper.
  - `statistics`: analytics screens and provider.
  - `import_export`: import and export UI.
  - `marketplace`: marketplace UI showing predefined, community, and **My Decks** tabs. Uses `MarketplaceDeckCard` to render deck cards; the My Decks tab displays published user decks with an unpublish button.
  - `settings`: theme and other user preferences.
  - `home`: home screen with daily challenge and quick stats.
- **Core utilities** in `lib/core/`:
  - `theme`: `app_theme.dart`, `colors.dart`, `text_styles.dart`.
  - `router`: `app_router.dart`, `route_names.dart` (GoRouter configuration).
  - `constants`: various constant definitions.
  - `utils/extensions`: BuildContext, String, DateTime helpers.
  - `database`: wrappers around Firebase Firestore (`firestore_service.dart`) and a generic `database_service.dart`.
- **Shared services** in `lib/shared/services/`: auth, notification, sound, predefined decks loader, etc.
- **State Management**: Riverpod (`flutter_riverpod`) is used throughout the app. Providers live next to the feature they serve (e.g., `deck_provider.dart`, `study_session_provider.dart`).
- **Backend**: Firebase Firestore stores user decks, cards, study sessions; Firebase Auth manages anonymous or email/password authentication.

## Common Development Commands

| Task | Command |
|------|----------|
| Install dependencies | `flutter pub get` |
| Generate Riverpod code (if using code‑gen) | `dart run build_runner build --delete-conflicting-outputs` |
| Run the app on a device/emulator | `flutter run` |
| Run a specific test file | `flutter test path/to/test_file_test.dart` |
| Run a single test case (by name) | `flutter test --name "MyTestName"` |
| Run all tests | `flutter test` |
| Lint / static analysis | `flutter analyze` |
| Build release APK | `flutter build apk --release` |
| Build iOS release | `flutter build ios --release` |
| Clean build artifacts | `flutter clean` |
| Format code | `dart format .` |

## Project‑specific Tips

- The **My Decks** tab is defined in `lib/features/marketplace/presentation/screens/marketplace_screen.dart`. Published decks are filtered with `deck.isPublished`. The unpublish button is rendered via `trailingAction` with a width of `160` px to avoid overflow.
- To add a new feature you’ll typically create a new subfolder under `lib/features/` with its own screens, providers, models, and repositories, then expose routes in `app_router.dart`.
- Settings (theme mode) are stored in `SharedPreferences` using keys from `AppConstants`. The default theme is `ThemeMode.light`.
- When working with Firestore data structures, refer to the repository classes (`deck_repository.dart`, `card_repository.dart`, `study_repository.dart`, etc.) for the field names and update patterns.

## Testing Guidelines

- Unit tests live alongside their feature under `test/` mirroring the `lib/` folder structure.
- Use `flutter test --name "<test description>"` to run an individual test.
- Integration tests (if any) can be run with `flutter drive`.

## Build & Release

- For Android, generate a signed APK/AAB using `flutter build apk --release` (or `flutter build appbundle`).
- For iOS, follow the standard Xcode archive process after `flutter build ios`.
- Ensure Firebase options are correctly configured (`firebase_options.dart`).

---

*This CLAUDE.md is intended for Claude Code to quickly understand the repository layout, common commands, and how the main features are organized.*