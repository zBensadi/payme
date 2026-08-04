# Changelog

## [1.0.0] - 2026-08-04
### Added
- **Full Version 1.0 Release** of PayMe (Offline-First Client Receivables Manager).
- **Core Entities**: Clients, Invoices, Payments, and Accounting Years.
- **Reporting**: Outstanding Invoices, Paid Invoices, Client Balances, and Payments by Period with CSV export capabilities.
- **Settings**: Business Profile (Name, Address, Registration Number, Logo) and System Currency configuration.
- **PDF Generation**: Generates and previews professional PDF invoices.
- **Backup & Restore**: Full database disaster recovery via localized ZIP files.
- **Schema Version**: Deployed with `schema_version = 2`.

### Fixed
- Stabilized Backup & Restore to handle optional asset directories.
- Refined Dashboard First-Run UX for initial Accounting Year setup.
- Enforced Branding consistency across the application.

## [1.0.0-phase3] - 2026-08-01
### Added
- PBKDF2-HMAC-SHA256 password hashing via the `cryptography` package.
- `AuthService` handling password setup, login, and recovery keys.
- Complete authentication UI suite: Setup, Login, Forgot Password, Recovery Key Display, and Fatal Error screens.
- `ReauthGuard` widget to protect future destructive actions.
- GoRouter redirection guards based on authentication state.
- Fatal error state to prevent silent admin account takeover if existing business data is detected but credentials are missing.

### Changed
- `PayMeApp` now consumes `appRouterProvider` via Riverpod.
- Placeholder home screen includes a top-bar "Lock" button.

### Security
- Password and recovery key hashes are stored safely alongside the local SQLite database.
- Recovery key is only displayed once during generation.

## Version 0.0.1

### Phase 1
**Added**
- `sqflite`, `sqflite_common_ffi`, `path_provider`, `logger`, `path` dependencies.
- `DatabaseService` and `MigrationRunner` to initialize and maintain SQLite databases.
- Initial schema `v1_initial.sql` per Architecture constraints.
- Logging output initialized before app startup.
- `Result` and `AppFailure` classes for standardized error handling.
- `AppPaths` for deterministic local directory resolutions.
- `AppConstants` centralized configuration.

### Phase 0
**Added**
- `flutter_riverpod` and `go_router` dependencies.
- `AppTheme` for centralized styling.
- `app_router.dart` for GoRouter configuration.
- `PlaceholderHomeScreen` as the initial dashboard route.
- Project implementation tracking documentation structure.

**Changed**
- Replaced default Flutter counter app with foundational Clean Architecture entry points (`main.dart`, `app.dart`).
- Updated `README.md` with detailed project information and run instructions.

**Fixed**
- N/A

**Technical Notes**
- Successfully verified the build on Windows Desktop and Android.
- Using progressive dependency management.
