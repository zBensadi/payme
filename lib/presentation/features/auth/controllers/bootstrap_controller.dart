import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../data/models/app_user_model.dart';
import '../../../../data/models/user_role_model.dart';
import '../../../../data/repositories_impl/firebase_bootstrap_repository.dart';
import '../../../../domain/repositories/bootstrap_repository.dart';
import '../../../providers/repository_providers.dart';
import 'current_user_controller.dart';
import 'context_resolution_controller.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final bootstrapRepositoryProvider = Provider<BootstrapRepository>((ref) {
  return FirebaseBootstrapRepository();
});

final bootstrapControllerProvider =
    NotifierProvider<BootstrapController, AsyncValue<void>>(
  BootstrapController.new,
);

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Orchestrates the one-time business provisioning flow.
///
/// ARCHITECTURAL EXCEPTION (documented in BootstrapRepository):
/// This is the ONLY workflow permitted to seed AppUser and UserRole directly
/// into SQLite outside of the SyncService. This is necessary because:
///   1. SyncService needs businessId from currentUserProvider.
///   2. currentUserProvider needs the user+role from SQLite.
///   3. SQLite is empty before bootstrap completes.
///
/// Responsibility: After Firestore provisioning succeeds, seed ONLY the
/// AppUser and UserRole into SQLite via their local data sources (bypassing
/// the SyncTrigger to avoid premature sync with a cold businessId).
/// Then invalidate currentUserProvider so it can resolve the identity from
/// the now-populated SQLite.
///
/// Failure model: If either the Firestore write OR the SQLite seed fails,
/// the operation is considered failed. The Firestore write is idempotent
/// (FirebaseBootstrapRepository checks for an existing document), so retry
/// is always safe.
class BootstrapController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Checks if the user already has a business (via the root users/{uid} pointer).
  /// If so, seeds SQLite and refreshes currentUserProvider to log them in.
  /// Returns true if a session was recovered, false if they are genuinely new.
  Future<Result<bool>> checkAndRecoverSession({
    required String uid,
    required String email,
  }) async {
    debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] ENTER checkAndRecoverSession uid=$uid email=$email');
    state = const AsyncValue.loading();
    debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] state set to AsyncValue.loading()');
    try {
      final bootstrapRepo = ref.read(bootstrapRepositoryProvider);
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] BEFORE checkExistingBusiness(uid=$uid)');
      final checkResult = await bootstrapRepo.checkExistingBusiness(uid: uid, email: email);
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] AFTER  checkExistingBusiness() → ${checkResult.runtimeType}');

      if (checkResult is Failure) {
        final failure = (checkResult as Failure).failure;
        debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] checkExistingBusiness returned Failure: ${failure.message}');
        state = AsyncValue.error(failure.message, StackTrace.current);
        return Failure(failure);
      }

      final bootstrapData = (checkResult as Success<BootstrapResult?>).value;
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] checkExistingBusiness returned Success — bootstrapData=${bootstrapData == null ? 'null (new user)' : 'BootstrapResult(uid=${bootstrapData.user.uid} businessId=${bootstrapData.user.businessId})'}');

      if (bootstrapData == null) {
        // No routing pointer found. This is a genuinely new user.
        debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] no pointer found → returning Success(false) [new user]');
        state = const AsyncValue.data(null);
        return const Success(false);
      }

      // Pointer found! Seed SQLite just like a normal bootstrap.
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] BEFORE _seedSQLite()');
      await _seedSQLite(bootstrapData);
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] AFTER  _seedSQLite() complete');

      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] BEFORE contextResolver.markBootstrapped()');
      final contextResolver = ref.read(contextResolutionProvider.notifier);
      await contextResolver.markBootstrapped(bootstrapData.user.businessId!);
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] AFTER  contextResolver.markBootstrapped()');

      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] BEFORE ref.invalidate(currentUserProvider)');
      ref.invalidate(currentUserProvider);
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] AFTER  ref.invalidate(currentUserProvider)');

      state = const AsyncValue.data(null);
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] returning Success(true) [session recovered]');
      return const Success(true);
    } catch (e, stack) {
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] EXCEPTION: $e\n$stack');
      state = AsyncValue.error(e, stack);
      return Failure(DatabaseFailure('Session recovery failed: $e'));
    }
  }

  Future<Result<void>> bootstrap({
    required String uid,
    required String email,
    required String? displayName,
    required String businessName,
  }) async {
    debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] ENTER bootstrap uid=$uid businessName=$businessName');
    state = const AsyncValue.loading();
    debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] state set to AsyncValue.loading()');

    try {
      // Step 1: Provision Firestore (idempotent)
      final bootstrapRepo = ref.read(bootstrapRepositoryProvider);
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] BEFORE bootstrapRepo.bootstrapBusiness()');
      final firestoreResult = await bootstrapRepo.bootstrapBusiness(
        uid: uid,
        email: email,
        displayName: displayName,
        businessName: businessName,
      );
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] AFTER  bootstrapRepo.bootstrapBusiness() → ${firestoreResult.runtimeType}');

      if (firestoreResult is Failure) {
        final failure = (firestoreResult as Failure).failure;
        debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] bootstrapBusiness returned Failure: ${failure.message}');
        state = AsyncValue.error(failure.message, StackTrace.current);
        return Failure(failure);
      }

      final bootstrapData = (firestoreResult as Success<BootstrapResult>).value;

      // Step 2: Seed SQLite — AppUser only
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] BEFORE _seedSQLite()');
      await _seedSQLite(bootstrapData);
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] AFTER  _seedSQLite()');

      // Step 3: Refresh currentUserProvider
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] BEFORE contextResolver.markBootstrapped()');
      final contextResolver = ref.read(contextResolutionProvider.notifier);
      await contextResolver.markBootstrapped(bootstrapData.user.businessId!);
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] AFTER  contextResolver.markBootstrapped()');

      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] BEFORE ref.invalidate(currentUserProvider)');
      ref.invalidate(currentUserProvider);
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] AFTER  ref.invalidate(currentUserProvider)');

      state = const AsyncValue.data(null);
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] BEFORE returning Success(null)');
      return const Success(null);
    } catch (e, stack) {
      debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] EXCEPTION in bootstrap: $e\n$stack');
      state = AsyncValue.error(e, stack);
      return Failure(DatabaseFailure('Bootstrap failed: $e'));
    }
  }

  Future<void> _seedSQLite(BootstrapResult bootstrapData) async {
    debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] ENTER _seedSQLite uid=${bootstrapData.user.uid} businessId=${bootstrapData.user.businessId}');
    debugPrint('[TRACE-businessId] BootstrapResult.businessId=${bootstrapData.user.businessId}');
    
    final userLocalDs = ref.read(userLocalDataSourceProvider);
    final roleLocalDs = ref.read(roleLocalDataSourceProvider);

    // Seed role FIRST to satisfy the foreign key constraint (user.roleId → roles.id)
    final roleModel = UserRoleModel.fromEntity(bootstrapData.role);
    final roleSeedMap = roleModel.toMap();
    roleSeedMap['is_dirty'] = 0;
    roleSeedMap['synced_at'] = bootstrapData.role.updatedAt.toUtc().toIso8601String();
    debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] BEFORE roleLocalDs.overwriteRole(${bootstrapData.role.id})');
    await roleLocalDs.overwriteRole(UserRoleModel.fromMap(roleSeedMap));
    debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] AFTER  roleLocalDs.overwriteRole() complete');

    // Seed user SECOND
    final userModel = AppUserModel.fromEntity(bootstrapData.user);
    debugPrint('[TRACE-businessId] AppUserModel.businessId=${userModel.businessId}');
    
    final userSeedMap = userModel.toMap();
    userSeedMap['is_dirty'] = 0;
    userSeedMap['synced_at'] = bootstrapData.user.updatedAt.toUtc().toIso8601String();
    debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] BEFORE userLocalDs.overwriteUser(${bootstrapData.user.uid})');
    await userLocalDs.overwriteUser(AppUserModel.fromMap(userSeedMap));
    debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] AFTER  userLocalDs.overwriteUser() complete');
    debugPrint('[BSCTRL][${DateTime.now().toIso8601String()}] EXIT _seedSQLite');
  }
}
