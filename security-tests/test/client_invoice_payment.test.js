const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { asNormalUser, asOwner, loadSyntheticFixtures, cleanupEnv } = require('../helpers');

describe('Client, Invoice & Payment Tests', () => {
  before(async () => {
    await loadSyntheticFixtures();
  });

  after(async () => {
    await cleanupEnv();
  });

  // Note: userA_normal has 'clients.view' but NO invoice or payment permissions

  it('[FUTURE SECURITY] Unauthorized client write -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/clients/clientA').update({ name: 'Hacked Client' }));
  });

  it('[FUTURE SECURITY] Unauthorized client delete -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/clients/clientA').delete());
  });

  it('[PHASE 2] Normal user can read invoice (broad read) -> ALLOWED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertSucceeds(db.doc('businesses/bizA/invoices/invA').get());
  });

  it('[FUTURE SECURITY] Unauthorized invoice write -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/invoices/invA').update({ amount: 1000 }));
  });

  it('[FUTURE SECURITY] Unauthorized invoice delete -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/invoices/invA').delete());
  });

  it('[PHASE 2] Normal user can read payment (broad read) -> ALLOWED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertSucceeds(db.doc('businesses/bizA/payments/payA').get());
  });

  it('[FUTURE SECURITY] Unauthorized payment write -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/payments/payA').update({ amount: 1000 }));
  });

  it('[FUTURE SECURITY] Unauthorized payment delete -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/payments/payA').delete());
  });
});
