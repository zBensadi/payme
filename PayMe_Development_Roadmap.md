# PayMe — Development Roadmap
### Solo-Developer, Milestone-Based Build Plan (based on the approved architecture)

**How to read this roadmap:** Each phase is small, sequential, and ends with the app in a **runnable, demoable state** — `flutter run` always produces a working app on Windows and Android, with strictly more functionality than the phase before. Nothing in a later phase is required for an earlier phase to work. File and folder paths match the approved architecture document exactly, so each phase is literally "create these files, wire these providers."

Each phase lists: **Goal**, **Runnable state at the end**, **Files/Folders to add**, **Entities**, **Repositories/Datasources**, **Domain/Application Services**, **Screens/Widgets**, **Provider wiring**, **Tests to add**, and **Definition of Done**.

A rough relative-size tag (**S** / **M** / **L**) is included per phase as a planning aid — not a time estimate, since pace varies.

---

## Milestone Overview

| # | Phase | Size | Depends on |
|---|---|---|---|
| 0 | Project Bootstrap | S | — |
| 1 | Core Infrastructure (DB, migrations, logging, errors) | M | 0 |
| 2 | Authentication (password + recovery key) | M | 1 |
| 3 | Accounting Years | M | 2 |
| 4 | Clients (global entity) | M | 3 |
| 5 | Invoices | M | 4 |
| 6 | Payments & Attachments | L | 5 |
| 7 | Client Ledger (primary screen) | M | 6 |
| 8 | Dashboard | S | 7 |
| 9 | Reports | M | 7 |
| 10 | Settings (business info, currency, logo) | M | 5 |
| 11 | PDF Generation | M | 10 |
| 12 | Backup & Restore (full) | M | 3 |
| 13 | Accounting Year Export/Import | L | 12 |
| 14 | Hardening & Polish | M | 13 |
| 15 | Packaging & Release | S | 14 |

Phases 8–11 can be reordered relative to each other if you want a different "feels complete" milestone sooner (e.g., PDF before Reports) — they don't depend on one another, only on Phase 7. Everything from Phase 12 onward assumes the full data model (3–6) is stable, since Backup/Export are the highest-risk, most destructive features and should be built last against a model that's already proven itself.

---

## Phase 0 — Project Bootstrap

**Goal:** Get a Flutter project running on both target platforms with the full folder skeleton in place, before any real feature exists.

**Runnable state:** `flutter run -d windows` and `flutter run -d android` both launch and show a placeholder "PayMe" screen.

**Folders/files to add:**
```
lib/main.dart
lib/app.dart
lib/core/theme/
lib/core/constants/
lib/core/database/
lib/core/database/migrations/
lib/core/error/
lib/core/security/
lib/core/storage/
lib/core/logging/
lib/core/utils/
lib/domain/entities/
lib/domain/repositories/
lib/domain/services/
lib/data/datasources/local/
lib/data/datasources/file/
lib/data/models/
lib/data/repositories_impl/
lib/services/
lib/presentation/routing/app_router.dart
lib/presentation/providers/repository_providers.dart
lib/presentation/features/   (empty subfolders per feature, per architecture Section 3)
```

**pubspec.yaml — add and pin:**
`flutter_riverpod`, `go_router`, `sqflite`, `sqflite_common_ffi`, `path_provider`, `cryptography`, `flutter_secure_storage`, `pdf`, `printing`, `file_picker`, `archive`, `uuid`, `intl`, `logger`, `flutter_lints`.

**Entities / Repos / Services:** none yet.

**Screens:** `PlaceholderHomeScreen` (a single `Scaffold` with "PayMe" text) wired as the router's `/` route.

**Provider wiring:** `ProviderScope` wraps `main.dart`'s `runApp`.

**Tests:** a single smoke test confirming the app builds and the placeholder screen renders.

**Definition of Done:** Project runs on both platforms from a clean checkout with `flutter pub get && flutter run`.

---

## Phase 1 — Core Infrastructure

**Goal:** Database, migrations, logging, and error-handling primitives exist and are provably working — before any feature depends on them.

**Runnable state:** App launches, initializes the SQLite database on both platforms, runs the v1 migration, and shows a debug confirmation (e.g., a temporary "DB ready — schema v1" line on the placeholder screen, removable later).

**Files to add:**
```
lib/core/database/database_provider.dart      # sqflite / sqflite_common_ffi bootstrap
lib/core/database/migrations/v1_initial.sql   # full schema from architecture Section 9
lib/core/database/migration_runner.dart
lib/core/error/result.dart                    # Result<T> sealed class
lib/core/error/failures.dart                  # AppFailure subtypes
lib/core/storage/app_paths.dart               # resolves platform storage dirs
lib/core/logging/logger_service.dart
```

**Entities:** none exposed yet — tables exist, but no domain classes wired to them.

**Repositories/Services:** none yet.

**Tests:**
- `MigrationRunner` applies `v1_initial.sql` to an empty temp DB and all expected tables exist.
- `AppPaths` resolves a writable directory on both platform test targets (or is abstracted/mocked for CI).

**Definition of Done:** On both platforms, a real `payme.db` file is created at the correct path, contains all Section 9 tables, and `app_meta.schema_version = 1`. Logger writes a daily rotating file under `logs/`.

---

## Phase 2 — Authentication

**Goal:** The app is gated behind a password, with a safe offline recovery mechanism, per the approved Security section.

**Runnable state:** Fresh install forces password + recovery-key setup; subsequent launches require the password; a working "Forgot Password" flow exists; after login, the (still-placeholder) home screen shows.

**Files to add:**
```
lib/core/security/password_hasher.dart
lib/core/security/reauth_guard.dart                      # shared re-auth widget, used later by Phases 3, 12, 13
lib/data/datasources/local/admin_credential_local_datasource.dart
lib/services/auth_service.dart
lib/presentation/features/auth/controllers/auth_controller.dart
lib/presentation/features/auth/screens/setup_password_screen.dart
lib/presentation/features/auth/screens/recovery_key_display_screen.dart
lib/presentation/features/auth/screens/login_screen.dart
lib/presentation/features/auth/screens/forgot_password_screen.dart
```

**Entities:** none new (per architecture, `AdminCredential` is internal to the security layer, not a domain entity).

**Repositories/Services:** `AuthService` (password verify/change, recovery-key verify/reset — no repository interface needed here since it's single-table and security-scoped, not part of the general data model).

**Screens:** Setup Password → Recovery Key Display (shown once) → Login → Forgot Password.

**Provider wiring:** `authControllerProvider`, `authServiceProvider`. `app_router.dart` gets a top-level `redirect`: unauthenticated → `/login`; no admin credential yet → `/setup`.

**Tests:**
- `PasswordHasher` hash/verify round-trip.
- Wrong password rejected; correct password accepted.
- Recovery-key reset changes the password without touching any other table.

**Definition of Done:** Every app launch requires the password; losing the password but having the recovery key allows a full reset with zero data loss; losing both is clearly a dead end (by design, per architecture).

---

## Phase 3 — Accounting Years

**Goal:** The foundational scoping entity exists — everything from Phase 5 onward needs an active year to attach to.

**Runnable state:** Logged-in user can create years, switch the active year, rename, and delete a non-active year (password-gated). Home screen displays the active year's name.

**Files to add:**
```
lib/domain/entities/accounting_year.dart
lib/domain/repositories/accounting_year_repository.dart
lib/data/models/accounting_year_model.dart
lib/data/datasources/local/accounting_year_local_datasource.dart
lib/data/repositories_impl/accounting_year_repository_impl.dart
lib/presentation/features/accounting_years/controllers/accounting_year_controller.dart
lib/presentation/features/accounting_years/screens/accounting_years_screen.dart
lib/presentation/features/accounting_years/widgets/year_list_tile.dart
lib/presentation/providers/active_year_provider.dart
```

**Entities:** `AccountingYear`.

**Repositories:** `AccountingYearRepository` (interface) / `AccountingYearRepositoryImpl` — `getAll`, `getActive`, `create`, `setActive`, `rename`, `delete` (throws/returns failure if `yearId` is active).

**Provider wiring:** `accountingYearRepositoryProvider` added to `repository_providers.dart`; `activeYearProvider` exposes the current active year app-wide (most future screens `watch` this).

**Tests:**
- Only one year can be active at a time.
- Deleting the active year is blocked with a clear error.
- Deleting a non-active year requires `ReauthGuard` (built in Phase 2) to pass first.

**Definition of Done:** Can create 2025/2026, switch between them, rename, and delete a non-active one only after re-entering the password.

---

## Phase 4 — Clients

**Goal:** The global Client entity, independent of any accounting year.

**Runnable state:** Client list (visible/non-deleted only), add/edit client, soft delete, and a separate screen to view and restore deleted clients.

**Files to add:**
```
lib/domain/entities/client.dart
lib/domain/repositories/client_repository.dart
lib/data/models/client_model.dart
lib/data/datasources/local/client_local_datasource.dart
lib/data/repositories_impl/client_repository_impl.dart
lib/presentation/features/clients/controllers/client_list_controller.dart
lib/presentation/features/clients/controllers/client_form_controller.dart
lib/presentation/features/clients/screens/client_list_screen.dart
lib/presentation/features/clients/screens/client_form_screen.dart
lib/presentation/features/clients/screens/deleted_clients_screen.dart
lib/presentation/features/clients/widgets/client_list_tile.dart
```

**Entities:** `Client` (with `isDeleted`).

**Repositories:** `ClientRepository` — `getAllVisible`, `getAllIncludingDeleted`, `getById`, `create`, `update`, `softDelete`, `restore`.

**Provider wiring:** `clientRepositoryProvider`; `app_router.dart` gains `/clients` and `/clients/new`.

**Tests:**
- Soft-deleted client excluded from `getAllVisible`, present in `getAllIncludingDeleted`.
- Restore reverses it correctly.

**Definition of Done:** Full client CRUD with soft delete/restore working exactly per architecture (deleted clients hidden from normal list and any future picker, but never hard-deleted).

---

## Phase 5 — Invoices

**Goal:** Invoices scoped to one client + one accounting year, with auto-numbering and (for now, payment-less) status.

**Runnable state:** From a client's screen, create/edit/delete invoices within the active year; invoice numbers auto-generate and restart per year; status shows "Unpaid" (no payments exist yet).

**Files to add:**
```
lib/domain/entities/invoice.dart
lib/domain/entities/invoice_status.dart
lib/domain/repositories/invoice_repository.dart
lib/domain/services/invoice_status_calculator.dart
lib/domain/services/invoice_number_generator.dart
lib/data/models/invoice_model.dart
lib/data/datasources/local/invoice_local_datasource.dart
lib/data/repositories_impl/invoice_repository_impl.dart
lib/presentation/features/invoices/controllers/invoice_list_controller.dart
lib/presentation/features/invoices/controllers/invoice_form_controller.dart
lib/presentation/features/invoices/screens/invoice_list_screen.dart
lib/presentation/features/invoices/screens/invoice_form_screen.dart
lib/presentation/features/invoices/widgets/invoice_status_badge.dart
```

**Entities:** `Invoice`, `InvoiceStatus` enum.

**Domain Services:** `InvoiceStatusCalculator` (unpaid case only is exercised for now — full matrix comes in Phase 6), `InvoiceNumberGenerator`.

**Repositories:** `InvoiceRepository` — `getInvoicesForYear`, `getInvoicesForClient`, `getById`, `create`, `update`, `delete`, `nextInvoiceNumber`.

**Provider wiring:** `invoiceRepositoryProvider`; router gains `/clients/:id/invoices/:invoiceId`.

**Tests:**
- Invoice numbers are unique and sequential per `(year, number)`, restart correctly in a new year.
- Deleting an invoice with no payments removes cleanly (cascade path exercised trivially; full cascade-with-payments tested in Phase 6).

**Definition of Done:** Full invoice CRUD scoped correctly to client + active year, with correct auto-numbering.

---

## Phase 6 — Payments & Attachments

**Goal:** The other half of the financial model — payments against invoices, multiple attachments per payment, and the full status/overpayment logic.

**Runnable state:** From an invoice, record/edit/delete payments (each with method, reference, notes, multiple attachments); invoice status live-updates across the full Unpaid → Partially Paid → Paid → Overpaid range; a payment cannot be entered above the invoice's remaining balance; editing an invoice's amount down below what's already paid correctly flags Overpaid.

**Files to add:**
```
lib/domain/entities/payment.dart
lib/domain/entities/payment_attachment.dart
lib/domain/repositories/payment_repository.dart
lib/domain/services/overpayment_detector.dart
lib/data/models/payment_model.dart
lib/data/datasources/local/payment_local_datasource.dart
lib/data/datasources/file/attachment_file_datasource.dart
lib/presentation/features/payments/controllers/payment_list_controller.dart
lib/presentation/features/payments/controllers/payment_form_controller.dart
lib/presentation/features/payments/screens/payment_list_screen.dart
lib/presentation/features/payments/screens/payment_form_screen.dart
lib/presentation/features/payments/widgets/attachment_picker.dart
lib/presentation/features/payments/widgets/attachment_thumbnail.dart
lib/data/repositories_impl/payment_repository_impl.dart
```

**Entities:** `Payment`, `PaymentAttachment`.

**Domain Services:** `OverpaymentDetector`; `InvoiceStatusCalculator` now exercised across its full matrix.

**Repositories:** `PaymentRepository` — `getPaymentsForInvoice`, `create`, `update`, `delete` (cascades attachment rows + files via `AttachmentFileDatasource`), plus attachment add/remove methods.

**Provider wiring:** `paymentRepositoryProvider`.

**Tests:**
- `InvoiceStatusCalculator`: full matrix — zero payments, partial, exact, over.
- Payment amount validated against remaining balance at entry time.
- Deleting a payment/invoice deletes attachment rows *and* files on disk (verify both).

**Definition of Done:** The complete financial core of the app — invoices, payments, statuses, attachments — works end to end and is the most heavily unit-tested part of the codebase so far, matching the architecture's risk-weighted testing priority.

---

## Phase 7 — Client Ledger

**Goal:** Assemble everything built so far into the screen the spec calls "the primary working screen of the application."

**Runnable state:** Opening a client shows Total Invoiced / Total Paid / Remaining Balance for the **active year**, with the client's invoices (and their statuses) listed below, drilling into payment detail.

**Files to add:**
```
lib/domain/services/client_ledger_calculator.dart
lib/presentation/features/clients/controllers/client_ledger_controller.dart
lib/presentation/features/clients/screens/client_ledger_screen.dart
lib/presentation/features/clients/widgets/ledger_summary_card.dart
```
`app_router.dart`: `/clients/:id` now resolves to `ClientLedgerScreen` (superseding a bare detail view).

**Domain Services:** `ClientLedgerCalculator` — aggregates invoices/payments for a client **scoped to the active year**, per the approved clarification.

**Tests:** ledger totals correct across a range of invoice/payment combinations; correctly excludes other years' data.

**Definition of Done:** The Client Ledger is accurate, fast, and is where a user would naturally land after picking a client — this is the app's functional center of gravity from this point forward.

---

## Phase 8 — Dashboard

**Goal:** Replace the placeholder home screen with a real one.

**Runnable state:** App opens (post-login) to a Dashboard showing the active year, an outstanding-balance summary, and quick links into Clients/Invoices/Reports.

**Files to add:**
```
lib/presentation/features/dashboard/controllers/dashboard_controller.dart
lib/presentation/features/dashboard/screens/dashboard_screen.dart
lib/presentation/features/dashboard/widgets/summary_tile.dart
```
`app_router.dart`: `/` now resolves to `DashboardScreen`.

**Tests:** dashboard aggregation matches the sum of individual client ledgers for the active year (cross-check test).

**Definition of Done:** Placeholder screen from Phase 0 is fully retired; the app now "feels" like a finished product's home screen.

---

## Phase 9 — Reports

**Goal:** The four required read-only reports.

**Runnable state:** From the Dashboard or a Reports section, view Outstanding Invoices, Paid Invoices, Client Balances, and Payments by Period — all scoped to the active year.

**Files to add:**
```
lib/presentation/features/reports/controllers/reports_controller.dart
lib/presentation/features/reports/screens/reports_home_screen.dart
lib/presentation/features/reports/screens/outstanding_invoices_report_screen.dart
lib/presentation/features/reports/screens/paid_invoices_report_screen.dart
lib/presentation/features/reports/screens/client_balances_report_screen.dart
lib/presentation/features/reports/screens/payments_by_period_report_screen.dart
```
Small additions to `InvoiceRepository`/`PaymentRepository` interfaces: targeted query methods (e.g., `getOutstandingInvoices(yearId)`, `getPaymentsBetween(yearId, start, end)`) rather than pulling everything into memory and filtering in Dart.

**Tests:** one test per report query, checking correctness against a seeded dataset with a known expected result.

**Definition of Done:** All four reports render correct, live data; no report performs an unbounded full-table scan without a year filter.

---

## Phase 10 — Settings

**Goal:** Business information, currency (with its lock rule), logo, and password change, all in one place.

**Runnable state:** Settings screen lets the user edit business info/logo freely before the first invoice ever created app-wide, and shows currency as read-only after that point. Password change works independently of the recovery-key flow from Phase 2.

**Files to add:**
```
lib/domain/entities/business_settings.dart
lib/domain/repositories/settings_repository.dart
lib/data/models/business_settings_model.dart
lib/data/datasources/local/settings_local_datasource.dart
lib/data/repositories_impl/settings_repository_impl.dart
lib/presentation/features/settings/controllers/settings_controller.dart
lib/presentation/features/settings/screens/settings_screen.dart
lib/presentation/features/settings/screens/change_password_screen.dart
lib/presentation/features/settings/widgets/logo_picker.dart
```

**Retroactive wiring task:** the Invoice form (Phase 5) gets a small addition here — reading `currencyLockedAt` to display the active currency alongside invoice amounts, and setting it on the very first invoice creation across the whole app if not already set.

**Tests:** currency becomes read-only immediately after the first invoice is created anywhere in the app (not just the current year); settings persist correctly across restarts.

**Definition of Done:** Settings screen fully functional; currency lock rule verified against the actual invoice-creation trigger, not just a UI toggle.

---

## Phase 11 — PDF Generation

**Goal:** Generate a professional invoice PDF from business settings + client + invoice data.

**Runnable state:** From an invoice's detail view, generate, preview, print, and save a PDF.

**Files to add:**
```
lib/services/pdf_generation_service.dart
lib/presentation/features/invoices/widgets/invoice_pdf_preview_button.dart
```
(Internally, `PdfGenerationService` composes the header/client/details/footer sections described in the architecture — these can live as private builder methods within the service rather than separate files, given there's only one template in V1.)

**Tests:** service produces non-empty PDF bytes across varied inputs, including a client/invoice with no logo set and very long business names/addresses (layout doesn't throw).

**Definition of Done:** A generated PDF looks correct for a real invoice, with and without a logo configured.

---

## Phase 12 — Backup & Restore (Full)

**Goal:** Whole-database backup and restore, migration-aware.

**Runnable state:** From a Backup screen, create a full backup ZIP (DB + attachments + settings + metadata) and restore from one — both gated by `ReauthGuard`.

**Files to add:**
```
lib/domain/repositories/backup_repository.dart
lib/data/repositories_impl/backup_repository_impl.dart
lib/services/backup_service.dart
lib/presentation/features/backup/controllers/backup_controller.dart
lib/presentation/features/backup/screens/backup_restore_screen.dart
```

**Tests:**
- Backup → Restore round-trip preserves all data bit-for-bit.
- Restoring an archive with an older `schema_version` triggers `MigrationRunner` correctly.
- Restoring an archive with a *newer* `schema_version` than the app supports is refused with a clear message (never silently misread).

**Definition of Done:** Full backup/restore is reliable and destructive-operation-gated exactly per the architecture's security requirements.

---

## Phase 13 — Accounting Year Export/Import

**Goal:** The most complex remaining feature — self-contained, UUID-aware year export/import.

**Runnable state:** Export a single accounting year to a ZIP; import it into the same or a different database, with client UUID matching/linking behaving exactly per the approved design.

**Files to add:**
```
lib/services/export_import_service.dart
lib/presentation/features/backup/screens/year_export_screen.dart
lib/presentation/features/backup/screens/year_import_screen.dart
```

**Tests:**
- Export produces a ZIP containing exactly the selected year's invoices/payments/attachments plus only the referenced clients.
- Import of a client UUID that already exists in the target DB links to it (no duplicate, existing contact info preserved).
- Import of an unrecognized client UUID creates a new client.
- Importing a year whose *name* collides with an existing year in the target DB is disambiguated (e.g., "2026 (imported)") rather than merged.

**Definition of Done:** A full export→import round trip between two separate app installs behaves correctly, including the client-linking edge cases — this is the highest-risk feature in the app and should not ship until every case above has a passing test.

---

## Phase 14 — Hardening & Polish

**Goal:** Close every gap left open for velocity during Phases 3–13.

**Tasks:**
- Audit every repository method for consistent `Result<T>`/`AppFailure` usage (Phase 1's primitives, applied everywhere by now).
- Confirm `ReauthGuard` wraps every destructive action app-wide (year delete, full restore, year import overwrite scenarios).
- Add empty-state widgets to every list screen (no clients yet, no invoices yet, etc.).
- Add loading states consistently via `AsyncValue` handling in every screen.
- Responsive layout pass: verify usable layouts on both a narrow Android phone width and a wide Windows desktop window.
- Fill any unit test gaps flagged during the above audit, particularly around Domain Services edge cases.

**Definition of Done:** No screen shows a raw exception or an unstyled blank list; every destructive action requires re-authentication; the app feels equally usable on both platforms.

---

## Phase 15 — Packaging & Release

**Goal:** Ship it.

**Tasks:**
- App icons and splash screens for both platforms.
- `flutter build windows` — verify a clean install/run on a machine without the Flutter SDK.
- `flutter build appbundle` (and/or APK) — signing configuration, verify install on a physical Android device.
- Final manual QA pass: fresh install → password/recovery setup → create year → add client → add invoice → add payment → view ledger → generate PDF → full backup → restore → year export/import.
- Tag the release and record the shipped `schema_version` in `CHANGELOG.md`, per the architecture's migration-tracking recommendation.

**Definition of Done:** Installable builds exist for both platforms and have been smoke-tested end to end against the full spec, not just individual features in isolation.

---

## Cross-Cutting Notes

- **Testing grows with the app, not after it.** Each phase above adds its own tests as it goes — there is no separate "write tests" phase, because retrofitting tests onto 13 phases of untested code is a much bigger job than writing them alongside, especially for the money-calculation logic in Phases 5–7.
- **`ReauthGuard` is built once (Phase 2), reused three times** (Phase 3 year deletion, Phase 12 restore, Phase 13 import-overwrite) — resist the urge to special-case password re-entry per screen.
- **The active-year provider (Phase 3) is the one piece of global app state** everything downstream depends on — once it's in place, switching years should visibly refresh every year-scoped screen automatically, and this is worth manually verifying at the end of Phase 3 before building anything on top of it.
- **If priorities shift**, Phases 8–11 (Dashboard, Reports, Settings, PDF) are the safest to reorder — none of them depend on each other, only on the Client Ledger (Phase 7) being done. Phases 12–13 should not be pulled earlier; they're intentionally last because they're the most destructive and benefit most from a data model that's already been exercised by real use.
