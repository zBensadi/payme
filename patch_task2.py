import sys
import re

file_path = "C:/Users/bft/.gemini/antigravity/brain/282ab1f6-443b-4206-aea6-3683a1c992e6/task.md"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# I will completely rewrite the content based on user's exact specifications
new_content = """# Phase 2A — Firestore System Role Migration Blocker Fixes

## 1. Migration Logic Improvements (Completed)
- [x] Implement deterministic legacy Owner detection (`isSystemRole`, `isEditable`).
- [x] Migrate BOTH legacy dynamic Owner and `role-super-admin`.
- [x] Iterate and migrate multiple legacy roles.
- [x] Ensure canonical `role-owner` creation with `SetOptions(merge: true)`.
- [x] Remap all domain users and update routing pointers with `set(..., SetOptions(merge: true))` containing full pointer schema.
- [x] Fail migration explicitly on partial batch failure (do NOT fallback silently).
- [x] Delete legacy roles ONLY after complete migration.
- [x] Maintain chunking (200 users / 400 writes).
- [x] Remove `role-super-admin` shortcut.
- [x] Fail `checkExistingBusiness` explicitly if migration throws.
- [x] v12 SQLite migration
- [x] Owner immutability
- [x] Owner UI locking
- [x] canonical Owner priority = 1000
- [x] Firebase bootstrap uses role-owner

## 2. Automated Tests (Deferred)
**Note: These items are NOT implemented and remain deferred until a Firestore emulator or approved mocking framework is introduced to the project.**
- [ ] Create tests for Firestore migration logic using `FakeFirebaseFirestore` or mocking.
  - [ ] Legacy dynamic Owner -> role-owner.
  - [ ] role-super-admin -> role-owner.
  - [ ] Multiple legacy Owner roles -> role-owner.
  - [ ] Custom role named "Owner" is NOT migrated.
  - [ ] role-owner already exists.
  - [ ] Missing routing pointer handling.
  - [ ] Multiple users across multiple batches (chunking integration tests).
  - [ ] Partial batch failure and retry (partial failure/retry integration tests).
  - [ ] Legacy role not deleted before successful remapping.
  - [ ] Successful migration deletes legacy roles.
  - [ ] Routing pointer receives correct businessId and roleId.
  - [ ] Idempotency.

## 3. Verification
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `walkthrough.md` and `task.md`.
"""

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content)
