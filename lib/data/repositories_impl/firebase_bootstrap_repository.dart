import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';


import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/bootstrap_repository.dart';

class FirebaseBootstrapRepository implements BootstrapRepository {
  final FirebaseFirestore _firestore;
  FirebaseBootstrapRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
          String effectiveRoleId;
          try {
            effectiveRoleId = await _migrateLegacyOwnerRoleIfNeeded(businessId, roleId);
          } catch (e) {
            debugPrint('[BSREPO][MIGRATION] Migration failed for $businessId: $e');
            return Failure(DatabaseFailure('Legacy role migration failed. Please try again.'));
          }
          debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] BEFORE businesses/$businessId/roles/$effectiveRoleId.get()');
          final roleDoc = await _firestore
              .collection('businesses')
              .doc(businessId)
              .collection('roles')
              .doc(effectiveRoleId)
              .get();
          debugPrint('[BSREPO][${DateTime.now().toIso8601String()}] AFTER  businesses/$businessId/roles/$effectiveRoleId.get() → exists=${roleDoc.exists} data=${roleDoc.data()}');

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
              roleId: effectiveRoleId,
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
      final effectiveDisplayName = displayName ?? email.split('@').first;
      
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User is not authenticated.');
      }

      final response = await http.post(
        Uri.parse('https://us-central1-payme-dev-967bb.cloudfunctions.net/bootstrapBusiness'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'businessName': businessName,
            'displayName': effectiveDisplayName,
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Server returned status code: ${response.statusCode} - ${response.body}');
      }

      final result = jsonDecode(response.body);
      final data = result['result'] ?? result['data'];
      
      if (data == null) {
        throw Exception('Server returned empty data: ${response.body}');
      }

      final businessId = data['businessId'] as String;
      final roleId = data['roleId'] as String;
      
      // Force token refresh after successful bootstrap (or if we hit the safe initialized state)
      await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);

      final now = DateTime.now().toUtc();

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
        priority: 1000,
        permissions: const [],
        createdAt: now.toLocal(),
        updatedAt: now.toLocal(),
      );

      return Success(BootstrapResult(user: appUser, role: userRole));

    } catch (e, stack) {
      debugPrint('Error during bootstrap (REST fallback): $e\n$stack');
      return Failure(DatabaseFailure('Server error: $e'));
    }
  }

  Future<String> _migrateLegacyOwnerRoleIfNeeded(String businessId, String currentRoleId) async {
    final rolesQuery = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('roles')
        .get();

    final legacyRoleIds = <String>[];
    for (var doc in rolesQuery.docs) {
      if (doc.id == 'role-owner') continue;
      
      if (doc.id == 'role-super-admin') {
        legacyRoleIds.add(doc.id);
        continue;
      }
      
      final data = doc.data();
      if (data['name'] == 'Owner' && data['isSystemRole'] == true && data['isEditable'] == false) {
        legacyRoleIds.add(doc.id);
      }
    }

    if (legacyRoleIds.isEmpty) {
      return currentRoleId;
    }

    debugPrint('[BSREPO][MIGRATION] Found legacy roles to migrate: $legacyRoleIds');

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

    // 2. Find all users referencing the legacy roles
    final allUsers = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (var i = 0; i < legacyRoleIds.length; i += 10) {
      final end = (i + 10 < legacyRoleIds.length) ? i + 10 : legacyRoleIds.length;
      final chunk = legacyRoleIds.sublist(i, end);
      final usersQuery = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('users')
          .where('roleId', whereIn: chunk)
          .get();
      allUsers.addAll(usersQuery.docs);
    }

    // 3. Chunked updates
    final int batchSize = 200;
    for (var i = 0; i < allUsers.length; i += batchSize) {
      final batch = _firestore.batch();
      final end = (i + batchSize < allUsers.length) ? i + batchSize : allUsers.length;
      final chunk = allUsers.sublist(i, end);

      for (var userDoc in chunk) {
        batch.update(userDoc.reference, {'roleId': 'role-owner', 'updatedAt': nowIso});
        
        final pointerRef = _firestore.collection('users').doc(userDoc.id);
        batch.set(pointerRef, {
          'businessId': businessId,
          'roleId': 'role-owner',
          'updatedAt': nowIso,
          'schemaVersion': 1,
        }, SetOptions(merge: true));
      }
      
      // Implicitly throws on failure, aborting migration cleanly.
      await batch.commit();
      debugPrint('[BSREPO][MIGRATION] Committed batch of ${chunk.length} users.');
    }

    // 4. Delete legacy roles
    final cleanupBatch = _firestore.batch();
    for (final legacyId in legacyRoleIds) {
      final legacyRoleRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('roles')
          .doc(legacyId);
      cleanupBatch.delete(legacyRoleRef);
    }
    await cleanupBatch.commit();
    debugPrint('[BSREPO][MIGRATION] Deleted legacy roles $legacyRoleIds.');

    return legacyRoleIds.contains(currentRoleId) ? 'role-owner' : currentRoleId;
  }
}


