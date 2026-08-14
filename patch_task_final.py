import sys

file_path = "C:/Users/bft/.gemini/antigravity/brain/282ab1f6-443b-4206-aea6-3683a1c992e6/task.md"
content = """# Phase 2B — Custom Role Creation & Deletion Tasks

## 1. UI & Routing
- [x] Add "Create Role" button/FAB to `RolesListScreen`.
- [x] Support `roleId: 'new'` route and handle empty state in `RoleEditorController`.
- [x] Add "Delete Role" button to `RoleEditorScreen` (only if `!isNew` and `role.isDeletable`).
- [x] Implement Delete Confirmation Dialog explaining why it's blocked if users are assigned.
- [x] Use predefined color palette (Blue, Green, Purple, Orange, Red, Gray).
- [x] Controller-level form validation (priority bounds, permissions bounds, duplicate names).

## 2. Business Logic (SecuredRoleRepository)
- [x] Enforce Duplicate Name Validation (case-insensitive, trimmed).
- [x] Enforce Custom Role Invariants on create (`isSystemRole = false`, `isEditable = true`, `isDeletable = true`).
- [x] Enforce Permission Privilege (target permissions ? current user's permissions, unless Owner).
- [x] Enforce Priority Bound (target priority < current user's priority).
- [x] Enforce Deletion Safety (block if ANY user active/inactive/deleted references roleId).
- [x] Implement Soft Deletion (`is_deleted = true`, `is_dirty = true`, trigger sync).
- [x] Protect System Roles from deletion/unauthorized edits.

## 3. Synchronization & Tests
- [x] Ensure offline role creation/deletion sets `is_dirty = true` and SyncService pulls correctly.
- [x] Create automated tests for Role Deletion Synchronization.
- [x] Create automated tests for SecuredRoleRepository invariants.
- [x] Run `flutter analyze` and `flutter test`.

## 4. Documentation & Verification
- [x] Execute manual offline/online testing per the 22-point checklist.
- [x] Update `walkthrough.md` with verification results.
- [x] Keep `task.md` updated.
"""

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
