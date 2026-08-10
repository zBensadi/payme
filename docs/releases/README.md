# PayMe V2 Release History

This document tracks the evolution of PayMe V2 from an offline-first SQLite application into a robust, Firebase-integrated SaaS. The development was split into incremental Alpha releases.

## Current Project Status
**Status:** Alpha 13 Completed
The application currently supports full offline-first functionality with reactive Firestore synchronization for Clients, Accounting Years, Invoices, Payments, and Settings. It features a complete authentication and business bootstrap flow, along with full runtime localization (English, French, Arabic) and RTL support.

## Current Architecture Summary
- **Clean Architecture:** Strict separation of Data, Domain, and Presentation layers.
- **Local Persistence:** Offline-first SQLite (using `sqflite_common_ffi` for desktop) with `is_dirty` and `updated_at` synchronization metadata.
- **Remote Persistence:** Firebase Firestore for cloud syncing and `firebase_auth` for identity.
- **State Management:** Riverpod (`Notifier` / `AsyncNotifier`).
- **Routing:** GoRouter with reactive authentication and bootstrap guards.
- **Synchronization Engine:** Background `SyncService` that orchestrates push/pull between local SQLite and Firestore, prioritizing offline mutations with Last-Write-Wins (LWW) conflict resolution.

## Alpha Releases

- [Alpha 01: Firebase Initialization](./alpha_01.md)
  Initial integration of the Firebase project, Firebase CLI setup, and core infrastructure scaffolding.
- [Alpha 02: Firebase Foundation](./alpha_02.md)
  Setup of the underlying Firebase architecture and service configurations required for the V2 transition.
- [Alpha 03: Authentication Foundation](./alpha_03.md)
  Implementation of `firebase_auth` (Email/Password), reactive `FirebaseAuthController`, and secure routing (Splash → Login → Dashboard).
- [Alpha 04: Business Bootstrap](./alpha_04.md)
  Atomic Firestore-based setup for new users using `WriteBatch` to provision businesses, roles, settings, and initial logs.
- [Alpha 05: Current User Profile Layer](./alpha_05.md)
  Decoupling authentication from user profile fetching via `UserProfileRepository` and robust Riverpod caching.
- [Alpha 06: Synchronization Infrastructure](./alpha_06.md)
  Foundation of the `SyncService`, conflict resolvers, and domain events for offline-first replication.
- [Alpha 07: Synchronization Engine Enhancements](./alpha_07.md)
  Refining the synchronization engine, background debounce timers, and change publishers.
- [Alpha 08: Client Synchronization](./alpha_08.md)
  Integration of the `ClientRepository` into the sync engine, utilizing soft deletes and priority ordering.
- [Alpha 09: Invoice Synchronization](./alpha_09.md)
  Integration of the `InvoiceRepository` with synchronization metadata, uncovering strict SQLite foreign key dependencies.
- [Alpha 10: Accounting Year Synchronization](./alpha_10.md)
  Resolving fresh-install FK constraint failures by synchronizing `AccountingYearRepository` before Invoices, preserving hard-deletes.
- [Alpha 11: Payments Synchronization](./alpha_11.md)
  Bringing the Payments domain up to offline-first parity with soft deletes, sync timestamps, and metadata syncing.
- [Alpha 12: Localization Infrastructure](./alpha_12.md)
  Integrating `LocaleController` with `shared_preferences` for runtime language switching, RTL automatic mirroring, and a first-launch language selector.
- [Alpha 13: UX Polish & Synchronization Finalization](./alpha_13.md)
  Finalizing the offline-first replication logic by stabilizing the settings synchronization, refining the PDF generation layout, and polishing the overall UX for a premium user experience on fresh installs and bootstrap sequences.
