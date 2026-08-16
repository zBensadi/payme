# Alpha 15 — Release Notes

**Tag:** `v2.0.0-alpha.15`  
**Released:** August 2026

---

## Summary

Alpha 15 represents a major architectural milestone for PayMe: the stabilization of the **offline-first authorization architecture**. This release focused entirely on correctness, robustness, and security of the data and permissions layer — not new features.

---

## What's New

### Offline-First Authorization (`SecuredRepository`)
- Introduced the `SecuredRepository` wrapper pattern, which enforces role-based permission checks against the **local SQLite cache** before allowing any read or write operation.
- Authorization decisions no longer depend on network availability — PayMe correctly enforces permissions even when offline.
- Any operation that exceeds the user's role permissions is blocked with a `PermissionFailure` regardless of network state.

### Role Propagation
- Role changes made by administrators now **propagate to affected users in real-time** without requiring re-authentication or app restart.
- The sync engine pushes updated role documents, which are immediately applied to the local permission cache.

### Re-Authentication Guard
- Sensitive destructive operations (e.g., accounting year deletion) now require the user to re-authenticate before proceeding.
- Prevents accidental or unauthorized destructive actions.

### Sync Engine Stability
- Resolved multiple edge cases in the bi-directional sync engine including:
  - Duplicate sync triggers
  - Race conditions during simultaneous push/pull cycles
  - Missing conflict resolution for concurrent edits
- Sync is now fully lifecycle-aware (pauses on background, resumes on foreground).

### Bootstrap Sequence
- First-login bootstrap flow hardened — creates the initial business, owner role, and user pointer atomically via Firestore transactions.

---

## Platforms

- ✅ Windows desktop
- ✅ Android

---

## Known Issues at Alpha 15

- Firestore Security Rules remain broad (`if request.auth != null`). Business-tenant isolation is application-side only.
- Some UI strings were still hardcoded in English (resolved in Alpha 16).
