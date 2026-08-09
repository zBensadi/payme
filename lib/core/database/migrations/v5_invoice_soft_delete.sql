-- Adds the is_deleted column to the invoices table to support soft deletion for synchronization.
ALTER TABLE invoices ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0;
