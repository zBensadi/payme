-- ============================================================
-- V12: Normalize System Roles
-- ============================================================

-- 1. Insert or Replace the canonical Owner role
INSERT OR IGNORE INTO roles (
    id, name, description, color, priority, is_system_role, is_editable, is_deletable, permissions, created_at, updated_at, is_dirty
) VALUES (
    'role-owner', 
    'Owner', 
    'Business owner with full permissions', 
    'blue', 
    1000, 
    1, 
    0, 
    0, 
    '[]', 
    datetime('now'), 
    datetime('now'), 
    0
);

-- 2. Enforce priority and immutability for the canonical Owner role
UPDATE roles 
SET priority = 1000, is_editable = 0, is_system_role = 1 
WHERE id = 'role-owner';

-- 3. Remap all users pointing to legacy system roles or who are flagged as owner
UPDATE users 
SET role_id = 'role-owner', is_dirty = 1 
WHERE is_owner = 1 
   OR role_id = 'role-super-admin' 
   OR role_id IN (SELECT id FROM roles WHERE name = 'Owner' AND id != 'role-owner');

-- 4. Delete legacy roles now that users are safely remapped
DELETE FROM roles 
WHERE id = 'role-super-admin' 
   OR (name = 'Owner' AND id != 'role-owner');
