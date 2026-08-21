const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { asNormalUser, asAdmin, asOwner, loadSyntheticFixtures, cleanupEnv } = require('../helpers');

describe('User Security Tests', () => {
  before(async () => {
    await loadSyntheticFixtures();
  });

  after(async () => {
    await cleanupEnv();
  });

  it('[FUTURE SECURITY] Unauthorized user creation -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/users/new-user').set({ uid: 'new-user', email: 'test@test.com' }));
  });

  it('[PHASE 2] Admin (users.create) assigns role-owner -> DENIED', async () => {
    // Admin has users.create, but cannot assign role-owner
    const db = await asAdmin('bizA', 'userA_admin');
    await assertFails(db.doc('businesses/bizA/users/new-admin-user').set({ uid: 'new-admin-user', email: 'test@test.com', businessId: 'bizA', roleId: 'role-owner', isOwner: false, isSuperAdmin: false }));
  });

  it('[PHASE 2] Admin (users.create) creates normal user -> ALLOWED', async () => {
    const db = await asAdmin('bizA', 'userA_admin');
    await assertSucceeds(db.doc('businesses/bizA/users/new-admin-user2').set({ uid: 'new-admin-user2', email: 'test@test.com', businessId: 'bizA', roleId: 'role-user', isOwner: false, isSuperAdmin: false }));
  });

  it('[PHASE 2] Owner assigns role-owner -> ALLOWED', async () => {
    const db = await asOwner('bizA', 'userA_owner');
    await assertSucceeds(db.doc('businesses/bizA/users/new-owner-user').set({ uid: 'new-owner-user', email: 'test@test.com', businessId: 'bizA', roleId: 'role-owner', isOwner: false, isSuperAdmin: false }));
  });

  it('[FUTURE SECURITY] Unauthorized user deletion -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/users/userA_admin').delete());
  });

  it('[FUTURE SECURITY] Normal user modifying another user security fields -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    await assertFails(db.doc('businesses/bizA/users/userA_admin').set({ isSuperAdmin: true }, { merge: true }));
  });

  it('[FUTURE SECURITY] Normal user changing their own security fields -> DENIED', async () => {
    const db = await asNormalUser('bizA', 'userA_normal');
    const docRef = db.doc('businesses/bizA/users/userA_normal');
    // Testing multiple fields
    await assertFails(docRef.update({ isOwner: true }));
    await assertFails(docRef.update({ isSuperAdmin: true }));
    await assertFails(docRef.update({ roleId: 'role-owner' }));
    await assertFails(docRef.update({ businessId: 'bizB' }));
  });

  it('[FUTURE SECURITY] Normal user changing ordinary profile fields -> ALLOWED', async () => {
    // Note: The exact editable profile-field list (e.g. displayName) is not fully clear from codebase.
    // Assuming displayName is allowed.
    const db = await asNormalUser('bizA', 'userA_normal');
    const docRef = db.doc('businesses/bizA/users/userA_normal');
    await assertSucceeds(docRef.update({ displayName: 'Updated Name' }));
  });
});
