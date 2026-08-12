-- ============================================================
-- roles
-- ============================================================
CREATE TABLE roles (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT,
    priority INTEGER NOT NULL DEFAULT 100,
    is_system_role INTEGER NOT NULL DEFAULT 0,
    is_editable INTEGER NOT NULL DEFAULT 1,
    is_deletable INTEGER NOT NULL DEFAULT 1,
    permissions TEXT NOT NULL, -- JSON array of strings
    is_deleted INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    remote_id TEXT,
    synced_at TEXT,
    is_dirty INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- users
-- ============================================================
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT,
    role_id TEXT NOT NULL REFERENCES roles(id),
    is_owner INTEGER NOT NULL DEFAULT 0,
    is_active INTEGER NOT NULL DEFAULT 1,
    is_deleted INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    remote_id TEXT,
    synced_at TEXT,
    is_dirty INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- client_user_visibility
-- ============================================================
CREATE TABLE client_user_visibility (
    client_id TEXT NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    synced_at TEXT,
    PRIMARY KEY (client_id, user_id)
);

-- ============================================================
-- ALTER existing tables
-- ============================================================
ALTER TABLE clients ADD COLUMN visibility_type TEXT NOT NULL DEFAULT 'everyone';
ALTER TABLE clients ADD COLUMN created_by TEXT;
ALTER TABLE clients ADD COLUMN updated_by TEXT;

ALTER TABLE invoices ADD COLUMN created_by TEXT;
ALTER TABLE invoices ADD COLUMN updated_by TEXT;

ALTER TABLE payments ADD COLUMN created_by TEXT;
ALTER TABLE payments ADD COLUMN updated_by TEXT;

ALTER TABLE accounting_years ADD COLUMN created_by TEXT;
ALTER TABLE accounting_years ADD COLUMN updated_by TEXT;

ALTER TABLE business_settings ADD COLUMN created_by TEXT;
ALTER TABLE business_settings ADD COLUMN updated_by TEXT;

-- ============================================================
-- Data Migration: Super Admin & System Owner
-- ============================================================

-- 1. Create Super Admin role
INSERT OR IGNORE INTO roles (
    id, name, description, color, priority, is_system_role, is_editable, is_deletable, permissions, created_at, updated_at, is_dirty
) VALUES (
    'role-super-admin', 
    'Super Admin', 
    'System generated owner role', 
    'purple', 
    900, 
    1, 
    0, 
    0, 
    '[]', 
    datetime('now'), 
    datetime('now'), 
    1
);

-- 2. Migrate existing admin to System Owner
INSERT OR IGNORE INTO users (
    id, email, display_name, role_id, is_owner, is_active, is_deleted, created_at, updated_at, is_dirty
) 
SELECT 
    '{{FIREBASE_UID}}', -- Replaced dynamically by MigrationRunner
    COALESCE(email, 'admin@local.business'), 
    COALESCE(business_name, 'System Owner'), 
    'role-super-admin', 
    1, 
    1, 
    0, 
    datetime('now'), 
    datetime('now'), 
    1
FROM business_settings 
WHERE id = 1;
