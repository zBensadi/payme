const admin = require('firebase-admin');
const { expect } = require('chai');
const { cleanupEnv } = require('../helpers');

const PROJECT_ID = 'demo-payme-test';

// Connect admin SDK to emulator
if (!admin.apps.length) {
  process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
  admin.initializeApp({ projectId: PROJECT_ID });
}
const db = admin.firestore();
const auth = admin.auth();

// Function calling helper
async function callFunction(funcName, data, context) {
  // We can simulate calling the HTTP endpoints of the emulator.
  // Alternatively, since this is for testing logic, we can construct raw HTTP requests.
  const fetch = require('node-fetch');
  const url = `http://127.0.0.1:5001/${PROJECT_ID}/us-central1/${funcName}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': context.auth ? `Bearer ${context.auth.token}` : ''
    },
    body: JSON.stringify({ data })
  });
  
  const body = await response.json();
  if (body.error) {
    const err = new Error(body.error.message || 'Function failed');
    err.status = body.error.status;
    throw err;
  }
  return body.result || body.data;
}

// Generate token for testing
async function generateToken(uid, customClaims = {}) {
  // Create user if not exists
  try {
    await auth.getUser(uid);
  } catch (e) {
    await auth.createUser({ uid });
  }
  await auth.setCustomUserClaims(uid, customClaims);
  // The Firebase Auth Emulator can generate ID tokens via an undocumented endpoint or custom token minting.
  // We use the REST API to exchange custom token for ID token in emulator
  const customToken = await auth.createCustomToken(uid);
  const fetch = require('node-fetch');
  const apiKey = 'fake-api-key'; // emulator accepts any api key
  const res = await fetch(`http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token: customToken, returnSecureToken: true })
  });
  const data = await res.json();
  return data.idToken;
}

describe('Phase 3 Cloud Functions Security & Logic', function() {
  this.timeout(10000);

  beforeEach(async () => {
    await cleanupEnv(PROJECT_ID);
  });

  after(async () => {
    await Promise.all(admin.apps.map(app => app.delete()));
  });

  describe('bootstrapBusiness', () => {
    it('denies anonymous callers', async () => {
      try {
        await callFunction('bootstrapBusiness', { businessName: 'Test' }, {});
        expect.fail('Should have thrown');
      } catch (e) {
        expect(e.status).to.equal('UNAUTHENTICATED');
      }
    });

    it('successfully bootstraps a new user and assigns claims', async () => {
      const uid = `new_owner_${Date.now()}`;
      const token = await generateToken(uid);
      
      const result = await callFunction('bootstrapBusiness', { businessName: 'My Biz' }, { auth: { token } });
      
      expect(result.businessId).to.not.be.undefined;
      expect(result.roleId).to.equal('role-owner');
      expect(result.alreadyInitialized).to.be.false;

      // Verify custom claims were set correctly
      const userRecord = await auth.getUser(uid);
      expect(userRecord.customClaims.businessId).to.equal(result.businessId);
      expect(userRecord.customClaims.isOwner).to.be.true;
      expect(userRecord.customClaims.isSuperAdmin).to.be.false;
      
      // Verify Firestore writes and isSuperAdmin=false in profile
      const pointer = await db.collection('users').doc(uid).get();
      expect(pointer.exists).to.be.true;
      const userProfile = await db.collection('businesses').doc(result.businessId).collection('users').doc(uid).get();
      expect(userProfile.data().isSuperAdmin).to.be.false;
      expect(userProfile.data().isOwner).to.be.true;
    });

    it('handles true parallel concurrency safely (exactly one initialization)', async () => {
      const uid = `parallel_owner_${Date.now()}`;
      const token = await generateToken(uid);
      
      const reqs = [
        callFunction('bootstrapBusiness', { businessName: 'Biz Parallel' }, { auth: { token } }),
        callFunction('bootstrapBusiness', { businessName: 'Biz Parallel' }, { auth: { token } })
      ];

      const [res1, res2] = await Promise.all(reqs);

      // Exactly one should be initialized, the other should return alreadyInitialized = true
      const initializedCount = (res1.alreadyInitialized ? 0 : 1) + (res2.alreadyInitialized ? 0 : 1);
      expect(initializedCount).to.equal(1);
      
      const pointerDoc = await db.collection('users').doc(uid).get();
      expect(pointerDoc.exists).to.be.true;

      const userRecord = await auth.getUser(uid);
      expect(userRecord.customClaims.businessId).to.equal(pointerDoc.data().businessId);
    });

    it('returns safely (idempotent) on repeated bootstrap', async () => {
      const uid = `idemp_owner_${Date.now()}`;
      const token = await generateToken(uid);
      
      const res1 = await callFunction('bootstrapBusiness', { businessName: 'Biz 1' }, { auth: { token } });
      expect(res1.alreadyInitialized).to.be.false;

      const res2 = await callFunction('bootstrapBusiness', { businessName: 'Biz 2' }, { auth: { token } });
      expect(res2.alreadyInitialized).to.be.true;
      expect(res2.businessId).to.equal(res1.businessId); // Did not create a new business
    });

    it('heals missing custom claims on retry (Claim Healing)', async () => {
      const uid = `heal_owner_${Date.now()}`;
      const token = await generateToken(uid);
      
      // 1. Manually simulate a broken state: Firestore committed, but claims failed.
      const businessId = 'broken_biz_id';
      await db.collection('businesses').doc(businessId).set({ name: 'Broken' });
      await db.collection('businesses').doc(businessId).collection('users').doc(uid).set({
        uid, isOwner: true, isSuperAdmin: false
      });
      await db.collection('users').doc(uid).set({
        businessId, roleId: 'role-owner'
      });
      // (Claims are currently empty for this user)

      // 2. Retry bootstrap
      const res = await callFunction('bootstrapBusiness', { businessName: 'Retry' }, { auth: { token } });
      expect(res.alreadyInitialized).to.be.true;
      expect(res.businessId).to.equal(businessId);

      // 3. Verify claims were repaired
      const userRecord = await auth.getUser(uid);
      expect(userRecord.customClaims.businessId).to.equal(businessId);
      expect(userRecord.customClaims.isOwner).to.be.true;
      expect(userRecord.customClaims.isSuperAdmin).to.be.false;
    });
  });

  describe('provisionUser', () => {
    it('denies provisioning if caller is not authorized (no claims)', async () => {
      const token = await generateToken(`norm_${Date.now()}`, { businessId: 'b1', isOwner: false });
      
      // Setup role so it passes validation and hits the permission check
      await db.collection('businesses').doc('b1').collection('roles').doc('some-role').set({ name: 'Role' });

      try {
        await callFunction('provisionUser', { 
          email: 'test@example.com', password: 'password', roleId: 'some-role' 
        }, { auth: { token } });
        expect.fail('Should have thrown');
      } catch (e) {
        expect(e.status).to.equal('PERMISSION_DENIED');
      }
    });

    it('allows Owner to provision a user and explicitly sets isOwner=false', async () => {
      const ownerToken = await generateToken(`owner_${Date.now()}`, { businessId: 'b1', isOwner: true });
      
      // Setup role
      await db.collection('businesses').doc('b1').collection('roles').doc('role-employee').set({ name: 'Emp' });

      const result = await callFunction('provisionUser', { 
        email: `employee_${Date.now()}@example.com`, password: 'password', roleId: 'role-employee'
      }, { auth: { token: ownerToken } });
      
      const newUid = result.uid;
      expect(newUid).to.not.be.undefined;

      // Verify Firestore explicitly sets isOwner false
      const userDoc = await db.collection('businesses').doc('b1').collection('users').doc(newUid).get();
      expect(userDoc.data().isOwner).to.be.false;
      expect(userDoc.data().isSuperAdmin).to.be.false;
      
      // Verify claims
      const newUserRecord = await auth.getUser(newUid);
      expect(newUserRecord.customClaims.businessId).to.equal('b1');
      expect(newUserRecord.customClaims.isOwner).to.be.false;
      expect(newUserRecord.customClaims.isSuperAdmin).to.be.false;
    });

    it('denies assigning role-owner during provisioning', async () => {
      const ownerToken = await generateToken(`owner_${Date.now()}`, { businessId: 'b1', isOwner: true });
      try {
        await callFunction('provisionUser', { 
          email: 'hacker@example.com', password: 'password', roleId: 'role-owner'
        }, { auth: { token: ownerToken } });
        expect.fail('Should have thrown');
      } catch (e) {
        expect(e.status).to.equal('PERMISSION_DENIED');
      }
    });

    it('denies provisioning if the requested role does not exist', async () => {
      const ownerToken = await generateToken(`owner_${Date.now()}`, { businessId: 'b1', isOwner: true });
      try {
        await callFunction('provisionUser', { 
          email: `emp_${Date.now()}@example.com`, password: 'password', roleId: 'non-existent-role'
        }, { auth: { token: ownerToken } });
        expect.fail('Should have thrown');
      } catch (e) {
        expect(e.status).to.equal('NOT_FOUND');
      }
    });

    it('rolls back Auth user if Firestore fails (simulated)', async () => {
      const ownerToken = await generateToken(`owner_${Date.now()}`, { businessId: 'b1', isOwner: true });
      const email = `fail_firestore_${Date.now()}@example.com`;

      // Setup role so it passes validation
      await db.collection('businesses').doc('b1').collection('roles').doc('valid-role').set({ name: 'Valid' });

      try {
        await callFunction('provisionUser', { 
          email, password: 'password', roleId: 'valid-role'
        }, { auth: { token: ownerToken } });
        expect.fail('Should have thrown');
      } catch (e) {
        expect(e.status).to.equal('INTERNAL');
      }

      // Verify Auth user was deleted
      try {
        const user = await auth.getUserByEmail(email);
        expect.fail('User should have been deleted, but was found: ' + user.uid);
      } catch (err) {
        expect(err.code).to.equal('auth/user-not-found');
      }
    });
  });
  
  describe('deactivateUser', () => {
    it('sets isActive false and writes to revoked_tokens', async () => {
      const ownerToken = await generateToken(`owner_${Date.now()}`, { businessId: 'b1', isOwner: true });
      
      // Setup fake user
      await db.collection('businesses').doc('b1').collection('users').doc('user_to_kill').set({
        isActive: true
      });

      await callFunction('deactivateUser', { uid: 'user_to_kill' }, { auth: { token: ownerToken } });
      
      const doc = await db.collection('businesses').doc('b1').collection('users').doc('user_to_kill').get();
      expect(doc.data().isActive).to.be.false;

      const revoked = await db.collection('businesses').doc('b1').collection('revoked_tokens').doc('user_to_kill').get();
      expect(revoked.exists).to.be.true;
    });
  });

});
