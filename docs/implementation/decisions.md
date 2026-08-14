# Implementation Decisions

*This document permanently records implementation decisions that affect the project, complementing the initial Architecture document.*

## 2026-08-01: Progressive Dependency Management
**Decision**: Adopt progressive dependency management instead of installing all roadmap-defined packages in Phase 0.
**Reason**: Reduces initial project bloat and clarifies the exact architectural moment each package is required.
**Alternatives Considered**: Adding all dependencies in Phase 0 as initially written in the roadmap.
**Impact**: Dependencies (like `sqflite`, `pdf`, `archive`) will be installed iteratively in the specific phases where they are first needed.

## 2026-08-01: Avoid Placeholder Files
**Decision**: Do not create empty architectural placeholder directories or files.
**Reason**: Keeps the project tree clean and meaningful. Empty files add noise to the repository.
**Alternatives Considered**: Creating the complete `lib/` tree with empty files during Phase 0.
**Impact**: Directories and files will only be created when they have actual implementation code inside them.

## 2026-08-11: Authentication Routing Layer
**Decision**: Implement a lightweight root `users/{uid}` pointer collection in Firestore for routing, decoupling it from the canonical `AppUser` domain model.
**Reason**: Relying on `collectionGroup` queries for business discovery required complex indexing and posed performance/scale risks. The routing pointer provides an O(1) idempotency check during bootstrap and subsequent logins. 
**Details**:
- `users/{uid}` is strictly a routing pointer (contains `businessId`, `roleId`, `updatedAt`, `schemaVersion`) and is NOT a domain model.
- Canonical user data exclusively resides under `businesses/{businessId}/users/{uid}`.
- Bootstrap is the ONLY workflow permitted to write directly to both Firestore and SQLite. It seeds SQLite with the canonical `AppUser` and `UserRole` directly.
- `CurrentAppUser` (provided by `currentUserProvider`) remains purely SQLite-driven.
- `SyncService` is strictly responsible for ongoing synchronization, remaining completely decoupled from the initial identity provisioning process.

## 2026-08-11: Fail-Closed Authorization Philosophy
**Decision**: Missing canonical domain data routes to a dedicated 'Account Data Error' view rather than attempting fallback provisioning or registration.
**Reason**: Prevents users from accidentally overwriting pointers or creating duplicate businesses during edge-case recovery or data corruption events.
**Details**: The bootstrap flow will unconditionally block access and only permit Retry or Logout actions if the Firestore routing pointer exists but the corresponding `businesses/{businessId}/users/{uid}` canonical data is missing.

## 2026-08-11: Strict Tenant-Scoped Firestore Architecture
**Decision**: All domain data, including Business Settings, must reside strictly under `businesses/{businessId}/...`.
**Reason**: Simplifies security rules, enforces data isolation per tenant, and eliminates cross-tenant pollution.
**Details**:
- Business settings migrated from the legacy `business_settings/{businessId}` top-level collection to `businesses/{businessId}/settings/main`.
- All other repositories (`roles`, `users`, `clients`, `accounting_years`, `invoices`, `payments`, `client_visibility`) exclusively read/write under their `businesses/{businessId}/<collection>` path.

## 2026-08-12: AppUser.businessId Persistence in SQLite
**Decision**: Explicitly persist `businessId` on the `users` SQLite table (`v11` migration) and serialize it within `AppUserModel`.
**Reason**: While `businessId` is implicit in the Firestore path, the local SQLite structure is flat. The offline-first `currentUserProvider` relies purely on SQLite to reconstruct the domain boundary. Omitting `businessId` in SQLite resulted in the `SyncService` lacking context upon cold offline reboots.
**Details**: Allows instant and reliable business context restoration without full network synchronizations.
