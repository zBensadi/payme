-- ============================================================
-- invoice_sequences
-- ============================================================
CREATE TABLE invoice_sequences (
    accounting_year_id TEXT PRIMARY KEY REFERENCES accounting_years(id) ON DELETE CASCADE,
    last_invoice_number INTEGER NOT NULL DEFAULT 0
);
