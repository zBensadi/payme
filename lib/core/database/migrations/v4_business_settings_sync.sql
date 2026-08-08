ALTER TABLE business_settings ADD COLUMN updated_at TEXT;
ALTER TABLE business_settings ADD COLUMN remote_id TEXT;
ALTER TABLE business_settings ADD COLUMN synced_at TEXT;
ALTER TABLE business_settings ADD COLUMN is_dirty INTEGER NOT NULL DEFAULT 0;
