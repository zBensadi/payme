const admin = require('firebase-admin');

// Initialize Firebase Admin (assuming default application credentials)
admin.initializeApp();
const auth = admin.auth();
const db = admin.firestore();

// Known Test Owner UID used for Dev Project Migration
const KNOWN_TEST_OWNER_UID = 'YOUR_TEST_OWNER_UID_HERE';

async function backfillClaims(dryRun = true) {
  console.log(`Starting Custom Claims Backfill (Dry Run: ${dryRun})`);
  
  let listUsersResult;
  let pageToken = undefined;
  
  do {
    listUsersResult = await auth.listUsers(1000, pageToken);
    for (const userRecord of listUsersResult.users) {
      const uid = userRecord.uid;
      console.log(`\nProcessing user: ${uid} (${userRecord.email})`);
      
      try {
        // 1. Fetch global pointer
        const pointerDoc = await db.collection('users').doc(uid).get();
        if (!pointerDoc.exists) {
          console.warn(`  [SKIP] No global pointer found for ${uid}`);
          continue;
        }
        
        const pointerData = pointerDoc.data();
        const businessId = pointerData.businessId;
        const pointerRoleId = pointerData.roleId;
        
        if (!businessId) {
          console.warn(`  [SKIP] Global pointer missing businessId for ${uid}`);
          continue;
        }

        // 2. Fetch business user document
        const businessUserDoc = await db.collection('businesses').doc(businessId).collection('users').doc(uid).get();
        if (!businessUserDoc.exists) {
          console.warn(`  [SKIP] No business-scoped user document found at businesses/${businessId}/users/${uid}`);
          continue;
        }

        const businessUserData = businessUserDoc.data();
        const businessUserRoleId = businessUserData.roleId;
        const businessUserIsOwner = businessUserData.isOwner === true;
        const businessUserIsSuperAdmin = businessUserData.isSuperAdmin === true;

        // 3. Consistency Validation
        if (pointerRoleId !== businessUserRoleId) {
          console.warn(`  [SKIP] Role mismatch: pointer=${pointerRoleId}, business=${businessUserRoleId}`);
          continue;
        }

        // 4. Trust Validation
        // For Alpha 17 dev environment, we only trust the known test owner UID for isOwner=true.
        // We never trust isSuperAdmin=true from client data.
        let isOwner = false;
        let isSuperAdmin = false;

        if (businessUserIsOwner) {
          if (uid === KNOWN_TEST_OWNER_UID) {
            console.log(`  [TRUST] User ${uid} matches known test owner. Assigning isOwner=true.`);
            isOwner = true;
          } else {
            console.warn(`  [WARN] User ${uid} claims isOwner=true but is not the known test owner. Forcing isOwner=false.`);
            isOwner = false;
          }
        }

        if (businessUserIsSuperAdmin) {
          console.warn(`  [WARN] User ${uid} claims isSuperAdmin=true. Stripping privilege for safety.`);
          isSuperAdmin = false;
        }

        // 5. Compare existing claims
        const currentClaims = userRecord.customClaims || {};
        const claimsDiffer = (
          currentClaims.businessId !== businessId ||
          currentClaims.isOwner !== isOwner ||
          currentClaims.isSuperAdmin !== isSuperAdmin
        );

        if (!claimsDiffer) {
          console.log(`  [OK] Claims are already consistent for ${uid}. No update needed.`);
          continue;
        }

        const newClaims = {
          ...currentClaims,
          businessId,
          isOwner,
          isSuperAdmin
        };

        if (dryRun) {
          console.log(`  [DRY-RUN] Would update claims for ${uid} to:`, newClaims);
        } else {
          await auth.setCustomUserClaims(uid, newClaims);
          console.log(`  [SUCCESS] Updated claims for ${uid} to:`, newClaims);
        }
        
      } catch (error) {
        console.error(`  [ERROR] Failed to process user ${uid}:`, error);
      }
    }
    
    pageToken = listUsersResult.pageToken;
  } while (pageToken);
  
  console.log(`\nBackfill complete.`);
}

// Check for dry-run flag
const args = process.argv.slice(2);
const isDryRun = !args.includes('--execute');

backfillClaims(isDryRun).catch(console.error);
