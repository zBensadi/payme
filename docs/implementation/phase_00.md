# Phase 0: Project Bootstrap

## Objectives
- Initialize the Flutter project for Windows Desktop and Android.
- Establish the folder structure according to the Clean Architecture layout.
- Add and configure initial dependencies for routing and state management.
- Set up a foundational theming configuration.
- Implement a placeholder home screen to verify the setup.

## Files Created
- `lib/app.dart`: Configures the Riverpod and GoRouter wrappers.
- `lib/core/theme/app_theme.dart`: Centralizes light and dark themes.
- `lib/presentation/features/dashboard/screens/placeholder_home_screen.dart`: The initial `/` route view.
- `lib/presentation/routing/app_router.dart`: Basic `go_router` setup.

## Files Modified
- `pubspec.yaml`: Added `flutter_riverpod` and `go_router`.
- `lib/main.dart`: Cleaned up default code, wrapped `PayMeApp` in `ProviderScope`.
- `test/widget_test.dart`: Updated the default test to verify the placeholder screen renders.
- `README.md`: Added project overview and running instructions.
- `analysis_options.yaml`: Verified to ensure standard Flutter lints are active.

## Architectural Decisions
- Used progressive dependency management: only added packages strictly required for Phase 0, deferring database and logging dependencies to Phase 1.
- Avoided creating empty directories or files that do not yet contain meaningful code, keeping the project tree clean.

## Dependencies Added
- `flutter_riverpod` (v3.x)
- `go_router` (v14.x)

## Tests Executed
- `flutter test`: Ran the widget smoke test.

## Verification Results
- All tests passed successfully.
- `flutter pub get` runs cleanly without conflicts.

## Lessons Learned
- Creating a solid `AppTheme` at the very beginning minimizes UI drift later on.
- Progressive dependency management reduces initial noise and helps document exactly when and why a new package is introduced to the architecture.
