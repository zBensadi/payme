-- ============================================================
-- Add updated_at column to accounting_years for synchronization
-- ============================================================
ALTER TABLE accounting_years ADD COLUMN updated_at TEXT NOT NULL DEFAULT '';
UPDATE accounting_years SET updated_at = created_at;
