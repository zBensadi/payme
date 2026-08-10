# PayMe V2 Comprehensive Regression Testing Checklist

This checklist must be executed to verify system stability across all core domains.

## 1. Authentication
- [ ] Fresh installation launches to Splash screen, then either Language Select or Login screen.
- [ ] Invalid credentials show appropriate Firebase error messages.
- [ ] Successful login routes to Dashboard (if bootstrapped) or Bootstrap Screen (if new).
- [ ] Logout securely clears session and returns to Login.
- [ ] Token expiration and automatic refresh work without crashing the Flutter engine.

## 2. Business Setup (Bootstrap)
- [ ] New user login intercepts routing and shows `FirebaseBootstrapScreen`.
- [ ] Submitting a valid business name executes an atomic Firestore `WriteBatch`.
- [ ] Firestore correctly populates `users`, `businesses`, `roles`, `business_settings`, and `activity_logs`.
- [ ] UI automatically routes to Dashboard after successful bootstrap.
- [ ] Existing user login correctly bypasses the Bootstrap screen.

## 3. Localization & RTL (Alpha 12)
- [ ] First launch (no language stored) displays Language Selection screen before login.
- [ ] Changing language in Settings immediately updates UI without requiring a restart.
- [ ] Selecting Arabic automatically mirrors the UI to RTL layout (drawers, icons, navigation).
- [ ] Selected language persists across app restarts via `shared_preferences`.

## 4. Accounting Years (Alpha 10)
- [ ] Creating a new Accounting Year locally marks it `is_dirty = true` and pushes to Firestore.
- [ ] Renaming or setting an active year updates `updated_at`, `is_dirty`, and syncs.
- [ ] A fresh installation correctly downloads all Accounting Years from Firestore before Invoices.
- [ ] Conflict resolution safely handles active year collisions across devices using `updated_at`.
- [ ] Multi-device sync: Device A creates a year, Device B receives it, Device A sees any updates.

## 5. Clients (Alpha 08)
- [ ] Creating/updating a Client pushes changes to Firestore.
- [ ] Deleting a client performs a soft-delete (`is_deleted = 1`) and pushes to Firestore.
- [ ] Soft-deleted clients are removed from the active UI lists but preserved for referential integrity.
- [ ] Fresh install pulls all clients down successfully.

## 6. Invoices (Alpha 09)
- [ ] Creating/updating an Invoice pushes changes to Firestore.
- [ ] Invoices sync *after* Clients and Accounting Years (low priority) to satisfy SQLite Foreign Keys.
- [ ] Invoice soft deletes operate correctly.
- [ ] Fresh install downloads invoices and successfully inserts them without SQLite `DatabaseException` (FK constraint failed).
- [ ] Global Invoice List UI automatically invalidates and refreshes when `InvoiceRepository` updates.

## 7. Payments (Alpha 11)
- [ ] Payments domain includes `is_deleted` and `updated_at` properties.
- [ ] Creating/updating a payment marks it dirty and syncs to Firestore (metadata only, no binary attachments yet).
- [ ] Soft-deleting a payment updates its status and pushes.
- [ ] Sync ordering ensures Payments sync *after* Invoices to satisfy Foreign Keys.

## 8. Synchronization & Resilience
- [ ] Offline mutations queue up locally (is_dirty = 1).
- [ ] Reconnecting to the network automatically drains the dirty queue.
- [ ] Background `SyncService` correctly pulls remote changes and emits `RepositoryEvent(remoteSynchronization)`.
- [ ] Riverpod UI automatically rebuilds upon remote synchronization via `invalidateOnRepositoryChange`.
- [ ] Developer Reset Database button correctly wipes SQLite, closes connections, and terminates the app.
