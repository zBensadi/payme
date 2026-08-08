import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/business_context.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/user_profile_repository.dart';

class FirebaseUserProfileRepository implements UserProfileRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<UserProfile?>> getUserProfile({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        // User profile doesn't exist yet, return minimal UserProfile indicating bootstrap required
        final appUser = AppUser(
          uid: uid,
          email: email,
          displayName: displayName,
          businessId: null,
          roleId: null,
          isSuperAdmin: false,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        return Success(UserProfile(user: appUser));
      }

      final userData = userDoc.data()!;
      final appUser = AppUser(
        uid: userData['uid'],
        email: userData['email'],
        displayName: userData['displayName'],
        businessId: userData['businessId'],
        roleId: userData['roleId'],
        isSuperAdmin: userData['isSuperAdmin'] ?? false,
        isActive: userData['isActive'] ?? true,
        createdAt: (userData['createdAt'] as Timestamp).toDate(),
        updatedAt: (userData['updatedAt'] as Timestamp).toDate(),
      );

      BusinessContext? businessContext;
      UserRole? userRole;

      if (appUser.businessId != null) {
        final businessDoc = await _firestore.collection('businesses').doc(appUser.businessId).get();
        if (businessDoc.exists) {
          final businessData = businessDoc.data()!;
          businessContext = BusinessContext(
            businessId: businessData['businessId'] ?? appUser.businessId!,
            name: businessData['name'],
          );
        }
      }

      if (appUser.roleId != null) {
        final roleDoc = await _firestore.collection('roles').doc(appUser.roleId).get();
        if (roleDoc.exists) {
          final roleData = roleDoc.data()!;
          userRole = UserRole(
            roleId: appUser.roleId!,
            name: roleData['name'],
            isSystemRole: roleData['isSystemRole'] ?? false,
            defaultPermissions: roleData['defaultPermissions'] ?? <String, dynamic>{},
          );
        }
      }

      return Success(UserProfile(
        user: appUser,
        businessContext: businessContext,
        role: userRole,
      ));
    } on FirebaseException catch (e) {
      debugPrint('FirebaseException fetching user profile: $e');
      return Failure(DatabaseFailure('Firebase error: ${e.code} - ${e.message}'));
    } catch (e) {
      debugPrint('Unexpected error fetching user profile: $e');
      return Failure(DatabaseFailure('Unexpected error: $e'));
    }
  }
}
