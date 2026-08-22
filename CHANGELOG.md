# Changelog

All notable changes to PayMe are documented in this file.

---

## [2.0.0-alpha.18] - Unreleased

### Summary
Alpha 18 focuses on UI/UX polish, desktop navigation enhancements, and a complete redesign of the PDF layout system.

### Features & Polish
- **PDF Redesign**: Redesigned the invoice/payment receipt layout to be more compact, supporting two identical receipts side-by-side on a single A4 page to save paper, while ensuring no clipping for long addresses.
- **Amount in Words**: Added numeric-to-words formatting (EN, FR, AR) for invoice totals.
- **Client Activity Logging**: Added `activity` note taking on the client model (Schema Version 17).
- **Navigation & Shortcuts**: 
  - Restructured the `+` shortcut (`PlusAction`) to be screen-specific (creating invoices, clients, etc.) and safely ignored when text fields are focused.
  - Enabled standard `F5` and `Backspace` hardware shortcuts for desktop navigation.
- **UI Responsiveness**: 
  - Introduced `SyncRefreshButton` for consistent manual sync interactions.
  - Implemented 'Select All / Deselect All' toggles in the Role Editor.
  - Added a visual logged-in indicator in the app layout.
  - Fixed reactivity issues in the global invoice list.

---

## [v2.0.0-alpha.17] — 2026-08-21

### Summary
Alpha 17 focuses on transitioning PayMe V2 from a permissive, client-enforced authorization model to a robust, server-authoritative Firestore backend, along with final analyzer cleanup and test stabilization.

### Security & Architecture
- **Firestore Rules**: Implemented strict RBAC via `hasRolePermission()` and business isolation via Custom Claims.
- **Cloud Functions**: Moved business bootstrap and user provisioning/deactivation to trusted Cloud Functions (`bootstrapBusiness`, `provisionUser`, `deactivateUser`, `reactivateUser`).
- **Custom Claims**: Replaced client-authoritative `businessId` fields with Firebase Auth Custom Claims to ensure zero-cost tenant isolation.
- **Storage Rules**: Enforced that only the business Owner can upload/modify the business logo, while allowing any authorized user within the same business to read it.

### Features & Polish
- **Logo Synchronization**: Business logos are now synchronized via Firebase Storage with a strict 2 MB limit. PDF generation correctly utilizes authenticated fallback downloads.
- **Dashboard Synchronization**: Dashboard now listens to `localMutation` events for immediate UI updates when clients or invoices are created.
- **Client Visibility**: `SecuredClientRepository` automatically bypasses visibility restrictions for the business Owner.
- **Audit Metadata**: Implemented `user_lookup_provider` to resolve UIDs into human-readable Display Names (or Emails) for audit trails.
- **Analyzer Cleanup**: Achieved 0 analyzer errors and 0 production-code warnings (`dart fix`, removed dead code, migrated `RadioListTile` to `RadioGroup`).

### Test Baseline
- **172 Flutter tests passing**
- **68 automated security tests passing**
- **1 intentionally pending security test**

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
