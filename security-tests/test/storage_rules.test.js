const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { getTestEnv, getAnonymousContext, asOwner, asNormalUser, asDeactivated, asAdmin } = require('../helpers');
const fs = require('fs');

describe('Storage Rules Security', function() {
  this.timeout(10000);
  let testEnv;

  before(async () => {
    testEnv = await getTestEnv();
  });

  after(async () => {
    // await testEnv.cleanup();
  });

  afterEach(async () => {
    await testEnv.clearStorage();
  });

  const uploadLogo = async (context, businessId, size = 1000, type = 'image/png') => {
    const storage = context.storage();
    const ref = storage.ref(`businesses/${businessId}/logos/logo.png`);
    const data = Buffer.alloc(size, 'a');
    return ref.put(data, { contentType: type });
  };

  const readLogo = async (context, businessId) => {
    const storage = context.storage();
    const ref = storage.ref(`businesses/${businessId}/logos/logo.png`);
    return ref.getDownloadURL();
  };

  it('allows owner to upload logo <= 2MB', async () => {
    const context = await getTestEnv().then(env => env.authenticatedContext('userA_owner', { businessId: 'bizA', isOwner: true }));
    await assertSucceeds(uploadLogo(context, 'bizA', 1024 * 1024));
  });

  it('rejects owner uploading logo > 2MB', async () => {
    const context = await getTestEnv().then(env => env.authenticatedContext('userA_owner', { businessId: 'bizA', isOwner: true }));
    await assertFails(uploadLogo(context, 'bizA', 3 * 1024 * 1024));
  });

  it('rejects owner uploading non-image file', async () => {
    const context = await getTestEnv().then(env => env.authenticatedContext('userA_owner', { businessId: 'bizA', isOwner: true }));
    await assertFails(uploadLogo(context, 'bizA', 1000, 'application/pdf'));
  });

  it('rejects admin from uploading logo', async () => {
    const context = await getTestEnv().then(env => env.authenticatedContext('userA_admin', { businessId: 'bizA', isOwner: false }));
    await assertFails(uploadLogo(context, 'bizA'));
  });

  it('allows any business user to read logo', async () => {
    // Upload as owner first
    const ownerContext = await getTestEnv().then(env => env.authenticatedContext('userA_owner', { businessId: 'bizA', isOwner: true }));
    await assertSucceeds(uploadLogo(ownerContext, 'bizA'));

    // Read as normal user
    const userContext = await getTestEnv().then(env => env.authenticatedContext('userA_normal', { businessId: 'bizA' }));
    await assertSucceeds(readLogo(userContext, 'bizA'));
  });

  it('rejects users from other businesses from reading logo', async () => {
    // Upload as owner of bizA
    const ownerContext = await getTestEnv().then(env => env.authenticatedContext('userA_owner', { businessId: 'bizA', isOwner: true }));
    await assertSucceeds(uploadLogo(ownerContext, 'bizA'));

    // Read as user from bizB
    const otherContext = await getTestEnv().then(env => env.authenticatedContext('userB_normal', { businessId: 'bizB' }));
    await assertFails(readLogo(otherContext, 'bizA'));
  });

  it('rejects anonymous access', async () => {
    const context = await getTestEnv().then(env => env.unauthenticatedContext());
    await assertFails(readLogo(context, 'bizA'));
  });

  const deleteLogo = async (context, businessId) => {
    const storage = context.storage();
    const ref = storage.ref(`businesses/${businessId}/logos/logo.png`);
    return ref.delete();
  };

  it('allows owner to delete logo', async () => {
    const ownerContext = await getTestEnv().then(env => env.authenticatedContext('userA_owner', { businessId: 'bizA', isOwner: true }));
    await assertSucceeds(uploadLogo(ownerContext, 'bizA'));
    await assertSucceeds(deleteLogo(ownerContext, 'bizA'));
  });

  it('rejects admin from deleting logo', async () => {
    const ownerContext = await getTestEnv().then(env => env.authenticatedContext('userA_owner', { businessId: 'bizA', isOwner: true }));
    await assertSucceeds(uploadLogo(ownerContext, 'bizA'));

    const adminContext = await getTestEnv().then(env => env.authenticatedContext('userA_admin', { businessId: 'bizA', isOwner: false }));
    await assertFails(deleteLogo(adminContext, 'bizA'));
  });

  it('rejects users from other businesses from deleting logo', async () => {
    const ownerContext = await getTestEnv().then(env => env.authenticatedContext('userA_owner', { businessId: 'bizA', isOwner: true }));
    await assertSucceeds(uploadLogo(ownerContext, 'bizA'));

    const otherContext = await getTestEnv().then(env => env.authenticatedContext('userB_owner', { businessId: 'bizB', isOwner: true }));
    await assertFails(deleteLogo(otherContext, 'bizA'));
  });
});
