-- ============================================================
-- app_meta: single-row table tracking schema version
-- ============================================================
CREATE TABLE app_meta (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    schema_version INTEGER NOT NULL
);

-- ============================================================
-- accounting_years
-- ============================================================
CREATE TABLE accounting_years (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,          -- e.g. "2026"
    is_active INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    -- sync-readiness (unused in V1)
    remote_id TEXT,
    synced_at TEXT,
    is_dirty INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- clients (GLOBAL — not scoped to a year)
-- ============================================================
CREATE TABLE clients (
    id TEXT PRIMARY KEY,                -- UUID
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    notes TEXT,
    is_deleted INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    remote_id TEXT,
    synced_at TEXT,
    is_dirty INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_clients_is_deleted ON clients(is_deleted);

-- ============================================================
-- invoices
-- ============================================================
CREATE TABLE invoices (
    id TEXT PRIMARY KEY,
    accounting_year_id TEXT NOT NULL REFERENCES accounting_years(id),
    client_id TEXT NOT NULL REFERENCES clients(id),
    invoice_number INTEGER NOT NULL,
    date TEXT NOT NULL,
    description TEXT,
    amount REAL NOT NULL CHECK (amount >= 0),
    due_date TEXT,
    notes TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    remote_id TEXT,
    synced_at TEXT,
    is_dirty INTEGER NOT NULL DEFAULT 0,
    UNIQUE (accounting_year_id, invoice_number)
);
CREATE INDEX idx_invoices_year ON invoices(accounting_year_id);
CREATE INDEX idx_invoices_client ON invoices(client_id);

-- ============================================================
-- payments
-- ============================================================
CREATE TABLE payments (
    id TEXT PRIMARY KEY,
    invoice_id TEXT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    date TEXT NOT NULL,
    amount REAL NOT NULL CHECK (amount > 0),
    method TEXT NOT NULL CHECK (method IN ('cash','cheque','bank_transfer')),
    reference TEXT,
    notes TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    remote_id TEXT,
    synced_at TEXT,
    is_dirty INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_payments_invoice ON payments(invoice_id);

-- ============================================================
-- payment_attachments
-- ============================================================
CREATE TABLE payment_attachments (
    id TEXT PRIMARY KEY,
    payment_id TEXT NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,            -- relative to app attachments dir
    original_file_name TEXT NOT NULL,
    file_type TEXT NOT NULL CHECK (file_type IN ('pdf','jpg','png')),
    file_size_bytes INTEGER NOT NULL,
    created_at TEXT NOT NULL
);
CREATE INDEX idx_attachments_payment ON payment_attachments(payment_id);

-- ============================================================
-- business_settings (single row)
-- ============================================================
CREATE TABLE business_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    business_name TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    logo_path TEXT,
    currency_code TEXT NOT NULL,
    currency_locked_at TEXT             -- set on first invoice creation
);

-- ============================================================
-- admin_credential (single row, security-sensitive)
-- ============================================================
CREATE TABLE admin_credential (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    password_hash TEXT NOT NULL,
    password_salt TEXT NOT NULL,
    recovery_key_hash TEXT NOT NULL,
    recovery_key_salt TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
