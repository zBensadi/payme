# Phase 2: Authentication

## Objectives
- Gated the application behind a single administrator password.
- Implemented a secure, offline recovery mechanism (Recovery Key).
- Handled initial setup, login, logout, and password resets securely.
- Handled scenarios involving existing business data with missing/corrupted authentication metadata to prevent silent takeovers.
- Avoided unnecessary platform complexity by omitting `flutter_secure_storage` and keeping the password hash locally in SQLite.

## Files Created
- `lib/core/security/password_hasher.dart`: Pure PBKDF2 hashing logic.
- `lib/core/security/reauth_guard.dart`: Widget to protect destructive actions.
- `lib/data/datasources/local/admin_credential_local_datasource.dart`: Data access layer for credentials.
- `lib/services/auth_service.dart`: Orchestrator for hashing, validation, setup, and recovery flows.
- `lib/presentation/features/auth/controllers/auth_controller.dart`: Global authentication state manager.
- `lib/presentation/features/auth/screens/setup_password_screen.dart`: UI for initial password creation.
- `lib/presentation/features/auth/screens/recovery_key_display_screen.dart`: One-time display of the recovery key.
- `lib/presentation/features/auth/screens/login_screen.dart`: Password entry screen.
- `lib/presentation/features/auth/screens/forgot_password_screen.dart`: Password recovery screen.
- `lib/presentation/features/auth/screens/fatal_auth_error_screen.dart`: Error screen for preventing data takeover when credentials are corrupted.
- `test/core/security/password_hasher_test.dart`
- `test/services/auth_service_test.dart`
- `test/presentation/features/auth/auth_flow_test.dart`

## Files Modified
- `lib/presentation/routing/app_router.dart`: Added GoRouter redirects based on AuthState.
- `lib/app.dart`: Updated to use Riverpod-provided router.
- `lib/presentation/features/dashboard/screens/placeholder_home_screen.dart`: Added lock icon.
- `test/widget_test.dart`: Updated mock configurations.

## Architectural Decisions
- Used `cryptography` package with PBKDF2-HMAC-SHA256 (100k iterations) for fully offline, cross-platform password hashing.
- Skipped `flutter_secure_storage` entirely for Phase 2 as the architecture specifically designated SQLite for password hash storage to ensure portability across devices and backup files.
- Stored Recovery Key identically to a password (hashed + salted) and display the plain-text key exactly once to the user.

## Dependencies Added
- `cryptography: ^2.7.0` (or latest compatible version)

## Tests Executed
- `password_hasher_test.dart`
- `auth_service_test.dart`
- `auth_flow_test.dart`
- `widget_test.dart`

## Verification Results
- 100% test pass rate.
- UI elements safely constrained in `SingleChildScrollView` to prevent test-time `RenderFlex` overflow errors on small viewports.
- The GoRouter correctly intercepts navigation and enforces the appropriate AuthState.
