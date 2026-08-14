-- ============================================================
-- deleted_client_visibilities
-- ============================================================
-- Tracks physical deletions of client_user_visibility mappings for synchronization.
-- Idempotent deletions insert here using INSERT OR IGNORE.
-- Re-adding a mapping will remove its corresponding tombstone.

CREATE TABLE deleted_client_visibilities (
    client_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    deleted_at TEXT NOT NULL,
    PRIMARY KEY (client_id, user_id)
);
