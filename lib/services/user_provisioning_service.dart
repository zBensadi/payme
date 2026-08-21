import 'dart:convert';
import 'package:http/http.dart' as http;
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
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User is not authenticated.');
      }

      final response = await http.post(
        Uri.parse('https://us-central1-payme-dev-967bb.cloudfunctions.net/provisionUser'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'email': user.email,
            'password': password,
            'displayName': user.displayName,
            'roleId': user.roleId,
            'isActive': user.isActive,
          }
        }),
      );

      final resultBody = jsonDecode(response.body);

      if (response.statusCode != 200) {
        final error = resultBody['error'] ?? {};
        final status = error['status'] ?? 'UNKNOWN';
        final message = error['message'] ?? response.body;

        if (status == 'ALREADY_EXISTS') {
          return const Failure(AuthFailure('Email already in use.'));
        } else if (status == 'PERMISSION_DENIED') {
          return Failure(AuthFailure(message));
        } else if (status == 'INVALID_ARGUMENT') {
          return Failure(AuthFailure(message));
        }
        return Failure(AuthFailure('Server Error: $message'));
      }
      
      final data = resultBody['result'] ?? resultBody['data'];
      final targetUid = data['uid'] as String;
      
      final finalUser = user.copyWith(
        uid: targetUid, 
        isDirty: false,
        updatedAt: DateTime.now().toUtc(),
      );

      // Local SQLite creation
      try {
        final localModel = AppUserModel.fromEntity(finalUser);
        await _localDataSource.create(localModel);
        
        // Trigger Sync integration
        _syncTrigger.requestSync(SyncDomain.users);
      } catch (e) {
        // SQLite write failed. Remote provisioning already succeeded.
        // Return a clear recoverable state (sync will pull the remote record).
        debugPrint('[PROVISIONING] Local SQLite write failed, but remote succeeded. Error: $e');
        _syncTrigger.requestSync(SyncDomain.users);
        return const Failure(DatabaseFailure('Remote provisioning succeeded, but local save failed. The user will be synchronized shortly.'));
      }

      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure('Unexpected provisioning error (REST fallback): $e'));
    }
  }

  Future<Result<void>> reactivateUser(String uid) async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User is not authenticated.');
      }

      final response = await http.post(
        Uri.parse('https://us-central1-payme-dev-967bb.cloudfunctions.net/reactivateUser'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'uid': uid,
          }
        }),
      );

      final resultBody = jsonDecode(response.body);

      if (response.statusCode != 200) {
        final error = resultBody['error'] ?? {};
        final status = error['status'] ?? 'UNKNOWN';
        final message = error['message'] ?? response.body;

        if (status == 'PERMISSION_DENIED') {
          return Failure(AuthFailure(message));
        } else if (status == 'INVALID_ARGUMENT') {
          return Failure(AuthFailure(message));
        }
        return Failure(AuthFailure('Server Error: $message'));
      }
      
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure('Unexpected reactivation error (REST fallback): $e'));
    }
  }
}
