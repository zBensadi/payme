# Alpha 17 Security Hardening

## Objective
Alpha 17 focuses on transitioning PayMe V2 from a permissive, client-enforced authorization model to a robust, server-authoritative Firestore backend.

## Current Limitation (Alpha 16)
In Alpha 16, the Firestore rules are:
```javascript
allow read, write: if request.auth != null;
```
This means any authenticated user can read or modify data belonging to any other business or escalate their privileges.

## Architectural Decisions
1. **Firestore Rules as the Boundary**: Firestore Rules are the definitive security perimeter. The local SQLite and Flutter UI are considered untrusted.
2. **Server-Authoritative Fields**: Fields such as `isOwner`, `isSuperAdmin`, `businessId`, and `roleId` are protected and cannot be freely modified by clients.
3. **Custom Claims**: `businessId` will be stored in Custom Claims to provide zero-cost tenant isolation.
4. **Cloud Functions**: Operations like business bootstrap (establishing the first owner) and accounting year deletion (verifying invoice invariants) will be moved to trusted Cloud Functions.
5. **Phase 2 Implementation**:
    - **Intra-Tenant Reads**: To support PayMe's offline-first architecture, `SyncService` pulls collections in bulk. Therefore, intra-tenant reads for foundational collections (`users`, `roles`, `settings`, `clients`, `invoices`, `payments`, `accounting_years`) are broad (`allow read: if hasBusinessClaim(businessId)`). This avoids exceeding the Firestore 10-get limit per rule evaluation. Cross-tenant reads remain strictly denied.
    - **Granular Writes**: Writes are single-document operations and enforce strict RBAC via `hasRolePermission()`. This properly safeguards the database against unauthorized modifications.
6. **Phase 3 Implementation**:
    - **Trusted Backend**: Implemented `bootstrapBusiness`, `provisionUser`, and `deactivateUser` Cloud Functions.
    - **Bootstrap Atomicity & Concurrency**: Uses Firestore `runTransaction` to safely guard against concurrent duplicate business creations.
    - **Authoritative Provisioning**: The `provisionUser` function assigns Auth Custom Claims and performs explicit rollback cleanup if Firestore writes fail. It actively strips `isOwner` and `isSuperAdmin` to prevent escalation.
    - **Backfill Tooling**: A `backfill_claims.js` script handles legacy data validation and establishes explicitly trusted sources for Custom Claims.

## Migration Sequence (Deploying Alpha 17 to Production)
To safely deploy the Phase 2/3 security enhancements to a live project without breaking existing users, follow this sequence:
1. **Backfill Custom Claims**: Execute `node tools/migrations/backfill_claims.js --execute` using the Admin SDK. This inspects legacy client-written data and mints authoritative Custom Claims for all users.
2. **Verify Claims**: Verify in the Firebase Console / Dashboard that users have the correct `businessId` and `isOwner` claims.
3. **Force Token Refresh**: Legacy client tokens may not contain the new Custom Claims immediately. If necessary, trigger an application-wide forced sign-out, or allow tokens to naturally expire (1 hour) before applying rules.
4. **Deploy Security Rules**: Once claims are populated and active, deploy the restrictive `firestore.rules`.
5. **Test & Monitor**: Run a subset of critical client operations (e.g., sync) and monitor Firebase Crashlytics for unexpected `permission-denied` errors.

## Finalized Functional Behavior
In addition to the security architecture, Alpha 17 includes the following finalized functional behaviors and stabilization fixes:
- **Dashboard Synchronization**: The dashboard now listens to the global `syncTriggerProvider` for `localMutation` events, ensuring that creating clients or invoices updates the dashboard totals and counts immediately.
- **User Soft Deletion & Reactivation**: Users can be deactivated (soft deleted). A Cloud Function (`reactivateUser`) allows reactivating users by setting `isActive: true` and simultaneously removing their `revoked_tokens` document.
- **Client Visibility**: The `SecuredClientRepository` now automatically bypasses visibility restrictions for the business Owner. The Owner is also perpetually selected and disabled in the `ClientForm` visibility checklist to enforce this invariant.
- **Audit Metadata (Created By / Last Edited By)**: Implemented `user_lookup_provider.dart` to resolve UIDs into human-readable Display Names (or Emails) across the application, making audit trails visible on the Client and Invoice detail screens.
- **Create User Localization**: Removed hardcoded English strings in the `UserEditorScreen` and replaced them with localized `.arb` keys for English, French, and Arabic.
- **Firebase Storage Logo Synchronization**: Business logos are now synchronized via Firebase Storage. A strict 2 MB limit is enforced on uploads. The PDF generation correctly utilizes authenticated fallback downloads if the local cache is empty.
- **Storage Security Model**: `storage.rules` enforces that only the business Owner can upload/modify the business logo, while any authorized user within the same business can read it. Cross-tenant reads are blocked.

## Test Suite Status
The stabilization pass of Alpha 17 verified the following test baseline:
- **172 passing Flutter tests**
- **68 passing automated security tests** via the Firebase Local Emulator Suite
- **1 intentionally skipped/pending test for future development**

## Future Phases
- **Client Visibility**: Stronger server-side visibility rules (via scoped queries or Cloud Functions) are a future roadmap item.
- **Deactivation (Revoked Tokens)**: Revocation enforcement (handling the gap between deactivation and token expiry) will be finalized in later iterations.
- **SQLite Tampering Reconciliation**: `SyncService` will be updated to handle `permission-denied` gracefully by forcing a local reconciliation pull instead of retrying indefinitely.
