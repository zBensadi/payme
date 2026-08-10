# Alpha 08: Client Synchronization

## Description
Integrated the Client domain into the synchronization engine. Clients are synchronized with medium priority as they have no strict foreign key dependencies.

## Key Changes
- Added `is_dirty`, `is_deleted`, and `updated_at` to the Client schema.
- Updated `ClientLocalDataSource` and `ClientRepositoryImpl` to support soft deletes.
- Implemented `ClientRemoteDataSource` and `ClientConflictResolver`.
- Verified multi-device client creation, updates, and deletions.
