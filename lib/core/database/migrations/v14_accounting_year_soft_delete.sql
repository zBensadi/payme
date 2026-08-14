ALTER TABLE accounting_years ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0;
CREATE INDEX idx_accounting_years_is_deleted ON accounting_years(is_deleted);
