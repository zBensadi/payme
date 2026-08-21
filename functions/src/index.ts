/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

export const bootstrapBusiness = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to bootstrap a business.");
  }

  const uid = request.auth.uid;
  const { businessName, displayName } = request.data;
  
  if (!businessName) {
    throw new HttpsError("invalid-argument", "businessName is required.");
  }

  // Idempotency & Concurrency Guard using a transaction on the global user pointer
  const userPointerRef = db.collection("users").doc(uid);
  
  const result = await db.runTransaction(async (transaction) => {
    const userPointerDoc = await transaction.get(userPointerRef);
    
    if (userPointerDoc.exists) {
      // Safe idempotent return
      const data = userPointerDoc.data();
      return { 
        alreadyInitialized: true,
        businessId: data?.businessId,
        roleId: data?.roleId
      };
    }

    const businessId = crypto.randomUUID();
    const roleId = 'role-owner';
    const nowIso = new Date().toISOString();
    
    const userRecord = await auth.getUser(uid);
    const effectiveEmail = userRecord.email || `user_${uid}@placeholder.com`;
    const effectiveDisplayName = displayName || (effectiveEmail.split('@')[0]);

    const businessRef = db.collection('businesses').doc(businessId);
    const roleRef = db.collection('businesses').doc(businessId).collection('roles').doc(roleId);
    const userRef = db.collection('businesses').doc(businessId).collection('users').doc(uid);
    const settingsRef = db.collection('businesses').doc(businessId).collection('settings').doc('main');

    // 1. Business
    transaction.set(businessRef, {
      businessId,
      name: businessName,
      createdAt: nowIso,
      createdBy: uid,
      isActive: true,
    });

    // 2. Owner role
    transaction.set(roleRef, {
      name: 'Owner',
      description: 'Business owner with full permissions',
      isSystemRole: true,
      isEditable: false,
      isDeletable: false,
      priority: 1000,
      permissions: [],
      isDeleted: false,
      createdAt: nowIso,
      createdBy: uid,
      updatedAt: nowIso,
      updatedBy: uid,
    });

    // 3. User profile
    transaction.set(userRef, {
      uid,
      email: effectiveEmail,
      displayName: effectiveDisplayName,
      businessId,
      roleId,
      isSuperAdmin: false,
      isOwner: true,
      isActive: true,
      isDeleted: false,
      createdAt: nowIso,
      createdBy: uid,
      updatedAt: nowIso,
      updatedBy: uid,
    });

    // 4. Auth Routing Pointer
    transaction.set(userPointerRef, {
      businessId,
      roleId,
      updatedAt: nowIso,
      schemaVersion: 1,
    });

    // 5. Settings
    transaction.set(settingsRef, {
      businessId,
      businessName,
      currencyCode: 'DZD',
      appMode: 'cloud',
      firestoreSchemaVersion: 1,
      createdAt: nowIso,
      createdBy: uid,
      updatedAt: nowIso,
      updatedBy: uid,
    });

    return {
      alreadyInitialized: false,
      businessId,
      roleId
    };
  });

  if (result.alreadyInitialized) {
    logger.info(`[BOOTSTRAP] User ${uid} already bootstrapped business ${result.businessId}. Verifying claims for healing.`);
    
    const userDoc = await db.collection('businesses').doc(result.businessId).collection('users').doc(uid).get();
    if (!userDoc.exists) {
       logger.error(`[BOOTSTRAP] Authoritative user document missing for ${uid} in business ${result.businessId}. Cannot heal claims.`);
       throw new HttpsError("internal", "Inconsistent state detected. Please contact support.");
    }
    
    const uData = userDoc.data();
    if (uData?.isOwner !== true) {
       logger.error(`[BOOTSTRAP] User ${uid} is not an owner in authoritative document. Cannot heal claims.`);
       throw new HttpsError("internal", "Inconsistent state detected. Please contact support.");
    }

    const expectedBusinessId = result.businessId;
    const expectedIsOwner = true;
    const expectedIsSuperAdmin = false;

    const userRecord = await auth.getUser(uid);
    const currentClaims = userRecord.customClaims || {};

    if (currentClaims.businessId !== expectedBusinessId || 
        currentClaims.isOwner !== expectedIsOwner || 
        currentClaims.isSuperAdmin !== expectedIsSuperAdmin) {
        
        logger.info(`[BOOTSTRAP] Claims mismatch detected for user ${uid}. Healing claims.`);
        try {
            await auth.setCustomUserClaims(uid, {
                businessId: expectedBusinessId,
                isOwner: expectedIsOwner,
                isSuperAdmin: expectedIsSuperAdmin
            });
            logger.info(`[BOOTSTRAP] Successfully healed claims for user ${uid}.`);
        } catch (error) {
            logger.error(`[BOOTSTRAP] Failed to heal claims for user ${uid}`, error);
            throw new HttpsError("internal", "Failed to heal security claims. Please contact support.");
        }
    }
    return result;
  }

  // Set Custom Claims outside transaction, since Auth SDK isn't transactional with Firestore
  try {
    await auth.setCustomUserClaims(uid, {
      businessId: result.businessId,
      isOwner: true,
      isSuperAdmin: false
    });
    logger.info(`[BOOTSTRAP] Successfully bootstrapped business ${result.businessId} for user ${uid}.`);
  } catch (error) {
    logger.error(`[BOOTSTRAP] Failed to set custom claims for user ${uid}`, error);
    // Note: since this is the bootstrap flow for the original owner, if claims fail, they won't have access. 
    // We log it and throw. In a real highly-available system we might background retry, but here we explicitly fail.
    throw new HttpsError("internal", "Failed to assign security claims. Please contact support.");
  }

  return result;
});

export const provisionUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to provision.");
  }

  const callerUid = request.auth.uid;
  const callerClaims = request.auth.token;
  const callerBusinessId = callerClaims.businessId as string;
  const callerIsOwner = callerClaims.isOwner === true;
  const callerIsSuperAdmin = callerClaims.isSuperAdmin === true;

  if (!callerBusinessId) {
    throw new HttpsError("permission-denied", "Caller has no business context.");
  }

  const { email, password, displayName, roleId, isActive } = request.data;
  
  if (!email || !password || !roleId) {
    throw new HttpsError("invalid-argument", "email, password, and roleId are required.");
  }

  if (roleId === 'role-owner') {
    throw new HttpsError("permission-denied", "Cannot assign role-owner during provisioning. The system supports only one owner.");
  }

  // Validate that the target role exists in the business
  const targetRoleDoc = await db.collection("businesses").doc(callerBusinessId).collection("roles").doc(roleId).get();
  if (!targetRoleDoc.exists) {
    throw new HttpsError("not-found", "The specified role does not exist.");
  }

  // Check caller permissions
  let canCreateUsers = callerIsOwner || callerIsSuperAdmin;
  if (!canCreateUsers) {
    // Check if caller's role has users.create
    const callerPointerDoc = await db.collection("users").doc(callerUid).get();
    if (callerPointerDoc.exists) {
      const cRole = callerPointerDoc.data()?.roleId;
      if (cRole) {
        const roleDoc = await db.collection("businesses").doc(callerBusinessId).collection("roles").doc(cRole).get();
        if (roleDoc.exists) {
          const perms = roleDoc.data()?.permissions || [];
          if (perms.includes("users.create")) {
            canCreateUsers = true;
          }
        }
      }
    }
  }

  if (!canCreateUsers) {
    throw new HttpsError("permission-denied", "Caller does not have permission to create users.");
  }

  // 1. Create Auth User
  let newUserRecord;
  try {
    newUserRecord = await auth.createUser({
      email,
      password,
      displayName
    });
  } catch (error: any) {
    if (error.code === 'auth/email-already-exists') {
      throw new HttpsError("already-exists", "The email address is already in use.");
    }
    logger.error("[PROVISION] Failed to create Firebase Auth user:", error);
    throw new HttpsError("internal", "Failed to create authentication record.");
  }

  const targetUid = newUserRecord.uid;
  const nowIso = new Date().toISOString();

  // Atomicity & Cleanup block for Firestore + Claims
  try {
    if (email.startsWith('fail_firestore')) {
      throw new Error("Simulated Firestore Failure for Integration Testing");
    }

    const batch = db.batch();
    
    // Auth pointer
    const pointerRef = db.collection("users").doc(targetUid);
    batch.set(pointerRef, {
      businessId: callerBusinessId,
      roleId,
      updatedAt: nowIso,
      schemaVersion: 1
    });

    // Business user
    const userRef = db.collection("businesses").doc(callerBusinessId).collection("users").doc(targetUid);
    batch.set(userRef, {
      uid: targetUid,
      email,
      displayName: displayName || (email.split('@')[0]),
      businessId: callerBusinessId,
      roleId,
      isSuperAdmin: false, // CRITICAL: NEVER TRUE FOR NORMAL PROVISIONING
      isOwner: false,      // CRITICAL: NEVER TRUE FOR NORMAL PROVISIONING
      isActive: isActive !== false,
      isDeleted: false,
      createdAt: nowIso,
      createdBy: callerUid,
      updatedAt: nowIso,
      updatedBy: callerUid
    });

    await batch.commit();

    // Assign claims
    await auth.setCustomUserClaims(targetUid, {
      businessId: callerBusinessId,
      isOwner: false,
      isSuperAdmin: false
    });

    logger.info(`[PROVISION] Successfully provisioned user ${targetUid} in business ${callerBusinessId}.`);
    return { uid: targetUid };
    
  } catch (error) {
    logger.error(`[PROVISION] Failed during Firestore write or claim assignment. Rolling back Auth user ${targetUid}.`, error);
    
    try {
      await auth.deleteUser(targetUid);
      logger.info(`[PROVISION] Successfully rolled back Auth user ${targetUid}.`);
    } catch (cleanupError) {
      logger.error(`[PROVISION] CRITICAL: Failed to rollback Auth user ${targetUid} after provisioning failure. Orphaned record exists.`, cleanupError);
    }

    throw new HttpsError("internal", "Failed to provision user. Rolling back.");
  }
});

export const deactivateUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const callerUid = request.auth.uid;
  const callerClaims = request.auth.token;
  const callerBusinessId = callerClaims.businessId as string;
  const callerIsOwner = callerClaims.isOwner === true;
  const callerIsSuperAdmin = callerClaims.isSuperAdmin === true;

  if (!callerBusinessId) {
    throw new HttpsError("permission-denied", "Caller has no business context.");
  }

  const { uid } = request.data;
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }

  // Check caller permissions
  let canEditUsers = callerIsOwner || callerIsSuperAdmin;
  if (!canEditUsers) {
    const callerPointerDoc = await db.collection("users").doc(callerUid).get();
    if (callerPointerDoc.exists) {
      const cRole = callerPointerDoc.data()?.roleId;
      if (cRole) {
        const roleDoc = await db.collection("businesses").doc(callerBusinessId).collection("roles").doc(cRole).get();
        if (roleDoc.exists) {
          const perms = roleDoc.data()?.permissions || [];
          if (perms.includes("users.edit")) {
            canEditUsers = true;
          }
        }
      }
    }
  }

  if (!canEditUsers) {
    throw new HttpsError("permission-denied", "Caller does not have permission to deactivate users.");
  }

  const nowIso = new Date().toISOString();
  const batch = db.batch();

  // 1. Update isActive: false on user doc
  const userRef = db.collection("businesses").doc(callerBusinessId).collection("users").doc(uid);
  batch.update(userRef, {
    isActive: false,
    updatedAt: nowIso,
    updatedBy: callerUid
  });

  // 2. Add revocation signal (groundwork)
  const revokedRef = db.collection("businesses").doc(callerBusinessId).collection("revoked_tokens").doc(uid);
  batch.set(revokedRef, {
    revokedAt: nowIso,
    revokedBy: callerUid
  });

  await batch.commit();

  logger.info(`[DEACTIVATE] Successfully deactivated user ${uid} and set revocation signal.`);
  return { success: true };
});

export const reactivateUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const callerUid = request.auth.uid;
  const callerClaims = request.auth.token;
  const callerBusinessId = callerClaims.businessId as string;
  const callerIsOwner = callerClaims.isOwner === true;
  const callerIsSuperAdmin = callerClaims.isSuperAdmin === true;

  if (!callerBusinessId) {
    throw new HttpsError("permission-denied", "Caller has no business context.");
  }

  const { uid } = request.data;
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }

  // Check caller permissions
  let canEditUsers = callerIsOwner || callerIsSuperAdmin;
  if (!canEditUsers) {
    const callerPointerDoc = await db.collection("users").doc(callerUid).get();
    if (callerPointerDoc.exists) {
      const cRole = callerPointerDoc.data()?.roleId;
      if (cRole) {
        const roleDoc = await db.collection("businesses").doc(callerBusinessId).collection("roles").doc(cRole).get();
        if (roleDoc.exists) {
          const perms = roleDoc.data()?.permissions || [];
          if (perms.includes("users.edit")) {
            canEditUsers = true;
          }
        }
      }
    }
  }

  if (!canEditUsers) {
    throw new HttpsError("permission-denied", "Caller does not have permission to reactivate users.");
  }

  const nowIso = new Date().toISOString();
  const batch = db.batch();

  // 1. Update isActive: true on user doc
  const userRef = db.collection("businesses").doc(callerBusinessId).collection("users").doc(uid);
  batch.update(userRef, {
    isActive: true,
    updatedAt: nowIso,
    updatedBy: callerUid
  });

  // 2. Remove revocation signal
  const revokedRef = db.collection("businesses").doc(callerBusinessId).collection("revoked_tokens").doc(uid);
  batch.delete(revokedRef);

  await batch.commit();

  logger.info(`[REACTIVATE] Successfully reactivated user ${uid} and removed revocation signal.`);
  return { success: true };
});
