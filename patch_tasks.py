import sys

file_path = "C:/Users/bft/.gemini/antigravity/brain/282ab1f6-443b-4206-aea6-3683a1c992e6/task.md"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace tasks in Data Layer section
old_data_layer = """## 1. Data Layer: Deletion Sync & Tombstones
- [ ] Create `v13_client_visibility_tombstones.sql` with `deleted_client_visibilities` table.
- [ ] Update `ClientVisibilityLocalDataSource.removeVisibility` to insert tombstones.
- [ ] Add `getPendingDeletions()` and `clearDeletions()` to `ClientVisibilityLocalDataSource`.
- [ ] Update `ClientVisibilityRepositoryImpl.pushChanges` to fetch tombstones, call `pushDeletions`, and clear them locally."""

new_data_layer = """## 1. Data Layer: Deletion Sync & Tombstones
- [ ] Create `v13_client_visibility_tombstones.sql` with `deleted_client_visibilities` table.
- [ ] Update `ClientVisibilityLocalDataSource.removeVisibility` to insert tombstones with `INSERT OR IGNORE` (Idempotency).
- [ ] Update `ClientVisibilityLocalDataSource.addVisibility` to delete existing tombstone for mapping (Reconciliation).
- [ ] Add `getPendingDeletions()` and `clearDeletions()` to `ClientVisibilityLocalDataSource`.
- [ ] Update `ClientVisibilityRepositoryImpl.pushChanges` to fetch tombstones, call `pushDeletions`, and clear them locally."""

content = content.replace(old_data_layer, new_data_layer)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
