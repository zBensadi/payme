# Changelog

## [Stage 3.1 Final] - 2026-08-11
### Added
- Implemented **Stage 3 Offline-First Architecture & Sync Foundations** based on the V2 Architecture.
- Deployed Firebase Authentication for Cloud Mode with decoupled offline recovery options (SQLite first).
- Implemented **Authentication Routing Layer**:
  - `users/{uid}` pointer collection in Firestore acting solely as O(1) idempotency checks.
  - Canonical user data relocated to `businesses/{businessId}/users/{uid}`.
- Refined `FirebaseBootstrapScreen` to provide strict Fail-Closed security. Missing canonical data routes to a dedicated **Account Data Error** view rather than the registration form.
- Introduced `CurrentAppUser` relying entirely on SQLite caching.

### Changed
- Refactored `BootstrapController` and `FirebaseBootstrapRepository` to strictly manage offline seeding without intermingling ongoing sync logic.
- `SyncService` is completely decoupled from initial setup.
### Added
- Attachment file size limits (5MB max) and format restrictions (`pdf`, `jpg`, `jpeg`, `png`) visually enforced in `PaymentFormScreen`.
- `BusinessSettings` defaults are instantly marked dirty on a fresh installation for immediate Firebase synchronization.

### Fixed
- Stabilized settings serialization to include `defaultDocumentTitle` and `defaultDocumentLayout` in the Firebase payload, resolving a data-loss bug.
- Resolved a layout clipping bug in the `PdfGenerationService` where the "duplicate" document layout overflowed and truncated invoice items. The layout now correctly scales down proportionally to fit half the page.
- Adjusted `DashboardScreen` behavior on fresh logins to retain the `LoadingView` until initial data synchronization completes, preventing the Accounting Year Setup screen from flashing prematurely.
- Refactored `GlobalInvoiceListController` to strictly await all dependencies (`activeYearProvider` and `clientListControllerProvider`) during initialization, fixing a bug where invoices failed to load upon immediately opening the screen.

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
