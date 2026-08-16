# Changelog

All notable changes to PayMe are documented in this file.

---

## [v2.0.0-alpha.16] — 2026-08-16

### Summary
Alpha 16 focuses on complete UI localization, final UX polish, and public repository preparation.

### Localization
- Full localization audit across all user-facing strings
- Added 30+ missing translation keys for English, French, and Arabic
- Localized User Management: deactivate dialog, role section, search bar, active/inactive labels
- Localized Role Management: system role warning, priority display, role description, edit/list screens
- Localized Client Visibility: visibility selector segments, user picker dialog, empty states
- Localized Accounting Year: delete confirmation dialog
- Added `deleteAccountingYearConfirm`, `systemOwnerDescription`, `priorityPrefix`, `clientVisibility`, `visibilityEveryone`, `visibilitySpecificUsers`, `noUsersSelected`, `selectUsers`, and related keys

### UI / UX
- Fixed `const` misuse on `SegmentedButton` segments using `AppLocalizations`
- Localized system owner role description with dynamic override in both list tile and editor
- Arabic (RTL) layout verified for all new localization strings

### Public Repository Preparation
- Untracked `lib/firebase_options.dart`, `android/app/google-services.json`, `.firebaserc`
- Updated `.gitignore` with Firebase, environment, and temp file entries
- Neutralized `firebase.json` — removed private project binding (`payme-dev-967bb`)
- Created `lib/firebase_options.example.dart` as a developer reference template
- Removed temporary development artifacts (`patch_*.py`, `scratch*.dart`, `*_output.txt`)
- Added MIT `LICENSE`
- Created full `README.md`, `CHANGELOG.md`, `docs/FIREBASE_SETUP.md`, `docs/CURRENT_STATUS.md`
- Created release notes: `docs/releases/ALPHA-15.md`, `docs/releases/ALPHA-16.md`

---

## [v2.0.0-alpha.15] — 2026-08-14

### Summary
Alpha 15 stabilized the offline-first authorization architecture and resolved critical sync issues.

### Architecture
- Offline-first `SecuredRepository` wrapper enforcing permission checks against local SQLite data
- Role propagation — live role changes take effect without requiring re-authentication
- Business-scoped multi-tenant Firestore structure (`businesses/{businessId}/...`)
- Bi-directional sync engine with conflict resolution and push/pull cycle management
- Re-authentication guard for sensitive operations (accounting year deletion)

### Features
- User management with role assignment, activation/deactivation
- Role management with permission matrix and priority ordering
- Client visibility scoping per user
- Accounting year management with active year enforcement
- Invoice and payment lifecycle tracking
- PDF generation with Arabic/RTL support (Amiri font, Arabic reshaper)
- CSV export

### Platforms
- Windows desktop — fully functional
- Android — fully functional

### Localization
- English, French, Arabic (RTL) — initial full-pass localization

---

## [v2.0.0-alpha.14] — 2026-08

### Summary
Algerian business compliance, bootstrap UX improvements, RTL fixes, offline Arabic PDF, client CSV export.

---

## [v2.0.0-alpha.13] — 2026-08

### Summary
UX polish, localization completion, document customization, and bootstrap improvements.

---

## [v2.0.0-alpha.1 … alpha.12]

Early alpha development: initial architecture, Firebase integration, local SQLite database, sync engine foundation, role/permission system, invoice/payment flows.

---

## [v1.0.0]

Initial stable release.
