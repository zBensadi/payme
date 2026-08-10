-- ============================================================
-- Add is_deleted column to payments for synchronization
-- ============================================================
ALTER TABLE payments ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0;
