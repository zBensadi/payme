# Phase 1: Core Infrastructure

## Objectives
- Establish the SQLite database foundation.
- Implement the structured, numbered schema migrations.
- Build logging and error-handling primitives.
- Initialize all infrastructure before application launch.

## Files Created
- `lib/core/constants/app_constants.dart`: Contains `appName`, `databaseName`, `schemaVersion`.
- `lib/core/error/failures.dart`: Defines `AppFailure` subtypes.
- `lib/core/error/result.dart`: Defines the `Result` monad (`Success` / `Failure`).
- `lib/core/storage/app_paths.dart`: Abstraction for path resolution (database, logs, attachments).
- `lib/core/logging/logger_service.dart`: Wraps `logger` for daily rotating files and console output.
- `lib/core/database/migrations/v1_initial.sql`: The full SQLite schema exact from Architecture Section 9.
- `lib/core/database/migration_runner.dart`: Reads `app_meta` and applies schema migrations in transactions.
- `lib/core/database/database_service.dart`: Encapsulates the `Database` instance.
- `lib/core/database/database_provider.dart`: Bootstraps SQLite, runs migrations, and exposes `databaseProvider`.
- `test/core/database/migration_runner_test.dart`: Validates that `v1_initial.sql` executes and creates correct tables.
- `test/core/storage/app_paths_test.dart`: Validates directory resolution.

## Files Modified
- `pubspec.yaml`: Added `sqflite`, `sqflite_common_ffi`, `path_provider`, `logger`, `path`, and migration asset folder.
- `lib/main.dart`: Initialized Logger and Database Bootstrap before `runApp`.
- `lib/presentation/features/dashboard/screens/placeholder_home_screen.dart`: Updated to watch `databaseProvider` and show initialization state.
- `test/widget_test.dart`: Injected a `FakeDatabaseService` to allow testing the UI without initializing actual SQLite in tests.

## Architectural Decisions
- Created a `DatabaseService` abstraction over the raw `Database` object to encapsulate DB ownership.
- Kept UI placeholders minimal but informative for debugging (e.g., showing database connection state).
- Explicitly split test behavior (fake dependencies) vs. real environment behavior via Riverpod overrides.

## Dependencies Added
- `sqflite`
- `sqflite_common_ffi`
- `path_provider`
- `logger`
- `path`

## Tests Executed
- `flutter test` executed successfully.

## Verification Results
- Database migration to version 1 completes successfully.
- Tables `app_meta`, `accounting_years`, `clients`, `invoices`, `payments`, `payment_attachments`, `business_settings`, and `admin_credential` exist.

## Lessons Learned
- When watching `databaseProvider` in widgets during tests, providing a test double (Fake) prevents `UnimplementedError` from providers initialized asynchronously in `main()`.
