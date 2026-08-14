# PayMe Release: v2.0.0-alpha.15
**Date:** 2026-08-12
**Codename:** Offline-First Authorization Architecture Stabilized

## Overview
Alpha 15 finalizes and freezes the architectural foundations laid out in Stage 3 and 3.1. It solidifies the tenant-scoped offline-first model, ensuring strict data boundaries and deterministic identity provisioning across both Firestore and SQLite.

## Core Architectural Milestones Reached & Frozen
- **Authentication Routing Layer:** The `users/{uid}` collection acts exclusively as a lightweight pointer for routing and idempotency. It is strictly separated from canonical domain data.
- **Fail-Closed Authorization:** Missing canonical data gracefully errors out to a dedicated 'Account Data Error' screen, preventing destructive duplication loops.
- **Direct SQLite Seeding:** The `BootstrapController` holds the exclusive authority to directly seed `AppUser` and `UserRole` models into the local SQLite database upon session creation or recovery.
- **SQLite Single Source of Truth:** `CurrentAppUser` relies purely on local SQLite to establish identity, allowing full offline capability immediately after bootstrap.
- **Tenant-Scoped Architecture:** Every single domain repository, now including Business Settings, has been completely migrated to the `businesses/{businessId}/*` hierarchy.
- **AppUser.businessId Persistence:** The local `users` table now natively stores the `business_id` (migration `v11`), ensuring the `SyncService` maintains business context upon cold boots without needing a network connection.

## Known Deferred Features
The following features were intentionally postponed and will be addressed in future milestones or the Administration Module:
- **User Invitation Workflow**: Email generation and dispatch for inviting secondary staff users.
- **Invitation Acceptance Flow**: Secure token parsing and registration flow for invited staff.
- **Activity Log Backend**: The `ActivityLogs` domain model, remote datasource, and local datasource remain unimplemented.
- **Advanced Role Assignments**: Dynamic assignment or revoking of custom roles to staff.
- **Client Visibility UI**: The management interface for restricting which clients specific staff members can view.

## Notes
The V2 Offline-First Architecture is now **STABLE/FROZEN**. Stage 4 (Management UI) and the Administration Module will build entirely upon these immutable foundations.
