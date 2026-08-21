const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { asNormalUser, loadSyntheticFixtures, cleanupEnv, getAuthenticatedContext } = require('../helpers');

describe('Tenant Isolation Tests', () => {
  let dbA;

  before(async () => {
    await loadSyntheticFixtures();
    dbA = await asNormalUser('bizA', 'userA_normal'); // User from Business A
  });

  after(async () => {
    await cleanupEnv();
  });

  it('[FUTURE SECURITY] Read Business B client -> DENIED', async () => {
    await assertFails(dbA.doc('businesses/bizB/clients/clientB').get());
  });

  it('[FUTURE SECURITY] Write Business B client -> DENIED', async () => {
    await assertFails(dbA.doc('businesses/bizB/clients/clientB').set({ name: 'Hacked' }, { merge: true }));
  });

  it('[FUTURE SECURITY] Delete Business B client -> DENIED', async () => {
    await assertFails(dbA.doc('businesses/bizB/clients/clientB').delete());
  });

  it('[FUTURE SECURITY] Read Business B invoice -> DENIED', async () => {
    await assertFails(dbA.doc('businesses/bizB/invoices/invB').get());
  });

  it('[FUTURE SECURITY] Write Business B invoice -> DENIED', async () => {
    await assertFails(dbA.doc('businesses/bizB/invoices/invB').set({ amount: 0 }, { merge: true }));
  });

  it('[FUTURE SECURITY] Read Business B payment -> DENIED', async () => {
    await assertFails(dbA.doc('businesses/bizB/payments/payB').get());
  });

  it('[FUTURE SECURITY] Write Business B payment -> DENIED', async () => {
    await assertFails(dbA.doc('businesses/bizB/payments/payB').set({ amount: 0 }, { merge: true }));
  });

  it('[FUTURE SECURITY] Read Business B accounting year -> DENIED', async () => {
    await assertFails(dbA.doc('businesses/bizB/accounting_years/yearB').get());
  });

  it('[PHASE 2] SuperAdmin -> Business A access -> ALLOWED', async () => {
    const dbAdmin = await getAuthenticatedContext('super_admin_user', { isSuperAdmin: true });
    await assertSucceeds(dbAdmin.collection('businesses/bizA/users').get());
  });

  it('[PHASE 2] SuperAdmin -> Business B access -> ALLOWED', async () => {
    const dbAdmin = await getAuthenticatedContext('super_admin_user', { isSuperAdmin: true });
    await assertSucceeds(dbAdmin.collection('businesses/bizB/users').get());
  });

  it('[PHASE 2] Normal Business A user -> Business B collection query -> DENIED', async () => {
    await assertFails(dbA.collection('businesses/bizB/users').get());
    await assertFails(dbA.collection('businesses/bizB/clients').get());
    await assertFails(dbA.collection('businesses/bizB/invoices').get());
  });

  it('[PHASE 2] Normal Business A user -> Business A collection query (pullUsers, etc) -> ALLOWED', async () => {
    // This proves the collection-level query compatibility fix (where read is broad intra-tenant)
    await assertSucceeds(dbA.collection('businesses/bizA/users').get());
    await assertSucceeds(dbA.collection('businesses/bizA/roles').get());
    await assertSucceeds(dbA.collection('businesses/bizA/clients').get());
    await assertSucceeds(dbA.collection('businesses/bizA/invoices').get());
    await assertSucceeds(dbA.collection('businesses/bizA/payments').get());
    await assertSucceeds(dbA.collection('businesses/bizA/accounting_years').get());
  });
});
