import sys

file_path = "lib/data/repositories_impl/firebase_bootstrap_repository.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

migration_code = """
  Future<String?> _migrateLegacyOwnerRoleIfNeeded(String businessId, String? currentRoleId) async {
    try {
      final rolesQuery = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('roles')
          .where('name', isEqualTo: 'Owner')
          .get();

      String? legacyRoleId;
      for (var doc in rolesQuery.docs) {
        if (doc.id != 'role-owner') {
          legacyRoleId = doc.id;
          break;
        }
      }

      if (legacyRoleId == null) {
        // No legacy role found, return existing roleId or role-owner
        return currentRoleId == 'role-super-admin' ? 'role-owner' : currentRoleId;
      }

      debugPrint('[BSREPO][MIGRATION] Found legacy Owner role: $legacyRoleId. Migrating to role-owner.');

      // 1. Create canonical role-owner
      final nowIso = DateTime.now().toUtc().toIso8601String();
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('roles')
          .doc('role-owner')
          .set({
        'name': 'Owner',
        'description': 'Business owner with full permissions',
        'isSystemRole': true,
        'isEditable': false,
        'isDeletable': false,
        'priority': 1000,
        'permissions': <String>[],
        'isDeleted': false,
        'createdAt': nowIso,
        'updatedAt': nowIso,
      }, SetOptions(merge: true));

      // 2. Find all users referencing the legacy role
      final usersQuery = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('users')
          .where('roleId', isEqualTo: legacyRoleId)
          .get();

      // 3. Chunked updates
      final int batchSize = 200;
      for (var i = 0; i < usersQuery.docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < usersQuery.docs.length) ? i + batchSize : usersQuery.docs.length;
        final chunk = usersQuery.docs.sublist(i, end);

        for (var userDoc in chunk) {
          batch.update(userDoc.reference, {'roleId': 'role-owner'});
          final pointerRef = _firestore.collection('users').doc(userDoc.id);
          batch.update(pointerRef, {'roleId': 'role-owner'});
        }
        
        await batch.commit();
      }

      // 4. Delete legacy role
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('roles')
          .doc(legacyRoleId)
          .delete();
          
      return 'role-owner';
    } catch (e, stack) {
      debugPrint('[BSREPO][MIGRATION] Error: $e');
      return currentRoleId;
    }
  }
}
"""

content = content.replace("\n}\n", "\n" + migration_code)

old_check = """        if (businessId != null && roleId != null) {
          debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] BEFORE businesses/$businessId/roles/$roleId.get()');
          final roleDoc = await _firestore
              .collection('businesses')
              .doc(businessId)
              .collection('roles')
              .doc(roleId)
              .get();"""
              
new_check = """        if (businessId != null && roleId != null) {
          final effectiveRoleId = await _migrateLegacyOwnerRoleIfNeeded(businessId, roleId) ?? roleId;
          debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] BEFORE businesses/$businessId/roles/$effectiveRoleId.get()');
          final roleDoc = await _firestore
              .collection('businesses')
              .doc(businessId)
              .collection('roles')
              .doc(effectiveRoleId)
              .get();"""
              
content = content.replace(old_check, new_check)
content = content.replace("businesses/$businessId/roles/$roleId.get", "businesses/$businessId/roles/$effectiveRoleId.get")
content = content.replace("roleId: roleId,", "roleId: effectiveRoleId,")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

