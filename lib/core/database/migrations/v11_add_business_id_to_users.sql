-- ============================================================
-- Migration: Add business_id to users
-- ============================================================
ALTER TABLE users ADD COLUMN business_id TEXT;
