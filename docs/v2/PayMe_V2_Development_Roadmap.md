# PayMe — Version 2 Development Roadmap

### Solo-Developer, Milestone-Based Implementation Plan for Cloud Mode

**Status:** Implementation planning document. Depends on four frozen, approved documents — `PayMe_V2_Architecture.md`, `PayMe_V2_Architecture_Review.md`, `PayMe_V2_Database_Design.md`, `PayMe_V2_Synchronization_Design.md` — none of which are revisited, redesigned, or second-guessed here. This document answers one question only: **in what order, and by what concrete steps, does a solo developer turn the already-approved design into a shipped product?**
**Continues:** V1's `PayMe_Development_Roadmap.md` numbering (Phases 0–15, shipped). This document picks up at **Phase 16**, matching the phase skeleton already sketched in `PayMe_V2_Architecture.md` Section 22 — that skeleton is expanded here into full implementation detail, not altered in sequence or intent.
**Audience:** The same solo developer who built and shipped V1.

---

## 1. Development Philosophy

These are the operating rules for every phase below. Where a phase's plan seems to conflict with one of these, the rule wins — these are inherited constraints, not suggestions to weigh against convenience.

- **Preserve Clean Architecture exactly as V1 established it.** Presentation depends on Domain; Domain depends on nothing; Data implements Domain's repository interfaces. Nothing in V2 changes this direction of dependency — cloud mode is a new implementation slotted into an existing layer, never a reason to reach across layers.
- **Repository interfaces are frozen, not just stable.** `InvoiceRepository`, `ClientRepository`, `PaymentRepository`, `AccountingYearRepository`, `SettingsRepository` keep their exact V1 method signatures (`PayMe_V2_Architecture.md` Section 9). If a phase below seems to need a new repository method, that is a signal to stop and check the frozen architecture again before writing it — the whole design's value collapses if this seam moves.
- **Firebase never appears above the repository boundary.** No `import 'package:cloud_firestore/...'` — or its Windows-facade equivalent, `dio` calls to `syncPush`/`syncPull` — anywhere in `lib/presentation/` or `lib/domain/`. If a Notifier or screen needs to know something Firebase-shaped, that is a defect, not a shortcut, and the fix is to push the concern down into the repository or `SyncEngine`, never to relax this rule for convenience.
- **Every phase leaves the app in a runnable, compiling state.** This is V1's own standard (`PayMe_Development_Roadmap.md`'s existing phase discipline), carried forward unchanged: no phase is checked in half-built. A phase that must span more than one working session is broken into smaller phases rather than committed in a broken intermediate state.
- **Every phase is independently testable**, per the testing block defined for it below (Section 6 gives the cross-cutting version of this). A phase without a way to verify it did what it claims is not a complete phase.
- **Implement incrementally, in dependency order, never speculatively.** A phase does not build infrastructure "for later" beyond what the very next phase needs — this mirrors V1's own restraint (no use-case-per-action classes, no premature abstraction) and keeps a solo developer's in-flight mental model small at any given time.
- **Local mode is never put at risk.** Every phase from 16 onward is additive to a shipped, real product with real users. A phase that could regress local-mode behavior is either restructured to avoid that risk or explicitly gated behind `appMode == cloud` so a local-mode user's experience is provably untouched.
- **No new technology enters through the back door.** The technology list is exactly what `PayMe_V2_Architecture.md` Section 4–5 already named. If an implementation phase seems to want something not on that list (a new package, a new backend service, a new state-management approach), that is treated as an architecture question, not a roadmap question, and is out of this document's authority to decide.

---

## 2. Prerequisites

Everything in this section is prepared **before** Phase 16's first line of code, because several later phases assume these exist and are correctly configured. Doing this once, carefully, up front avoids re-doing configuration mid-phase later.

### 2.1 Firebase Project

- Create the **dev** Firebase project first; the **prod** project is created just before Phase 28 (release hardening), not on day one — no reason to pay for or maintain a production project's worth of configuration months before it's needed. Both use the CLI project-alias mechanism named in `PayMe_V2_Architecture.md` Section 19.
- Record both project IDs somewhere durable outside of source control (a personal password manager or notes app is sufficient for a solo developer) — they are referenced repeatedly through setup, not just once.

### 2.2 Authentication

- Enable the **Email/Password** provider in the Firebase Console for the dev project (`PayMe_V2_Architecture.md` Section 5/6 — this is the only provider V2 uses).
- No other provider is enabled — enabling and then not using Google/Apple/phone sign-in would be scope not asked for by the frozen architecture.

### 2.3 Firestore

- Create the Firestore database in **Native mode** (not Datastore mode) for the dev project, in a region appropriate to the business's location.
- Do not write any Security Rules yet beyond the default deny-all — Rules are Phase 23's deliverable (Section 5 below), not a prerequisite. A deny-all default is safe to leave in place while nothing depends on it yet.

### 2.4 Storage

- Enable Firebase Storage for the dev project. No bucket structure needs to exist yet — the `logos/`, `attachments/`, `exports/`, `backups/` prefixes (`PayMe_V2_Database_Design.md` Section 6) come into existence the first time something is written to them; nothing needs to be pre-created.

### 2.5 Cloud Functions

- Provision the Functions project skeleton (`functions/` directory, correct runtime/SDK version pinned per `PayMe_V2_Architecture.md` Section 19's infrastructure-as-code approach) — but do not write any actual Function logic yet. An empty, deployable skeleton is the Phase 16 deliverable; real Functions arrive in the phases that need them (18 onward).
- Confirm the Firebase project is on a billing plan that supports Cloud Functions (the Blaze pay-as-you-go plan is required by Firebase for any Functions usage) — this is a real prerequisite step, easy to discover too late otherwise.

### 2.6 FlutterFire CLI

- Install the FlutterFire CLI and run configuration against the **dev** project only, generating the `firebase_options.dart` (or equivalent) for Android. Windows does not go through FlutterFire CLI configuration in the same way, since it never talks to Firebase SDKs directly (`PayMe_V2_Architecture.md` Section 4) — its configuration is whatever the Cloud Functions facade's HTTPS endpoint and `dio` client need (a base URL and any App Check token plumbing), not a FlutterFire-generated file.

### 2.7 Secrets and Environment Configuration

- Establish a clear **dev vs. prod** switch at the app level from day one (an `AppEnvironment` concept, or equivalent — the exact mechanism is an implementation detail, not an architectural one, but the *existence* of the switch is a prerequisite so that no later phase is tempted to hardcode a project ID).
- No Firebase Admin SDK service-account keys are ever bundled into the Flutter app — those live only inside Cloud Functions' own execution environment, never on a client device. This is stated here as a hard prerequisite rule, not merely a preference, because it is the kind of mistake that's expensive to unwind after the fact.
- `firestore.rules`, `firestore.indexes.json`, and `functions/` live in the same git repository as the Flutter app from the very first commit that touches any of them (`PayMe_V2_Architecture.md` Section 19) — not a separate repository, not hand-edited later from the console.

### 2.8 Android

- Confirm the existing V1 Android build already meets whatever minimum SDK version the current Firebase Android SDKs require (check at prerequisite time, not discovered as a build failure mid-Phase-16) — V1's Android target may need a minor bump; if so, that bump is itself a zero-risk, independently testable micro-step done here, before any Firebase code exists to depend on it.

### 2.9 Windows

- No Firebase-specific Windows setup is needed at this stage, by design (`PayMe_V2_Architecture.md` Section 4 — Windows never holds a Firebase SDK dependency at all). What *is* a prerequisite: confirm `dio` (already a V1 dependency, earmarked in V1 Section 19 for exactly this future use) is present and at a version compatible with whatever App Check token attachment and error-handling approach Phase 21 will need.

---

## 3. Git Strategy

- **`main`** remains the branch that always reflects the currently-shipped, released state of the app — V1 today, V1+V2 once cloud mode ships. `main` is never force-pushed and never contains work-in-progress.
- **`v2-firebase`** is a long-lived integration branch, branched from `main` at the start of Phase 16, into which every V2 phase merges as it completes. `v2-firebase` is expected to be broken *between* phase merges is not acceptable — the "every phase compiles and is testable" rule (Section 1) applies to this branch's history, not just to `main`'s. `v2-firebase` is rebased onto `main` periodically (e.g., whenever a V1 hotfix is released to production users during the V2 build) so it never drifts dangerously far from what's actually shipping.
- **Feature branches**, one per phase (or, for a large phase, one per clearly-separable sub-step within it), branched from `v2-firebase`, named consistently (e.g., `v2/16-firebase-scaffolding`, `v2/20-sync-engine-android`). A feature branch's lifetime is one phase's worth of work — it is not kept alive across multiple phases.
- **Merge strategy:** feature branch → `v2-firebase` via a normal merge (or squash, at the developer's preference — for a solo developer working alone, this is a matter of personal git-history taste, not a correctness concern) once that phase's Definition of Done (Section 9) is met. `v2-firebase` → `main` happens only at the milestone boundaries named in Section 8 (Beta, RC1, RC2, Stable) — not after every individual phase, since intermediate phases are not independently useful to a released user (an app with `SyncEngine` scaffolding but no Security Rules yet is not a state anyone should be running in production).
- **Tags:** a lightweight tag at the completion of every phase on `v2-firebase` (e.g., `v2-phase-16-complete`) — cheap, and gives a precise rollback point if a later phase's work needs to be reverted back to a known-good state without losing the phases before it. Milestone tags on `main` (`v2-beta-1`, `v2-rc-1`, `v2.0.0`) follow normal release-tagging conventions.
- **Release candidates:** cut from `v2-firebase` once Phase 28 (hardening) is underway — an RC branch (`release/v2-rc1`) is a short-lived stabilization branch, receiving only bug fixes found during RC testing, never new feature work; a fix landing on an RC branch is cherry-picked back onto `v2-firebase` so the two never diverge permanently.

---

## 4. Development Phases

Each phase below follows the same structure. Phase numbers, names, and dependency order match `PayMe_V2_Architecture.md` Section 22 exactly — nothing here reorders or renames what was already frozen there; this section is that skeleton's detail, not a replacement for it.

---

### Phase 16 — Firebase Project Scaffolding

**Goal:** Firebase infrastructure exists and deploys cleanly, with zero app-code changes yet (`PayMe_V2_Architecture.md` Section 22, Phase 16's own note: "infrastructure only").

**Files affected:**
```
firebase.json
firestore.rules              (deny-all placeholder)
firestore.indexes.json       (empty)
functions/                   (skeleton project, no real Functions yet)
android/app/google-services.json   (dev project)
lib/core/config/app_environment.dart   (new — dev/prod switch, Section 2.7)
```

**Repositories affected:** None.

**Services affected:** None.

**Testing required:**
- **Manual:** `firebase deploy` succeeds against the dev project for an empty Functions skeleton and placeholder Rules/indexes files, from a clean checkout.
- **Emulator:** confirm the Firestore + Functions emulator suite starts locally (needed for every phase from 20 onward — worth validating this works now, cheaply, before anything depends on it).
- No unit/integration tests yet — there is no app logic to test.

**Possible risks:** Firebase CLI / project-alias misconfiguration silently pointing dev work at the wrong project. Mitigated by the explicit dev/prod `AppEnvironment` switch (Section 2.7) being the *only* thing that selects a project, never an ambient default.

**Expected deliverables:** A deployable, empty Firebase project pair; `AppEnvironment` compiles and defaults to dev; V1 app behavior is completely unchanged (this phase touches no existing file that affects local mode).

**Suggested Git commit points:** One commit for the Firebase config files; one for `AppEnvironment`.

**Suggested merge point:** Into `v2-firebase` once `firebase deploy` succeeds against dev from a fresh clone (proves the setup is reproducible, not just working on the developer's current machine).

**Suggested checkpoint:** Tag `v2-phase-16-complete`.

---

### Phase 17 — AppMode + Firebase Authentication

**Goal:** A business can choose local or cloud mode; in cloud mode, Firebase Authentication backs the existing `AuthService` interface (`PayMe_V2_Architecture.md` Section 6, 22).

**Files affected:**
```
lib/domain/entities/app_mode.dart                        (new — local | cloud enum)
lib/presentation/providers/app_mode_provider.dart          (new)
lib/services/auth_service.dart                            (interface — confirm unchanged)
lib/services/firebase_auth_service_impl.dart               (new — cloud-mode AuthService impl)
lib/data/repositories_impl/local_auth_service_impl.dart     (rename/confirm — existing V1 impl, unchanged behavior)
lib/presentation/features/onboarding/screens/choose_mode_screen.dart   (new — first-run only)
```

**Repositories affected:** None directly — this phase is `AuthService`, not a repository, matching `PayMe_V2_Architecture.md` Section 9's note that `AuthService` "gains a Firebase-backed implementation behind its existing interface."

**Services affected:** `AuthService` (new cloud-mode implementation added; V1's local implementation untouched); `ReauthGuard` gains a Firebase-backed re-authentication path (`reauthenticateWithCredential`) alongside its existing local-password path (`PayMe_V2_Architecture.md` Section 6).

**Testing required:**
- **Unit:** `AppMode` selection persists correctly to `business_settings.appMode`; `FirebaseAuthServiceImpl` wraps `authStateChanges()` correctly (mockable via a fake Firebase Auth instance).
- **Integration:** against the Auth emulator — sign-up, sign-in, sign-out, wrong-password rejection, password-reset-via-email flow initiation.
- **Manual:** on a real dev-project device, confirm a created account can log in and `authStateProvider` reflects it; confirm `ReauthGuard`'s Firebase path is invoked, not the local path, when `appMode == cloud`.
- **Regression:** full local-mode auth test suite (V1 Phase 2's tests) re-run unchanged and passing — this phase must not touch local-mode auth behavior at all.

**Possible risks:** Accidentally coupling `authStateProvider`'s local-mode Stream implementation to the new cloud-mode one (breaking the "single provider, seam is `AuthService`" pattern from `PayMe_V2_Architecture.md` Section 6). Mitigated by writing the local-mode regression test *first*, before touching any shared code, so a break is caught immediately.

**Expected deliverables:** First-run mode selection; a working Firebase-backed login for cloud mode; local mode provably unaffected.

**Suggested Git commit points:** `AppMode` entity/provider; `FirebaseAuthServiceImpl`; `ReauthGuard` Firebase path; mode-selection screen — four small, separately reviewable commits.

**Suggested merge point:** Into `v2-firebase` once both the cloud-mode Auth emulator suite and the full local-mode regression suite pass.

**Suggested checkpoint:** Tag `v2-phase-17-complete`. This is the first phase where manually installing a debug build and creating a real (dev-project) account is a meaningful smoke test — do it once here before moving on.

---

### Phase 18 — Roles, Permissions Catalog, Users + Custom-Claims Sync

**Goal:** The `roles`, `permissions_catalog`, and `users` collections exist and are populated at business setup; a Cloud Function keeps custom claims in sync with them (`PayMe_V2_Architecture.md` Section 8, 22; `PayMe_V2_Database_Design.md` Sections 4.2–4.4).

**Files affected:**
```
lib/domain/entities/role.dart                              (new)
lib/domain/entities/app_user.dart                           (new — distinct from Firebase's own User type)
lib/services/permission_service.dart                        (new)
lib/presentation/features/users/...                         (admin screens: user list, invite, role/override editor)
functions/src/onUserWrite.ts   (or equivalent)               (new — custom claims sync trigger)
functions/src/seedRolesAndCatalog.ts                         (new — runs once at cloud-mode onboarding)
firestore.rules                                              (add roles/, permissions_catalog/, users/ rules — still permissive/dev-only at this stage, hardened fully in Phase 27)
```

**Repositories affected:** None — per `PayMe_V2_Database_Design.md`, `roles`/`permissions_catalog`/`users` are read through `PermissionService` and dedicated admin-screen data access, not through the five frozen repository interfaces (which stayed deliberately unchanged, per Section 1's rule).

**Services affected:** `PermissionService` (new) implements `effectivePermission(user, key)` exactly as specified in `PayMe_V2_Architecture.md` Section 8.

**Testing required:**
- **Unit:** `effectivePermission` formula — role default, override present, `super_admin` bypass — all three branches.
- **Integration:** against the Functions + Firestore emulator — writing a `users/{uid}` document triggers the custom-claims Function; writing a `roles/{roleId}.defaultPermissions` change triggers a recompute for every user with that role and no override.
- **Manual:** create a second (non-`super_admin`) user in the dev project via the admin UI; confirm their custom claims reflect their role; confirm the `force_refresh` marker pattern (`PayMe_V2_Architecture.md` Section 8) actually prompts a token refresh on an already-open session.
- **Regression:** none applicable yet (no existing behavior this phase could break — purely additive).

**Possible risks:** The custom-claims trigger recomputing incorrectly for users with `permissionOverrides` (a common off-by-one-priority bug: applying role defaults *after* overrides instead of before). Mitigated by the unit test explicitly covering the override-present branch, not just the two simpler branches.

**Expected deliverables:** A working (though not yet UI-gated everywhere) permission model; the first non-`super_admin` user can be created and has a correctly resolved permission set.

**Suggested Git commit points:** Entities/`PermissionService`; the two Cloud Functions; the admin UI, as three or four separable commits.

**Suggested merge point:** Once the custom-claims emulator test suite passes and the manual second-user smoke test succeeds.

**Suggested checkpoint:** Tag `v2-phase-18-complete`.

---

### Phase 19 — Client Visibility Model

**Goal:** `clients.visibleTo` exists and is editable; the `onClientVisibilityChange` cascade trigger keeps it denormalized correctly onto invoices/payments/attachments (`PayMe_V2_Architecture.md` Section 10, 22; `PayMe_V2_Database_Design.md` Section 4.6).

**Files affected:**
```
functions/src/onClientVisibilityChange.ts                   (new)
lib/presentation/features/clients/widgets/visibility_editor.dart   (new)
lib/data/models/client_model.dart                             (extend — visibleTo, ownerUid, rc/nif/nis/art per Database Design Section 4.6)
```

**Repositories affected:** `ClientRepository` — **interface unchanged**; `HybridClientRepositoryImpl` (built properly in Phase 20, stubbed minimally here just enough to write/read `visibleTo` for this phase's own testing) begins carrying the new client fields.

**Services affected:** None new.

**Testing required:**
- **Unit:** a client's `visibleTo` write validates "at least one `true` entry" (`PayMe_V2_Database_Design.md` Section 4.6's rule).
- **Integration:** against the emulator — changing a client's `visibleTo` correctly fans out to every invoice/payment/attachment tracing back to it, in batches, including the "more than 500 documents" chunking case (can be tested with a seeded large dataset even before the Sync Engine itself exists, since this Function operates purely server-side).
- **Manual:** grant a second user access to one client in the dev project; confirm (via direct Firestore console inspection, since UI-level confirmation waits for Phase 20's sync engine) that the invoice/payment documents under that client now carry the updated map.
- **Regression:** none yet applicable (still additive, gated behind cloud mode).

**Possible risks:** The cascade trigger missing the edge case of a **newly created** invoice/payment (which must copy the *current* `visibleTo` at creation time, not wait for a subsequent client edit to populate it) — `PayMe_V2_Database_Design.md` Sections 4.7–4.9 specify "copied from client at creation," which is a distinct code path from the update-cascade trigger and easy to accidentally omit. Mitigated by an explicit test case: create an invoice under a client that already has multiple users in `visibleTo`, assert the invoice's `visibleTo` matches immediately, without any subsequent client edit.

**Expected deliverables:** Working, tested visibility cascade, independently verifiable via the emulator and the Firestore console, ahead of the Sync Engine that will make it visible in the app's own UI.

**Suggested Git commit points:** Cascade Function; client model/visibility editor UI — two commits.

**Suggested merge point:** Once the 500+-document chunking test and the creation-time-copy test both pass.

**Suggested checkpoint:** Tag `v2-phase-19-complete`.

---

### Phase 20 — Sync Engine Core (Android)

**Goal:** The highest-risk, most novel piece of V2. Dirty-row tracking, push, and pull work end-to-end on Android using the native `cloud_firestore` SDK, per `PayMe_V2_Synchronization_Design.md` Sections 2–9 in full. Built and stabilized on Android alone first, deliberately, before Windows exists (`PayMe_V2_Architecture.md` Section 22's own explicit sequencing).

**Files affected:**
```
lib/services/sync_engine.dart                                (new — the engine itself)
lib/services/sync_engine_android_transport.dart               (new — cloud_firestore-specific transport)
lib/data/repositories_impl/hybrid_client_repository_impl.dart      (new)
lib/data/repositories_impl/hybrid_invoice_repository_impl.dart     (new)
lib/data/repositories_impl/hybrid_payment_repository_impl.dart     (new)
lib/data/repositories_impl/hybrid_accounting_year_repository_impl.dart  (new)
lib/data/local/migrations/xxx_add_sync_bookkeeping.dart        (new — idx_*_is_dirty, sync_watermarks table, per Synchronization Design Section 8.5)
lib/presentation/providers/sync_state_provider.dart             (new)
lib/presentation/providers/repository_providers.dart            (extend — mode-based switch, per Architecture Section 9's example)
```

**Repositories affected:** All five frozen interfaces gain a `Hybrid*` implementation (Section 1's rule: interfaces unchanged, only new implementations added).

**Services affected:** `SyncEngine` (new, central to this phase); every `Hybrid*RepositoryImpl` depends on it per `PayMe_V2_Synchronization_Design.md` Section 2.3.

**Testing required:**
- **Unit:** dirty-flag/debounce logic; idempotent-push logic (pushing the same document twice yields the same state); conflict-decision function in isolation (`PayMe_V2_Synchronization_Design.md` Section 14's "Unit tests" row).
- **Integration/Emulator:** full push/pull cycles against the Firestore emulator, including the 500-document batching boundary and parent-before-child ordering (Synchronization Design Sections 3.2–3.3, 4.6).
- **Manual:** two physical/emulated Android devices, same dev-project account family — create a client on device A, confirm it appears on device B within the expected near-instant listener latency (this is the first phase where `PayMe_V2_Synchronization_Design.md` Section 7's realtime scenario becomes observable end-to-end).
- **Offline tests:** airplane-mode a device mid-session, make several edits, confirm they queue correctly and flush on reconnect (Synchronization Design Section 5.7).
- **Conflict tests:** the worked examples from Synchronization Design Section 6.4, both the genuine-conflict case and the "two separate payments is not a conflict" case explicitly.
- **Regression:** full local-mode test suite (all of V1's phases) re-run and passing — `Hybrid*RepositoryImpl` existing alongside `*RepositoryImpl` must not have disturbed local-mode wiring.

**Possible risks:** This is explicitly named in `PayMe_V2_Architecture.md` Section 22 as "the highest-risk, most novel piece" — allocate real schedule slack here, more than the phase's apparent size suggests, and do not proceed to Phase 21 until the realtime and offline manual tests above are both genuinely convincing, not just passing in the narrow sense. A `SyncEngine` bug here is inherited by every phase after it.

**Expected deliverables:** A working, multi-device-verified, offline-resilient sync engine on Android — cloud mode is, for the first time, actually multi-user in a way a person can watch happen.

**Suggested Git commit points:** This phase is large enough to warrant several: `SyncEngine` skeleton + state machine; push pipeline; pull pipeline; each `Hybrid*RepositoryImpl` as it's wired in; sync bookkeeping migration. Each should independently compile and pass its own slice of tests before the next is started.

**Suggested merge point:** Only after the two-device manual realtime test, the offline test, and the full local-mode regression suite all pass — this is the single most important merge gate in the entire roadmap.

**Suggested checkpoint:** Tag `v2-phase-20-complete`. Consider this checkpoint the informal "cloud mode fundamentally works" milestone, even though Windows, Storage, and hardening remain.

---

### Phase 21 — Cloud Functions Facade + Windows Repository Fork

**Goal:** Windows reaches the same data through the Cloud Functions facade, reusing the same `SyncEngine` contract with only the transport differing (`PayMe_V2_Architecture.md` Section 4, 13, 22; `PayMe_V2_Synchronization_Design.md` Sections 3.3–4.4 throughout).

**Files affected:**
```
functions/src/syncPush.ts                                    (new — callable, Admin SDK batched write + permission/visibility re-check)
functions/src/syncPull.ts                                    (new — callable, since-watermark query)
lib/services/sync_engine_windows_transport.dart                (new — dio-based)
lib/services/sync_engine.dart                                 (extend — transport selection by platform, internal to the engine, invisible above it)
```

**Repositories affected:** None new at the interface level — the existing `Hybrid*RepositoryImpl` classes gain a second internal transport path, exactly as `PayMe_V2_Architecture.md` Section 9 describes ("an internal fork... invisible above the repository boundary").

**Services affected:** `SyncEngine` (transport fork added, per `PayMe_V2_Synchronization_Design.md` Section 2.1).

**Testing required:**
- **Unit:** the Functions facade's permission/visibility re-check logic, tested identically in shape to the Rules-side logic it must stay in parity with (this is the first concrete instance of the "shared test matrix, not shared code" risk mitigation named in `PayMe_V2_Architecture.md` Section 21).
- **Integration/Emulator:** `syncPush`/`syncPull` callables tested against the Functions + Firestore emulator, including a deliberately-crafted permission-denied case (does the facade reject it the same way Rules would reject the equivalent Android write?).
- **Manual:** a real Windows build (or Windows-target debug run) performing a full cold-startup pull, a push, and a polling-interval realtime observation (create on Android, watch it appear on Windows within the ~15s default) — the concrete scenario from `PayMe_V2_Synchronization_Design.md` Section 7.1.
- **Regression:** Android sync suite from Phase 20 re-run unaffected — the transport fork must not have disturbed Android's own path.

**Possible risks:** Permission/visibility logic drifting between the Rules implementation and this Function's re-implementation (`PayMe_V2_Architecture.md` Section 21's named risk). Mitigated by writing the parity test matrix (Phase 27 formalizes this fully, but a first version of it should exist here, exercised against this phase's own callables, not deferred entirely).

**Expected deliverables:** A working Windows cloud-mode build, verified against a real dev-project multi-device scenario alongside Android.

**Suggested Git commit points:** `syncPush`/`syncPull` Functions; Windows transport; `SyncEngine` fork wiring — three commits.

**Suggested merge point:** Once the Android-vs-Windows realtime scenario is manually verified end-to-end and the Android regression suite is unaffected.

**Suggested checkpoint:** Tag `v2-phase-21-complete`.

---

### Phase 22 — Conflict-Resolution Surfacing

**Goal:** The last-write-wins mechanism (already implemented as engine logic in Phase 20) gets its user-facing side: the non-blocking "updated by someone else" notice (`PayMe_V2_Architecture.md` Section 22; `PayMe_V2_Synchronization_Design.md` Section 6.3).

**Files affected:**
```
lib/presentation/widgets/conflict_notice_banner.dart          (new)
lib/presentation/providers/conflict_notice_provider.dart       (new)
```

**Repositories affected:** None.

**Services affected:** `SyncEngine` (extended to emit a queued-notice event per Synchronization Design Section 6.3, rather than only resolving silently).

**Testing required:**
- **Unit:** the notice-queuing logic — a losing edit correctly identifies its original local editor and the correct affected record.
- **Integration:** the Section 6.4 worked-example scenario (two users editing the same invoice offline) reproduced against the emulator, asserting the losing side receives exactly one notice, not zero and not duplicated.
- **Manual:** two devices, deliberately induced conflict (both edit the same client's notes field while both offline, then reconnect both) — confirm the notice appears, is non-blocking, and shows the correct current version.

**Possible risks:** A notice firing for the "two separate payments" non-conflict case (Synchronization Design Section 6.4's explicit warning about this being the case most likely to be mistaken for a conflict) — the regression test from Phase 20's conflict-test suite should already guard this, re-run here as a check, not re-invented.

**Expected deliverables:** Conflicts are visible to the person who lost one, not silently discarded.

**Suggested Git commit points:** One or two commits — this is a small, focused phase.

**Suggested merge point:** Once the two-device induced-conflict manual test passes.

**Suggested checkpoint:** Tag `v2-phase-22-complete`.

---

### Phase 23 — Audit Logging

**Goal:** `activity_logs` populated server-side on every relevant write, viewable via a dedicated screen (`PayMe_V2_Architecture.md` Section 15, 22; `PayMe_V2_Database_Design.md` Section 4.10). Independent of the sync-engine work — can run in parallel with Phases 20–22 if schedule allows, per the Architecture doc's own note, though presented here in sequence for clarity.

**Files affected:**
```
functions/src/onInvoiceWrite.ts, onInvoiceDelete.ts, onClientVisibilityChange.ts (extend), onUserRoleChange.ts   (new triggers)
lib/domain/entities/activity_log_entry.dart                   (new)
lib/presentation/features/activity_log/...                    (new screen — paginated, per Synchronization Design Section 13)
```

**Repositories affected:** None (per Database Design Section 3, `activity_logs` is read via a dedicated, on-demand paginated query, not one of the five frozen repositories).

**Services affected:** None new on the client side — this phase is almost entirely server-side Functions plus one read-only screen.

**Testing required:**
- **Unit:** the `entitySummary` formatting logic (e.g., producing `"Invoice INV-105"` from raw entity data, matching the brief's example format exactly).
- **Integration:** each trigger fires correctly and exactly once per qualifying write, against the emulator; a client write attempt directly to `activity_logs` is rejected (append-only enforcement, tested as a negative case).
- **Manual:** perform a handful of real actions (create invoice, delete invoice, change a user's role) in the dev project; confirm the Activity Log screen shows them, newest-first, correctly attributed.

**Possible risks:** A trigger double-firing (e.g., both `onInvoiceWrite` and an unrelated trigger both logging the same logical action) producing duplicate-looking log entries. Mitigated by the integration test explicitly asserting exactly-one-entry-per-action, not just "at least one."

**Expected deliverables:** A working, correctly-attributed audit trail and its screen.

**Suggested Git commit points:** Functions, entity, screen — three commits; can be developed on its own branch in parallel with Phase 20–22's branches per the Architecture doc's independence note.

**Suggested merge point:** Once the exactly-once-per-action integration test passes.

**Suggested checkpoint:** Tag `v2-phase-23-complete`.

---

### Phase 24 — Notifications

**Goal:** The `notifications` collection and its triggers exist; FCM supplements delivery on Android only (`PayMe_V2_Architecture.md` Section 16, 22; `PayMe_V2_Database_Design.md` Section 4.11). Also independent of Phases 20–22, safe to reorder earlier if schedule prefers.

**Files affected:**
```
functions/src/onPaymentCreate.ts, onInvoiceCreate.ts, onClientCreate.ts, checkOverdueInvoices.ts (scheduled), onPasswordChange.ts   (new triggers)
lib/domain/entities/notification.dart                          (new)
lib/presentation/features/notifications/...                    (new — feed screen, badge)
android: FCM token registration wiring                          (Android-only, per Architecture Section 5)
```

**Repositories affected:** None (read via the same live-listener/poll mechanism `SyncEngine` already provides for every monitored collection, per Synchronization Design Section 7.3 — no new repository needed, `notifications` is just one more entry in the existing monitored-collections list from Phase 20).

**Services affected:** `SyncEngine` (extended to include `notifications` among its monitored collections — a configuration addition, not new sync logic, since Section 9.1 of the Synchronization Design already names it as in-scope).

**Testing required:**
- **Unit:** each trigger's recipient-selection logic (e.g., `onPaymentCreate` notifies exactly the users with visibility into the related client, not all users).
- **Integration:** against the emulator — a payment creation produces exactly the expected notification documents for exactly the expected recipients.
- **Manual:** on a real Android dev-project device, confirm a background FCM push actually wakes/prompts the app, and — critically — confirm the notification feed is complete and correct even with FCM permission denied at the OS level (proving FCM is genuinely a supplement, not load-bearing, per Architecture Section 16).
- **Regression:** the `SyncEngine`'s existing monitored-collection tests (Phase 20) re-run with `notifications` added, confirming no interference with the other collections' sync behavior.

**Possible risks:** Accidentally making some part of the notification *feed itself* (as opposed to the push wake-up) depend on FCM delivery succeeding — explicitly guarded against by the "deny FCM permission and confirm the feed still works" manual test above.

**Expected deliverables:** A working, correctly-scoped notification feed on every platform, with best-effort push on Android.

**Suggested Git commit points:** Triggers; entity/feed screen; FCM wiring — three commits.

**Suggested merge point:** Once the FCM-denied manual test passes (this is the gate that proves the "system of record vs. best-effort supplement" design distinction actually holds).

**Suggested checkpoint:** Tag `v2-phase-24-complete`.

---

### Phase 25 — Firebase Storage (Attachments, Logos)

**Goal:** Attachment and logo upload/download/caching works per `PayMe_V2_Synchronization_Design.md` Section 10 in full, on both platforms.

**Files affected:**
```
lib/services/storage_service.dart                              (new — upload/download/cache, wraps platform-appropriate transport)
lib/data/repositories_impl/hybrid_payment_repository_impl.dart  (extend — attachment create/delete now involves storage_service)
functions/src/onPaymentDelete.ts (extend)                       (Storage cleanup, per Database Design Section 4.9 / Architecture Section 11)
```

**Repositories affected:** `PaymentRepository`'s `Hybrid` implementation (attachments are a sub-concern of payments, per the existing V1 entity relationship, `PayMe_Architecture.md` Section 8).

**Services affected:** `StorageService` (new).

**Testing required:**
- **Unit:** the ordering rule from Synchronization Design Section 10.1 (metadata document push held until file upload succeeds) — tested as an explicit sequencing assertion, not just an eventual-consistency hope.
- **Integration:** against the Storage + Firestore emulator — upload, download, and the delete-cascade (Firestore doc + Storage object together) all verified; an offline-then-reconnect attachment deletion (Synchronization Design Section 10.5's specific offline case) tested explicitly.
- **Manual:** attach a real photo/PDF to a payment on one device, confirm it downloads and caches correctly on a second device on first view, and again instantly (from cache) on second view.
- **Regression:** V1's local-mode attachment tests (V1 Phase 6) re-run unaffected.

**Possible risks:** A `payment_attachments` document referencing a `storagePath` whose upload silently failed (an orphaned metadata pointer). Mitigated directly by the ordering-rule unit test above being a merge gate, not optional.

**Expected deliverables:** Full attachment lifecycle working across devices, including the logo (business settings) case.

**Suggested Git commit points:** `StorageService`; repository integration; cleanup Function — three commits.

**Suggested merge point:** Once the ordering-rule test and the offline-deletion test both pass.

**Suggested checkpoint:** Tag `v2-phase-25-complete`.

---

### Phase 26 — CloudOnboardingService (V1 → V2 Migration)

**Goal:** Existing V1 users can safely, one-time, upload their local database into a freshly-configured cloud-mode business, per `PayMe_V2_Architecture.md` Section 18, 22 and `PayMe_V2_Synchronization_Design.md` Section 15. Built and tested **last** among the core features — it operates on real, irreplaceable user data, and depends on everything built in Phases 16–25 already being solid.

**Files affected:**
```
lib/services/cloud_onboarding_service.dart                     (new — analogous in shape to V1's ExportImportService)
lib/presentation/features/onboarding/screens/enable_cloud_sync_screen.dart   (new)
```

**Repositories affected:** All five, read-only, for the bulk-upload traversal (this service reads through existing local-mode repository methods, it does not bypass them).

**Services affected:** `CloudOnboardingService` (new); reuses `ExportImportService`'s UUID-based reconciliation logic as-is (Architecture Section 18).

**Testing required:**
- **Unit:** UUID-based idempotent re-run logic — an onboarding upload interrupted and restarted correctly skips already-uploaded rows (recognized by `remote_id` already stamped, per Architecture Section 18 Point 7) rather than duplicating them.
- **Integration:** a realistic seeded V1 SQLite database (several years, dozens of clients/invoices/payments/attachments) run through the full onboarding flow against the emulator, verifying end state matches exactly, including the default `visibleTo = { <admin's new uid>: true }` for every client (Architecture Section 18 Point 5).
- **Manual:** on a real device, using an actual snapshot of representative V1 data (anonymized test data, not a live customer's real database), perform the full flow: local password login → "Enable Cloud Sync" → Firebase Auth password creation → upload → verification → confirm local mode has transitioned to "local mirror" status per Architecture Section 18 Point 6.
- **Regression:** a device that does **not** opt into cloud mode continues behaving exactly as V1 always did (Architecture Section 18 Point 1) — this is arguably the single most important regression test in the entire V2 project, since it protects every existing V1 user who never touches this feature.

**Possible risks:** Named explicitly and severely in `PayMe_V2_Architecture.md` Section 21 as "a real-data, no-do-over event for the first upload." Mitigated by: (a) the idempotent-re-run test above being non-negotiable, (b) rehearsing the manual test against several different realistic dataset shapes (a business with very little data, a business with years of history, a business with many attachments) before this phase is considered complete, and (c) not shipping this phase to any real user until every other phase's regression suite is also green — this phase is the last gate before a real V1 user's actual data is at stake.

**Expected deliverables:** A rehearsed, tested, idempotent one-time migration path — the feature that turns V2 from "a new mode for new businesses" into "an upgrade path for the existing product."

**Suggested Git commit points:** `CloudOnboardingService` core logic; the onboarding UI flow; test fixtures/seeded datasets — kept as separate, carefully reviewed commits given the stakes.

**Suggested merge point:** Only after every test category above passes against at least three differently-shaped seeded datasets, and the "never opts in, unaffected" regression test is green.

**Suggested checkpoint:** Tag `v2-phase-26-complete`. Treat this tag as a natural point to pause and do a broader personal review pass before continuing, given the phase's risk profile.

---

### Phase 27 — Security Rules + Functions-Facade Permission-Parity Test Suite

**Goal:** Real, hardened Security Rules replace the deny-all placeholder from Phase 16; the parity test matrix named as a risk mitigation throughout the architecture documents (`PayMe_V2_Architecture.md` Sections 7, 21) is built out fully and made a release gate, per Architecture Section 22's own explicit statement: "do not consider cloud mode release-ready without this in place."

**Files affected:**
```
firestore.rules                                                (full implementation, per Database Design Section 8's dependency table)
storage.rules                                                   (full implementation, per Database Design Section 6's security note)
test/rules/                                                      (new — Rules-emulator test suite)
test/functions_parity/                                           (new — Functions-facade equivalent test suite, same scenarios)
```

**Repositories affected:** None directly — this phase hardens the enforcement layer every prior phase's repositories already write against.

**Services affected:** None new — this phase validates existing services' write paths against real Rules for the first time (everything from Phase 18 onward was built against permissive/dev-only Rules).

**Testing required:**
- **The parity matrix itself, in full:** every permission key × every visibility scenario (visible/not-visible, own record/other's record, active/deactivated user, `super_admin` bypass) — exercised as automated tests against **both** the Rules emulator and the Functions facade, per `PayMe_V2_Architecture.md` Section 21's explicit mitigation design: "not shared code... but a shared specification with parity enforced by tests, not by memory."
- **Regression:** the **entire** V2 feature set built in Phases 17–26, re-run against real (no longer permissive) Rules — this is expected to surface bugs introduced by the permissive-Rules development shortcut, and finding them here (rather than in production) is the explicit point of this phase existing as its own step rather than being folded into each earlier phase.
- **Manual:** a deliberately crafted "modified client" scenario — attempt a write that the UI wouldn't offer (bypassing the UI-level convenience check, Architecture Section 7 Point 1) and confirm the Rules layer independently rejects it, proving Point 1 was never the real gate.

**Possible risks:** This phase, by its nature, is where accumulated permissive-development-mode assumptions get tested against reality for the first time — expect to find and fix real bugs here, and schedule for that rather than treating this as a formality. This is also exactly the phase where Rules/Functions-facade drift (Architecture Section 21's named risk) would first become visible, if it has crept in across Phases 18–26.

**Expected deliverables:** A fully hardened, tested enforcement layer; the app is, for the first time in this roadmap, safe to expose to users who are not the developer.

**Suggested Git commit points:** Rules; Storage Rules; the parity test suite itself — kept visible in history as their own commits since they are, alongside Phase 26, the highest-scrutiny work in the project.

**Suggested merge point:** Only when the full parity matrix passes on both sides and the entire Phase 17–26 regression suite passes against real Rules.

**Suggested checkpoint:** Tag `v2-phase-27-complete`. This tag is the practical entry point into Milestone "V2 Beta" (Section 8).

---

### Phase 28 — Hardening, Field-Load Testing, Packaging & Release

**Goal:** Close every gap opened for velocity in Phases 16–27, exactly mirroring V1 Phase 14/15's own closing discipline (`PayMe_V2_Architecture.md` Section 22).

**Files affected:** Broad, low-risk touch across the codebase — polish, error-message review, loading-state review against `UI_UX_Guidelines.md`, performance tuning of the constants named in `PayMe_V2_Synchronization_Design.md` Section 17 (debounce, backoff, poll interval — "fix empirically, not by guessing," per that document's Section 18 recommendation #3).

**Repositories affected:** All, in the sense of final review, none in the sense of new functionality.

**Services affected:** All, same sense.

**Testing required:**
- **Full stress tests:** large dirty-row counts, large initial cold pulls, extended offline-then-reconnect with a substantial backlog (`PayMe_V2_Synchronization_Design.md` Section 14's "Stress tests" row) — run against a seeded dataset sized well beyond a typical office, specifically to validate batching/chunking under load, not to represent expected real-world usage.
- **Realistic multi-office dataset:** at minimum, two or three simulated "offices" (separate Firebase project pairs, per the per-office-project model) each independently exercised through the full feature set, to catch anything that only manifests with more than one project's worth of real usage.
- **Regression:** the complete test suite from every prior phase, run once more, top to bottom, as a final gate.
- **Manual:** a full "new business, cloud mode from day one" walkthrough and a full "existing V1 business, migrates" walkthrough (Phase 26's flow, rehearsed again here as a release-readiness check, not just a development-time check).

**Possible risks:** This phase is where schedule pressure most tempts skipping steps — explicitly resist merging to `main`/tagging a release milestone until the full regression pass (not a partial one) is green, per Section 1's philosophy that no phase — including this closing one — gets an exception to "must be testable" and "must compile."

**Expected deliverables:** A packaged, releasable build for both Android and Windows, cloud mode included, ready for the RC process (Section 8).

**Suggested Git commit points:** Incremental, as individual hardening items are addressed — no single large "hardening commit."

**Suggested merge point:** `v2-firebase` → `main`, the first such merge since Phase 16 began (per the Git Strategy in Section 3 — intermediate phases stayed off `main` deliberately).

**Suggested checkpoint:** Tag `v2.0.0-rc1` (or the project's preferred RC naming) — this phase's completion is the transition point from "development roadmap" to "release-candidate process" (Section 8).

---

## 5. Suggested Phase Order

| # | Phase | Depends on | Can run in parallel with |
|---|---|---|---|
| 16 | Firebase project scaffolding | 15 (V1 complete) | — |
| 17 | AppMode + Firebase Authentication | 16 | — |
| 18 | Roles / permissions catalog / users + custom claims | 17 | — |
| 19 | Client visibility model + cascade trigger | 18 | — |
| 20 | Sync Engine core (Android) | 19 | — |
| 21 | Cloud Functions facade + Windows fork | 20 | — |
| 22 | Conflict-resolution surfacing | 20–21 | — |
| 23 | Audit logging | 18 | 20–22 |
| 24 | Notifications | 19 | 20–22 (also independent of 23) |
| 25 | Firebase Storage | 21 | — |
| 26 | `CloudOnboardingService` (migration) | 21, 25 | — |
| 27 | Security Rules + parity test suite | 18–21 | — |
| 28 | Hardening, packaging, release | 22–27 | — |

This table restates, without altering, the dependency graph `PayMe_V2_Architecture.md` Section 22 already establishes — included here as a single at-a-glance reference alongside the fuller per-phase detail in Section 4.

---

## 6. Testing Strategy

The testing approach is the same five categories throughout every phase, in the proportions each phase's own risk profile calls for (a low-risk phase like 23 leans on unit/integration tests; a high-risk phase like 20 or 26 leans heavily on manual and stress testing in addition):

| Category | What it covers, project-wide | Primary tool/environment |
|---|---|---|
| **Unit tests** | Pure logic in isolation — permission resolution, conflict decisions, dirty-flag/debounce behavior, idempotency guarantees. | Standard Dart/Flutter test runner; no network or emulator dependency. |
| **Integration tests** | Multi-component behavior against a real (emulated) backend — Rules enforcement, Function triggers, sync push/pull cycles, migration end-to-end. | Firebase Local Emulator Suite (Firestore, Auth, Functions, Storage together) — this is the single most-used tool across Phases 18–27 and should be considered core project infrastructure from Phase 16 onward, not an optional add-on. |
| **Manual tests** | Real-device, real-account behavior a script can't easily assert on — realtime latency *feel*, offline UX, cross-platform (Android↔Windows) observation, the migration walkthrough. | Real dev-project Firebase project, real or emulated devices for both platforms. |
| **Emulator tests** | A specific subset of integration tests: anything validating Security Rules or Functions-facade behavior specifically, run against the Rules/Functions emulator rather than a live project, to keep the parity-matrix suite (Phase 27) fast and free to run constantly during development. | Firebase Local Emulator Suite, Rules-testing library. |
| **Regression tests** | Confirming a phase's new work did not disturb (a) local mode, which must remain byte-for-byte behaviorally identical to V1 throughout every V2 phase, and (b) prior V2 phases' own already-passing tests. | The full accumulated suite from all prior phases, re-run at every phase boundary — not just at the end. |

**Cross-cutting rule:** local-mode regression is checked at *every* phase from 17 onward, not just at the end — this is the single testing habit most responsible for making sure V2 development never puts the already-shipped V1 product at risk, and is treated as equally mandatory as any phase's own new-feature tests.

---

## 7. Risk Management

| Risk category | Concretely, what goes wrong | Early detection |
|---|---|---|
| **Synchronization bugs** | Dirty rows never clearing (stuck perpetually re-pushing); pull events applied out of order, breaking a foreign-key assumption; a debounce/backoff constant tuned so aggressively it hammers cost or so loosely it feels broken. | Phase 20's unit + integration suite, re-run as a *standing* regression check in every subsequent phase (per Section 6) — a sync bug introduced in Phase 24, say, should be caught by Phase 20's own tests still being exercised, not discovered fresh in Phase 28. |
| **Permission bugs** | A user seeing or editing something their role/overrides shouldn't allow; Rules and the Functions facade drifting apart (`PayMe_V2_Architecture.md` Section 21's named risk). | The parity test matrix (Phase 27), but *started* informally as early as Phase 21 (that phase's own testing block already includes a first version of this check) rather than deferred entirely to the end. |
| **Offline bugs** | A write silently lost because it wasn't actually marked dirty; a read blocking or erroring because it mistakenly tried to reach the network. | Phase 20's explicit offline test category, re-run at every later phase that touches a `Hybrid*RepositoryImpl` (25, 26 especially, since both add new write paths). |
| **Migration bugs** | Data loss or duplication during the one-time V1→V2 upload; a V1 user who never opts in nonetheless experiencing a behavior change. | Phase 26's idempotent-re-run test and its "never opts in, unaffected" regression test — both non-negotiable merge gates, not just nice-to-haves, per Phase 26's own risk note. |
| **Realtime bugs** | A listener not re-attaching correctly on foreground (stale data shown); Windows polling silently stopping. | Phase 20's two-device manual realtime test, and its Windows equivalent in Phase 21 — both should be repeated periodically through later phases as a quick manual sanity check, not performed once and assumed to remain true. |
| **Windows facade bugs** | The facade's independently-implemented permission/visibility checks diverging from Android's Rules-based checks (the same class of risk as "permission bugs" above, but specifically the Windows-side implementation of it). | Phase 21's parity-check testing, formalized fully in Phase 27; any change to a permission or visibility rule anywhere in Phases 18–27 should trigger re-running the parity suite, not just the phase that introduced the change. |

**General early-detection principle across all categories:** every risk above is cheapest to catch in the phase that introduces the underlying mechanism (20 for sync, 18–19 for permission/visibility, 26 for migration, 21 for the facade) and gets progressively more expensive to catch the further downstream it travels undetected — which is the practical justification for this roadmap's insistence on full regression passes at every phase boundary (Section 6), rather than only at the end.

---

## 8. Milestones

| Milestone | Corresponds to | Meaning |
|---|---|---|
| **V2 Phase 1 (internal)** | Completion of Phase 20 | Cloud mode fundamentally works, Android-only, in an emulator/dev-project setting — the point at which the core architectural bet ("one app, a reconciliation layer") is proven, not just designed. |
| **V2 Phase 2 (internal)** | Completion of Phase 25 | Full cross-platform feature set (Android + Windows, sync, storage, permissions, visibility, audit, notifications) exists, still on permissive dev-mode Rules. |
| **V2 Beta** | Completion of Phase 27 | Hardened, tested enforcement layer in place; suitable for the developer's own real (or closely-simulated) business usage, not yet for other real customers' irreplaceable data. |
| **V2 RC1** | Completion of Phase 28 | First release-candidate build; feature-complete, stress-tested, both platforms packaged. |
| **V2 RC2** | Any fixes found during RC1 real-world/extended testing, cherry-picked per the Git Strategy (Section 3) | Addresses whatever RC1 surfaced; not expected to contain new features. |
| **V2 Stable** | `v2-firebase` merged to `main`, tagged, released | Cloud mode ships to real V1 users as an opt-in upgrade, per Phase 26's migration path. |

---

## 9. Definition of Done — Consolidated

Each phase's own section (Section 4) states its specific Definition of Done implicitly through its "Expected deliverables" and "Testing required." Restated here as a single project-wide standard every phase must meet before its checkpoint tag is applied, so it's visible in one place rather than only distributed across seventeen phase sections:

A phase is done when, and only when:
1. It compiles and runs, on every platform it touches, from a clean checkout.
2. Its own unit and integration tests pass.
3. Its manual test scenario (where one is specified) has actually been performed, not just theoretically possible.
4. The full local-mode regression suite still passes, unchanged.
5. The full regression suite of every *prior* V2 phase still passes.
6. Firebase never appears above the repository boundary anywhere the phase touched (Section 1's core rule, checked at every phase, not assumed).
7. It is merged into `v2-firebase` and tagged, per Section 3's Git Strategy.

No phase is considered done on the basis of "the happy path works" alone — every phase's testing block in Section 4 specifies what "done" concretely requires beyond that.

---

## 10. Final Timeline — Relative Complexity

| Phase | Complexity | Why |
|---|---|---|
| 16 | **Low** | Pure configuration, no app logic. |
| 17 | **Medium** | New auth implementation behind an existing interface — well-bounded, but real integration surface (Firebase Auth + `ReauthGuard`). |
| 18 | **Medium** | New collections and a Cloud Function trigger, but a self-contained, well-specified formula (`effectivePermission`). |
| 19 | **Medium** | The cascade trigger's chunking and creation-time-copy edge cases add real subtlety beyond the basic CRUD surface. |
| 20 | **Very High** | Named as the highest-risk phase in the frozen architecture itself; introduces the entire hybrid-repository pattern, the engine's state machine, both pipelines, and conflict resolution, all at once, with no prior V2 phase's pattern to lean on. |
| 21 | **High** | Reuses Phase 20's contract, but the Windows facade's independent permission/visibility re-implementation is genuinely new surface area with real drift risk. |
| 22 | **Low** | Small, focused UI/state addition on top of already-working engine logic. |
| 23 | **Low–Medium** | Mostly mechanical (triggers + a read-only screen); independence from the sync engine keeps risk contained. |
| 24 | **Medium** | More moving parts than audit logging (FCM, scheduled Functions, multiple trigger types), but each part is individually well-bounded. |
| 25 | **Medium–High** | Cross-cutting (touches an existing repository, adds a new service, has real ordering/consistency subtlety around the metadata/file-upload relationship). |
| 26 | **Very High** | Operates on irreplaceable real user data, with a stated "no do-over" character for the first upload; correctness bar is categorically higher than any other phase's. |
| 27 | **High** | Not conceptually novel (the checks were already designed), but exhaustive by requirement — the parity matrix's completeness, not its individual difficulty, is what makes this phase demanding. |
| 28 | **Medium** | Broad but shallow — mostly tuning, polish, and exhaustive re-testing rather than new design or new risk surface. |

**Biggest risks, ranked:** Phase 20 (Sync Engine core) and Phase 26 (migration) are the two phases this roadmap treats with the most schedule slack and the most conservative merge gates — Phase 20 because every later phase inherits its correctness, and Phase 26 because its failure mode is irreversible data loss for a real person's business records, not merely a bug to patch in a follow-up release. Phase 27 is the third-ranked risk, not because any individual check is hard, but because it is the phase most likely to surface accumulated problems from every phase before it, all at once, right before release.
