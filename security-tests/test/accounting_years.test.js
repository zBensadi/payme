const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { asNormalUser, asOwner, loadSyntheticFixtures, cleanupEnv } = require('../helpers');

describe('Accounting Year Tests', () => {
  before(async () => {
    await loadSyntheticFixtures();
  });

  after(async () => {
    await cleanupEnv();
  });

  // Note: userA_normal has 'clients.view' but NOT 'accounting_years.view' or 'accounting_years.manage'

  it('[PHASE 2] Normal user can read accounting years (broad read) -> ALLOWED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertSucceeds(db.doc('businesses/bizA/accounting_years/yearA').get());
  });

  it('[FUTURE SECURITY] User without accounting_years.manage cannot create -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/accounting_years/new-year').set({ name: '2027', isActive: false }));
  });

  it('[FUTURE SECURITY] User without accounting_years.manage cannot update -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/accounting_years/yearA').update({ isActive: false }));
  });

  it('[FUTURE SECURITY] User without accounting_years.manage cannot delete -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/accounting_years/yearA').delete());
  });

  it('[FUTURE SECURITY] Authorized owner/manager operation -> ALLOWED', async () => {
    const db = await asOwner('bizA', 'userA_owner');
    await assertSucceeds(db.doc('businesses/bizA/accounting_years/yearA').get());
    // (We do not implement the trusted deleteAccountingYear Cloud Function validation here yet)
  });
});
