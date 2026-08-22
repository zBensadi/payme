const fs = require('fs');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'demo-payme-test';
const RULES_PATH = '../firestore.rules';

let testEnv;

async function getTestEnv() {
  if (!testEnv) {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: fs.readFileSync(RULES_PATH, 'utf8'),
        host: '127.0.0.1',
        port: 8080,
      },
      storage: {
        rules: fs.readFileSync('../storage.rules', 'utf8'),
        host: '127.0.0.1',
        port: 59199,
      },
    });
  }
  return testEnv;
}

async function cleanupEnv() {
  if (testEnv) {
    await testEnv.cleanup();
    testEnv = null;
  }
}

function getAnonymousContext() {
  return getTestEnv().then(env => env.unauthenticatedContext().firestore());
}

function getAuthenticatedContext(uid, claims = {}) {
  return getTestEnv().then(env => env.authenticatedContext(uid, claims).firestore());
}

function getAdminContext() {
  // Bypasses all rules (for setup only, not for testing assertions)
  return getTestEnv().then(env => env.withSecurityRulesDisabled(context => context.firestore()));
}

async function asOwner(businessId, uid) {
  return getAuthenticatedContext(uid, {
    businessId: businessId,
    isOwner: true,
    isSuperAdmin: false,
  });
}

async function asAdmin(businessId, uid) {
  return getAuthenticatedContext(uid, {
    businessId: businessId,
    isOwner: false,
    isSuperAdmin: false,
  });
}

async function asNormalUser(businessId, uid) {
  return getAuthenticatedContext(uid, {
    businessId: businessId,
    isOwner: false,
    isSuperAdmin: false,
  });
}

async function asDeactivated(businessId, uid) {
  return getAuthenticatedContext(uid, {
    businessId: businessId,
    isOwner: false,
    isSuperAdmin: false,
  });
}

async function loadSyntheticFixtures() {
  const env = await getTestEnv();
  
  // Use admin privileges to write fixtures
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const batch = db.batch();

    // --- BUSINESS A ---
    batch.set(db.doc('businesses/bizA'), { name: 'Business A' });
    
    // Roles
    batch.set(db.doc('businesses/bizA/roles/role-owner'), { name: 'Owner', isSystemRole: true, priority: 1000, permissions: [] });
    batch.set(db.doc('businesses/bizA/roles/role-admin'), { name: 'Admin', isSystemRole: true, priority: 800, permissions: ['users.edit', 'roles.manage', 'users.create'] });
    batch.set(db.doc('businesses/bizA/roles/role-user'), { name: 'User', isSystemRole: true, priority: 500, permissions: ['clients.view'] });

    // Users
    batch.set(db.doc('businesses/bizA/users/userA_owner'), { uid: 'userA_owner', businessId: 'bizA', roleId: 'role-owner', isOwner: true, isSuperAdmin: false });
    batch.set(db.doc('businesses/bizA/users/userA_admin'), { uid: 'userA_admin', businessId: 'bizA', roleId: 'role-admin', isOwner: false, isSuperAdmin: false });
    batch.set(db.doc('businesses/bizA/users/userA_normal'), { uid: 'userA_normal', businessId: 'bizA', roleId: 'role-user', isOwner: false, isSuperAdmin: false });
    batch.set(db.doc('businesses/bizA/users/userA_extra1'), { uid: 'userA_extra1', businessId: 'bizA', roleId: 'role-user', isOwner: false, isSuperAdmin: false });
    batch.set(db.doc('businesses/bizA/users/userA_extra2'), { uid: 'userA_extra2', businessId: 'bizA', roleId: 'role-user', isOwner: false, isSuperAdmin: false });
    batch.set(db.doc('businesses/bizA/users/userA_extra3'), { uid: 'userA_extra3', businessId: 'bizA', roleId: 'role-user', isOwner: false, isSuperAdmin: false });
    
    // Deactivated user
    batch.set(db.doc('businesses/bizA/users/userA_deactivated'), { uid: 'userA_deactivated', businessId: 'bizA', roleId: 'role-user', isOwner: false, isSuperAdmin: false, isActive: false });
    batch.set(db.doc('businesses/bizA/revoked_tokens/userA_deactivated'), { revokedAt: '2026-01-01T00:00:00Z' });

    // Global pointers
    batch.set(db.doc('users/userA_owner'), { uid: 'userA_owner', businessId: 'bizA' });
    batch.set(db.doc('users/userA_admin'), { uid: 'userA_admin', businessId: 'bizA' });
    batch.set(db.doc('users/userA_normal'), { uid: 'userA_normal', businessId: 'bizA' });
    batch.set(db.doc('users/userA_extra1'), { uid: 'userA_extra1', businessId: 'bizA' });
    batch.set(db.doc('users/userA_extra2'), { uid: 'userA_extra2', businessId: 'bizA' });
    batch.set(db.doc('users/userA_extra3'), { uid: 'userA_extra3', businessId: 'bizA' });

    // Client/Invoice/Payment/Accounting
    for (let i = 1; i <= 6; i++) {
      batch.set(db.doc(`businesses/bizA/clients/client${i}`), { name: `Client ${i}` });
      batch.set(db.doc(`businesses/bizA/accounting_years/year${i}`), { name: `202${i}`, isActive: i === 1 });
      batch.set(db.doc(`businesses/bizA/invoices/inv${i}`), { clientId: `client${i}`, amount: 100 * i });
      batch.set(db.doc(`businesses/bizA/payments/pay${i}`), { invoiceId: `inv${i}`, amount: 100 * i });
    }

    // --- BUSINESS B ---
    batch.set(db.doc('businesses/bizB'), { name: 'Business B' });
    batch.set(db.doc('businesses/bizB/roles/role-owner'), { name: 'Owner', priority: 1000 });
    batch.set(db.doc('businesses/bizB/users/userB_owner'), { uid: 'userB_owner', businessId: 'bizB', roleId: 'role-owner', isOwner: true, isSuperAdmin: false });
    batch.set(db.doc('users/userB_owner'), { uid: 'userB_owner', businessId: 'bizB' });
    
    batch.set(db.doc('businesses/bizB/clients/clientB'), { name: 'Client B' });
    batch.set(db.doc('businesses/bizB/invoices/invB'), { clientId: 'clientB', amount: 50 });
    batch.set(db.doc('businesses/bizB/payments/payB'), { invoiceId: 'invB', amount: 50 });
    batch.set(db.doc('businesses/bizB/accounting_years/yearB'), { name: '2026', isActive: true });

    await batch.commit();
  });
}

module.exports = {
  getTestEnv,
  cleanupEnv,
  getAnonymousContext,
  getAuthenticatedContext,
  asOwner,
  asAdmin,
  asNormalUser,
  asDeactivated,
  loadSyntheticFixtures,
};
