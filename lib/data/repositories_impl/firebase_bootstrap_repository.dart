import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/bootstrap_repository.dart';

class FirebaseBootstrapRepository implements BootstrapRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  FirebaseBootstrapRepository({FirebaseFirestore? firestore, Uuid? uuid})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<BootstrapResult?>> checkExistingBusiness({
    required String uid,
    required String email,
  }) async {
    debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] ENTER checkExistingBusiness uid=$uid email=$email');
    try {
      debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] BEFORE users/$uid.get()');
      final pointerDoc = await _firestore.collection('users').doc(uid).get();
      debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] AFTER  users/$uid.get() → exists=${pointerDoc.exists} data=${pointerDoc.data()}');

      if (pointerDoc.exists) {
        final data = pointerDoc.data()!;
        final businessId = data['businessId'] as String?;
        final roleId = data['roleId'] as String?;
        debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] pointer exists → businessId=$businessId roleId=$roleId');

        if (businessId != null && roleId != null) {
          debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] BEFORE businesses/$businessId/roles/$roleId.get()');
          final roleDoc = await _firestore
              .collection('businesses')
              .doc(businessId)
              .collection('roles')
              .doc(roleId)
              .get();
          debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] AFTER  businesses/$businessId/roles/$roleId.get() → exists=${roleDoc.exists} data=${roleDoc.data()}');

          debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] BEFORE businesses/$businessId/users/$uid.get()');
          final userDoc = await _firestore
              .collection('businesses')
              .doc(businessId)
              .collection('users')
              .doc(uid)
              .get();
          debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] AFTER  businesses/$businessId/users/$uid.get() → exists=${userDoc.exists} data=${userDoc.data()}');

          if (roleDoc.exists && userDoc.exists) {
            debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] BEFORE mapping Firestore documents into AppUser/UserRole');
            final rData = roleDoc.data()!;
            final uData = userDoc.data()!;
            final existingUser = AppUser(
              uid: uid,
              email: uData['email'] ?? email,
              displayName: uData['displayName'],
              businessId: businessId,
              roleId: roleId,
              isSuperAdmin: uData['isSuperAdmin'] ?? true,
              isOwner: uData['isOwner'] ?? true,
              isActive: uData['isActive'] ?? true,
              createdAt: uData['createdAt'] != null
                  ? DateTime.parse(uData['createdAt'] as String).toLocal()
                  : DateTime.now(),
              updatedAt: uData['updatedAt'] != null
                  ? DateTime.parse(uData['updatedAt'] as String).toLocal()
                  : DateTime.now(),
            );
            final existingRole = UserRole(
              id: roleId,
              name: rData['name'] ?? 'Owner',
              isSystemRole: rData['isSystemRole'] ?? true,
              permissions: List<String>.from(rData['permissions'] ?? []),
              priority: rData['priority'] ?? 0,
              createdAt: rData['createdAt'] != null
                  ? DateTime.parse(rData['createdAt'] as String).toLocal()
                  : DateTime.now(),
              updatedAt: rData['updatedAt'] != null
                  ? DateTime.parse(rData['updatedAt'] as String).toLocal()
                  : DateTime.now(),
            );
            debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] AFTER  mapping → AppUser uid=${existingUser.uid} businessId=${existingUser.businessId} roleId=${existingUser.roleId}');
            debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] BEFORE returning Success(BootstrapResult)');
            return Success(BootstrapResult(user: existingUser, role: existingRole));
          } else {
            debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] BEFORE returning Failure — pointer exists but domain docs missing: roleDoc.exists=${roleDoc.exists} userDoc.exists=${userDoc.exists}');
            return Failure(DatabaseFailure('Domain user or role not found for routing pointer.'));
          }
        } else {
          debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] pointer data incomplete (businessId or roleId null) → returning Success(null)');
        }
      } else {
        debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] pointer does not exist → returning Success(null) (genuine new user)');
      }
      debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] BEFORE returning Success(null)');
      return const Success(null);
    } on FirebaseException catch (e, stack) {
      debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] FirebaseException caught: code=${e.code} message=${e.message}\n$stack');
      return Failure(DatabaseFailure('Failed to check existing business: $e'));
    } catch (e, stack) {
      debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] EXCEPTION caught: $e\n$stack');
      return Failure(DatabaseFailure('Failed to check existing business: $e'));
    }
  }

  @override
  Future<Result<BootstrapResult>> bootstrapBusiness({
    required String uid,
    required String email,
    required String? displayName,
    required String businessName,
  }) async {
    try {
      // 1. Business provisioning
      final businessId = _uuid.v4();

      final roleId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final nowIso = now.toIso8601String();
      final effectiveDisplayName = displayName ?? email.split('@').first;

      final batch = _firestore.batch();

      // 1. Business document
      final businessRef = _firestore.collection('businesses').doc(businessId);
      batch.set(businessRef, {
        'businessId': businessId,
        'name': businessName,
        'createdAt': nowIso,
        'createdBy': uid,
        'isActive': true,
      });

      // 2. Owner role
      // CANONICAL PATH: businesses/{businessId}/roles/{roleId}
      // This is the same path used by RoleRemoteDataSource.pullRoles()
      final roleRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('roles')
          .doc(roleId);
      batch.set(roleRef, {
        'name': 'Owner',
        'description': 'Business owner with full permissions',
        'isSystemRole': true,
        'isEditable': false,
        'isDeletable': false,
        'priority': 0,
        'permissions': <String>[], // Populated by PermissionService.isOwner
        'isDeleted': false,
        'createdAt': nowIso,
        'createdBy': uid,
        'updatedAt': nowIso,
        'updatedBy': uid,
      });

      // 3. User profile
      // CANONICAL PATH: businesses/{businessId}/users/{uid}
      // This is the same path used by UserRemoteDataSource.pullUsers()
      final userRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('users')
          .doc(uid);
      batch.set(userRef, {
        'uid': uid,
        'email': email,
        'displayName': effectiveDisplayName,
        'businessId': businessId,
        'roleId': roleId,
        'isSuperAdmin': true,
        'isOwner': true,
        'isActive': true,
        'isDeleted': false,
        'createdAt': nowIso,
        'createdBy': uid,
        'updatedAt': nowIso,
        'updatedBy': uid,
      });

      // 4. Auth Routing Pointer
      // CANONICAL PATH: users/{uid}
      // This is solely for discovery when logging in on a new device.
      // ARCHITECTURAL INVARIANT: This is an authentication routing layer, not a domain model.
      // The canonical user data always lives under businesses/{businessId}/users/{uid}.
      final pointerRef = _firestore.collection('users').doc(uid);
      batch.set(pointerRef, {
        'businessId': businessId,
        'roleId': roleId,
        'updatedAt': nowIso,
        'schemaVersion': 1,
      });

      // 5. Business Settings
      final settingsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('settings')
          .doc('main');
      batch.set(settingsRef, {
        'businessId': businessId,
        'businessName': businessName,
        'currencyCode': 'DZD',
        'appMode': 'cloud',
        'firestoreSchemaVersion': 1,
        'createdAt': nowIso,
        'createdBy': uid,
        'updatedAt': nowIso,
        'updatedBy': uid,
      });

      await batch.commit();

      final appUser = AppUser(
        uid: uid,
        email: email,
        displayName: effectiveDisplayName,
        businessId: businessId,
        roleId: roleId,
        isSuperAdmin: true,
        isOwner: true,
        isActive: true,
        createdAt: now.toLocal(),
        updatedAt: now.toLocal(),
      );

      final userRole = UserRole(
        id: roleId,
        name: 'Owner',
        description: 'Business owner with full permissions',
        isSystemRole: true,
        isEditable: false,
        isDeletable: false,
        priority: 0,
        permissions: const [],
        createdAt: now.toLocal(),
        updatedAt: now.toLocal(),
      );

      return Success(BootstrapResult(user: appUser, role: userRole));

    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException during bootstrap: $e\n$stack');
      return Failure(DatabaseFailure('Firebase error: ${e.code} - ${e.message}'));
    } catch (e, stack) {
      debugPrint('Unexpected error during bootstrap: $e\n$stack');
      return Failure(DatabaseFailure('Unexpected error: $e'));
    }
  }
}
