const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { asNormalUser, loadSyntheticFixtures, cleanupEnv } = require('../helpers');

describe('Global Users Pointer Tests', () => {
  let dbA;

  before(async () => {
    await loadSyntheticFixtures();
    dbA = await asNormalUser('bizA', 'userA_normal');
  });

  after(async () => {
    await cleanupEnv();
  });

  it('[FUTURE SECURITY] User A reads /users/userB -> DENIED', async () => {
    await assertFails(dbA.doc('users/userB_owner').get());
  });

  it('[FUTURE SECURITY] User A modifies another user global pointer -> DENIED', async () => {
    await assertFails(dbA.doc('users/userA_admin').set({ businessId: 'bizB' }, { merge: true }));
  });

  it('[FUTURE SECURITY] User reads their own global user pointer -> ALLOWED', async () => {
    // Currently this will succeed, and in the future it should also succeed.
    await assertSucceeds(dbA.doc('users/userA_normal').get());
  });
});
