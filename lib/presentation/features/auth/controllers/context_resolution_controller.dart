import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/error/result.dart';
import 'bootstrap_controller.dart';
import 'firebase_auth_controller.dart';

import '../../../../domain/entities/app_user.dart';

enum ContextResolutionState {
  resolving,
  approved,
  contextSwitchPending, // Waiting for user input on dirty data
  bootstrapping,        // Fresh DB, waiting for Firebase provisioning
  failure,              // Error resolving context
  unauthenticated,
}

class ContextResolutionData {
  final ContextResolutionState state;
  final AppUser? user;
  final int dirtyCount;

  ContextResolutionData({
    required this.state,
    this.user,
    this.dirtyCount = 0,
  });
}

final contextResolutionProvider = NotifierProvider<ContextResolutionController, ContextResolutionData>(
  ContextResolutionController.new,
);

class ContextResolutionController extends Notifier<ContextResolutionData> {
  @override
  ContextResolutionData build() {
    debugPrint('[CONTEXT] build() - listening to authStateChanges');
    
    // Listen to Firebase Auth state
    final authService = ref.watch(firebaseAuthServiceProvider);
    
    ref.listen<AppUser?>(
      firebaseAuthServiceProvider.select((service) => service.currentUser), 
      (previous, next) {
        if (next == null) {
          state = ContextResolutionData(state: ContextResolutionState.unauthenticated);
        } else if (previous?.uid != next.uid) {
          _resolveContext(next);
        }
      },
      fireImmediately: true,
    );
    
    // Also explicitly listen to the stream since currentUser is sync but might not update dynamically without the stream
    authService.authStateChanges().listen((user) {
       if (user == null) {
          state = ContextResolutionData(state: ContextResolutionState.unauthenticated);
       } else if (state.user?.uid != user.uid) {
          _resolveContext(user);
       }
    });

    return ContextResolutionData(state: ContextResolutionState.resolving);
  }

  Future<void> _resolveContext(AppUser appUser) async {
    debugPrint('[CONTEXT] Resolving context for ${appUser.uid}');
    state = ContextResolutionData(state: ContextResolutionState.resolving, user: appUser);

    try {
      // 1. Get authoritative businessId
      String? authBusinessId;
      
      // Force token refresh to ensure custom claims are up to date
      authBusinessId = await fetchAuthBusinessId(appUser.uid);

      if (authBusinessId == null) {
        debugPrint('[CONTEXT] No custom claim found, checking bootstrap repository...');
        final bootstrapRepo = ref.read(bootstrapRepositoryProvider);
        final checkResult = await bootstrapRepo.checkExistingBusiness(uid: appUser.uid, email: appUser.email);
        if (checkResult is Success) {
          final val = (checkResult as Success).value;
          if (val != null) {
            authBusinessId = val.user.businessId;
          }
        }
      }

      // 2. Get local DB context marker
      final dbService = ref.read(databaseProvider);
      final localMeta = await dbService.getAppMeta();
      final localBusinessId = localMeta?.currentBusinessId;
      final localUid = localMeta?.currentUid;

      final hasDomainData = await dbService.hasAnyDomainData();

      debugPrint('[CONTEXT] Auth BusinessId: $authBusinessId, Local BusinessId: $localBusinessId, Local UID: $localUid, HasData: $hasDomainData');

      if (authBusinessId == null) {
        if (localBusinessId == null && !hasDomainData) {
          debugPrint('[CONTEXT] Case A: Fresh DB + New User -> Bootstrapping state');
          // Update current_uid so we know who is bootstrapping, but do NOT set businessId
          await dbService.updateAppMeta(businessId: null, uid: appUser.uid);
          state = ContextResolutionData(state: ContextResolutionState.bootstrapping, user: appUser);
          return;
        } else {
          debugPrint('[CONTEXT] Case C: Stale DB + New User -> ContextSwitchPending');
          final dirtyCount = await dbService.getTotalDirtyCount();
          state = ContextResolutionData(
            state: ContextResolutionState.contextSwitchPending,
            user: appUser,
            dirtyCount: dirtyCount,
          );
          return;
        }
      }

      if (localBusinessId == null && !hasDomainData) {
        debugPrint('[CONTEXT] Case B: Fresh DB + Existing Business User -> Approving context');
        await dbService.updateAppMeta(businessId: authBusinessId, uid: appUser.uid);
        state = ContextResolutionData(state: ContextResolutionState.approved, user: appUser);
        return;
      }

      if (localBusinessId == authBusinessId) {
        if (localUid != appUser.uid) {
          debugPrint('[CONTEXT] Case E: Same Business, Different User -> Clearing admin_credential.');
          await dbService.db.delete('admin_credential');
          await dbService.updateAppMeta(businessId: authBusinessId, uid: appUser.uid);
        } else {
          debugPrint('[CONTEXT] Case E: Same Business, Same User -> Approving context');
        }
        state = ContextResolutionData(state: ContextResolutionState.approved, user: appUser);
        return;
      }

      debugPrint('[CONTEXT] Case D: Existing DB + Different Business -> Initiating context switch logic.');
      final dirtyCount = await dbService.getTotalDirtyCount();
      state = ContextResolutionData(
        state: ContextResolutionState.contextSwitchPending,
        user: appUser,
        dirtyCount: dirtyCount,
      );

    } catch (e) {
      debugPrint('[CONTEXT] Error resolving context: $e');
      state = ContextResolutionData(state: ContextResolutionState.failure, user: appUser);
    }
  }

  Future<void> markBootstrapped(String businessId) async {
    final currentUser = state.user;
    if (currentUser != null && state.state == ContextResolutionState.bootstrapping) {
      debugPrint('[CONTEXT] Finalizing bootstrap -> Updating app_meta and approving context.');
      final dbService = ref.read(databaseProvider);
      await dbService.updateAppMeta(businessId: businessId, uid: currentUser.uid);
      state = ContextResolutionData(state: ContextResolutionState.approved, user: currentUser);
    }
  }

  @visibleForTesting
  Future<String?> fetchAuthBusinessId(String uid) async {
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser != null && fbUser.uid == uid) {
      final idTokenResult = await fbUser.getIdTokenResult(true);
      return idTokenResult.claims?['businessId'] as String?;
    }
    return null;
  }
}
