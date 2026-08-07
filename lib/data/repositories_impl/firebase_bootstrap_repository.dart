import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/bootstrap_repository.dart';

class FirebaseBootstrapRepository implements BootstrapRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  FirebaseBootstrapRepository({FirebaseFirestore? firestore, Uuid? uuid})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<AppUser>> bootstrapBusiness({
    required String uid,
    required String email,
    required String? displayName,
    required String businessName,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);

      // 1. Perform a standard read first. 
      // Windows Desktop C++ SDK frequently fails on transaction.get() due to gRPC stream bugs.
      final userSnapshot = await userRef.get();

      // Idempotency check: if user already exists, just return it
      if (userSnapshot.exists) {
        final data = userSnapshot.data()!;
        return Success(AppUser(
          uid: data['uid'],
          email: data['email'],
          displayName: data['displayName'],
          businessId: data['businessId'],
          roleId: data['roleId'],
          isSuperAdmin: data['isSuperAdmin'] ?? false,
          isActive: data['isActive'] ?? true,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        ));
      }

      // Generate IDs
      final businessId = _uuid.v4();
      final roleId = _uuid.v4();
      final now = FieldValue.serverTimestamp();

      // Start a batch instead of a transaction to maintain atomicity
      final batch = _firestore.batch();

      // 1. Business document
      final businessRef = _firestore.collection('businesses').doc(businessId);
      batch.set(businessRef, {
        'businessId': businessId,
        'name': businessName,
        'createdAt': now,
        'createdBy': uid,
        'isActive': true,
      });

      // 2. Default Super Admin role
      final roleRef = _firestore.collection('roles').doc(roleId);
      batch.set(roleRef, {
        'businessId': businessId,
        'name': 'Super Admin',
        'isSystemRole': true,
        'defaultPermissions': {},
        'createdAt': now,
        'createdBy': uid,
        'updatedAt': now,
        'updatedBy': uid,
      });

      // 3. User profile
      final effectiveDisplayName = displayName ?? email.split('@').first;
      batch.set(userRef, {
        'uid': uid,
        'email': email,
        'displayName': effectiveDisplayName,
        'businessId': businessId,
        'roleId': roleId,
        'isSuperAdmin': true,
        'isActive': true,
        'createdAt': now,
        'createdBy': uid,
        'updatedAt': now,
        'updatedBy': uid,
      });

      // 4. Business Settings
      final settingsRef = _firestore.collection('business_settings').doc(businessId);
      batch.set(settingsRef, {
        'businessId': businessId,
        'currencyCode': 'DZD',
        'appMode': 'cloud',
        'firestoreSchemaVersion': 1,
        'createdAt': now,
        'createdBy': uid,
        'updatedAt': now,
        'updatedBy': uid,
      });

      // 5. Initial Activity Log entries
      final logs = [
        {'action': 'created', 'entityType': 'business', 'entityId': businessId, 'entitySummary': businessName},
        {'action': 'created', 'entityType': 'role', 'entityId': roleId, 'entitySummary': 'Super Admin'},
        {'action': 'completed', 'entityType': 'bootstrap', 'entityId': businessId, 'entitySummary': 'Business Bootstrap'},
      ];

      for (final log in logs) {
        final logRef = _firestore.collection('activity_logs').doc();
        batch.set(logRef, {
          'businessId': businessId,
          'userId': uid,
          'userDisplayName': effectiveDisplayName,
          'action': log['action'],
          'entityType': log['entityType'],
          'entityId': log['entityId'],
          'entitySummary': log['entitySummary'],
          'timestamp': now,
        });
      }

      // Commit the batch atomically
      await batch.commit();

      final appUser = AppUser(
        uid: uid,
        email: email,
        displayName: effectiveDisplayName,
        businessId: businessId,
        roleId: roleId,
        isSuperAdmin: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Success(appUser);
      
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException during bootstrap: $e\n$stack');
      return Failure(DatabaseFailure('Firebase error: ${e.code} - ${e.message}'));
    } catch (e, stack) {
      debugPrint('Unexpected error during bootstrap: $e\n$stack');
      return Failure(DatabaseFailure('Unexpected error: $e'));
    }
  }
}
