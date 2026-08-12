# Stage 3: Offline-First Architecture & Authentication Routing

## Objectives
- Establish the offline-first authorization architecture relying on SQLite as the single source of truth for the local application state.
- Implement a robust Authentication Routing Layer utilizing a root `users/{uid}` pointer collection in Firestore to direct authenticated users to their canonical domain data.
- Enforce strict fail-closed security for corrupted data states, preventing accidental duplicate business creation.
- Seamlessly transition from a brand-new registration, to an existing session, and to the Dashboard.

## Finalized Bootstrap Flow & Routing Layer
The application implements a decoupled routing layer, separating identity resolution from domain data.
1. **Firebase Authentication:** Determines the user's base identity (`uid`).
2. **Routing Pointer (`users/{uid}`):** A lightweight document in the root collection that answers: *"Which business does this user belong to?"* It contains only `businessId`, `roleId`, `updatedAt`, and `schemaVersion`. **This is not a domain model.**
3. **Canonical Domain Data:** The actual User and Role models reside under `businesses/{businessId}/users/{uid}` and `businesses/{businessId}/roles/{roleId}`.
4. **Idempotency & Session Recovery:** During startup (`FirebaseBootstrapScreen.initState`), the `checkAndRecoverSession` function reads the pointer. If the pointer and canonical domain data exist, it automatically provisions SQLite and routes the user to the Dashboard.
5. **Brand-New Registration:** If the pointer does not exist, the user is presented with the Bootstrap form to create a new business. The business, role, user, and pointer are all written atomically in a single Firestore `WriteBatch`.

## Fail-Closed Philosophy
If the routing pointer exists but the canonical domain documents (User or Role) are missing, the application enters a corrupted state. 
- The bootstrap form is explicitly **hidden** to prevent the user from accidentally creating a second business and overwriting the pointer.
- A dedicated **Account Data Error** view is rendered, offering only "Retry" and "Logout" actions.
- The user remains authenticated but is safely blocked from entering the system.

## SQLite Seeding Process
Bootstrap is the **only workflow** permitted to write directly to both Firestore and SQLite. 
- Once the initial provisioning or session recovery is complete, the canonical `AppUser` and `UserRole` are seeded directly into the local SQLite database.
- `CurrentAppUser` (provided by `currentUserProvider`) remains purely SQLite-driven. It reacts to the seeded data and authorizes the user.
- `SyncService` starts subsequently, fully decoupled from the identity provisioning logic.

## Verification Results
- All static analysis (`flutter analyze`) and automated tests (`flutter test`) pass successfully.
- Verified across 8 distinct edge cases including brand-new registration, crash recovery, new device login, missing pointers, and corrupted domain data.
