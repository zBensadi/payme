import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../core/error/failures.dart';
import '../core/error/result.dart';
import '../domain/entities/app_user.dart';
import '../data/datasources/local/user_local_datasource.dart';
import '../data/models/app_user_model.dart';
import '../core/sync/sync_trigger.dart';
import '../core/sync/sync_domain.dart';
import '../presentation/providers/repository_providers.dart';
import '../presentation/providers/sync_trigger_provider.dart';

final userProvisioningServiceProvider = Provider<UserProvisioningService>((ref) {
  return UserProvisioningService(
    ref.watch(userLocalDataSourceProvider),
    ref.watch(syncTriggerProvider),
  );
});

class UserProvisioningService {
  final UserLocalDataSource _localDataSource;
  final SyncTrigger _syncTrigger;

  UserProvisioningService(this._localDataSource, this._syncTrigger);

  Future<Result<void>> provisionUser(AppUser user, String password) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'provisioning_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: user.email, 
        password: password,
      );
      
      if (cred.user == null) {
        return const Failure(AuthFailure('Failed to create Firebase Auth user.'));
      }
      
      final uid = cred.user!.uid;
      final finalUser = user.copyWith(
        uid: uid, 
        isDirty: false,
        updatedAt: DateTime.now().toUtc(),
      );

      final batch = FirebaseFirestore.instance.batch();
      
      // 1. Auth Routing Pointer
      final pointerRef = FirebaseFirestore.instance.collection('users').doc(uid);
      batch.set(pointerRef, {
        'businessId': finalUser.businessId,
        'roleId': finalUser.roleId,
        'updatedAt': finalUser.updatedAt.toIso8601String(),
        'schemaVersion': 1,
      });

      // 2. Canonical Business User
      final userRef = FirebaseFirestore.instance
          .collection('businesses')
          .doc(finalUser.businessId)
          .collection('users')
          .doc(uid);
      final model = AppUserModel.fromEntity(finalUser);
      final map = model.toFirestore();
      map.removeWhere((key, value) => value == null);
      batch.set(userRef, map);

      try {
        await batch.commit();
      } catch (e) {
        // Recoverable state: Delete the orphaned Auth account
        try {
          await cred.user!.delete();
          debugPrint('[PROVISIONING] Orphaned Auth account deleted successfully.');
        } catch (deleteError) {
          debugPrint('[PROVISIONING] Failed to delete orphaned Auth account: $deleteError');
        }
        return Failure(AuthFailure('Failed to provision remote records: $e'));
      }

      // 3. Local SQLite creation
      try {
        final localModel = AppUserModel.fromEntity(finalUser);
        await _localDataSource.create(localModel);
        
        // 4. Trigger Sync integration
        _syncTrigger.requestSync(SyncDomain.users);
      } catch (e) {
        // SQLite write failed. Remote provisioning already succeeded.
        // Return a clear recoverable state (sync will pull the remote record).
        debugPrint('[PROVISIONING] Local SQLite write failed, but remote succeeded. Error: $e');
        _syncTrigger.requestSync(SyncDomain.users);
        return const Failure(DatabaseFailure('Remote provisioning succeeded, but local save failed. The user will be synchronized shortly.'));
      }

      return const Success(null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return const Failure(AuthFailure('Email already in use.'));
      } else if (e.code == 'invalid-email') {
        return const Failure(AuthFailure('Invalid email address.'));
      } else if (e.code == 'weak-password') {
        return const Failure(AuthFailure('Weak password.'));
      } else if (e.code == 'network-request-failed') {
        return const Failure(AuthFailure('Network error. Please check your connection.'));
      }
      return Failure(AuthFailure('Auth Error: ${e.message}'));
    } catch (e) {
      return Failure(AuthFailure('Unexpected provisioning error: $e'));
    } finally {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
    }
  }
}
