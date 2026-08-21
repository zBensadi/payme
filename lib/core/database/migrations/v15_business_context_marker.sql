-- ============================================================
-- Migration: Add business context markers to app_meta
-- ============================================================
ALTER TABLE app_meta ADD COLUMN current_business_id TEXT;
ALTER TABLE app_meta ADD COLUMN current_uid TEXT;
