import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/sync/sync_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/current_app_user.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/user_role.dart';
import '../../../providers/repository_providers.dart';
import 'firebase_auth_controller.dart';
import 'context_resolution_controller.dart';

/// Resolves the Firebase-authenticated user to a [CurrentAppUser] using
/// ONLY the local SQLite database.
///
/// This provider NEVER queries Firestore. It is a pure authorization resolver:
///
///   Firebase UID  →  SQLite AppUser  →  SQLite UserRole  →  CurrentAppUser
///
/// Possible outcomes for each Firebase Auth event:
///
///   1. User not in SQLite → yield bootstrap sentinel (requiresBootstrap = true)
///      Routing: GoRouter sends to /firebase-bootstrap.
///      Resolution: BootstrapController provisions Firestore + seeds SQLite,
///      then invalidates this provider.
///
///   2. User in SQLite but roleId is null → fail closed (signOut).
///      This indicates a corrupted authorization state.
///
///   3. User in SQLite and role found → yield CurrentAppUser (authenticated).
///
///   4. User in SQLite, roleId set, but role not found in SQLite → fail closed.
///      This indicates a referential integrity failure — role was deleted locally
///      but user still references it.
///
/// SyncService reads businessId from this provider. Once step 3 is reached,
/// SyncService will have a valid businessId and can begin pulling all
/// remaining data from Firestore.
final currentUserProvider = StreamProvider<CurrentAppUser?>((ref) async* {

  final userRepository = ref.watch(internalUserRepositoryProvider);
  final roleRepository = ref.watch(internalRoleRepositoryProvider);

  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] StreamProvider build — initializing unified trigger');

  final triggerController = StreamController<AppUser?>();
  AppUser? lastKnownAuthUser;

  ref.listen<ContextResolutionData>(contextResolutionProvider, (previous, next) {
    if (next.state == ContextResolutionState.approved) {
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] context approved: uid=${next.user?.uid}');
      lastKnownAuthUser = next.user;
      triggerController.add(next.user);
    } else if (next.state == ContextResolutionState.unauthenticated) {
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] context unauthenticated');
      lastKnownAuthUser = null;
      triggerController.add(null);
    }
  }, fireImmediately: true);

  final userSub = userRepository.watchEvents().listen((event) {
    if (event.domain == SyncDomain.users) {
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] userRepository event — triggering refresh check');
      triggerController.add(lastKnownAuthUser);
    }
  });

  final roleSub = roleRepository.watchEvents().listen((event) {
    if (event.domain == SyncDomain.roles) {
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] roleRepository event — triggering refresh check');
      triggerController.add(lastKnownAuthUser);
    }
  });

  ref.onDispose(() {
    userSub.cancel();
    roleSub.cancel();
    triggerController.close();
  });

  CurrentAppUser? lastYielded;

  await for (final user in triggerController.stream) {
    if (user == null) {
      // No Firebase session → unauthenticated
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] user=null → yielding null (unauthenticated)');
      if (lastYielded != null) {
        lastYielded = null;
        yield null;
      } else if (!triggerController.isClosed) {
        yield null;
      }
      continue;
    }
    
    // Attempt to resolve the user from SQLite only.
    final userResult = await userRepository.getUserById(user.uid);

    if (userResult is! Success || (userResult as Success<AppUser?>).value == null) {
      // User is authenticated with Firebase but has no local SQLite record.
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] no SQLite record → yielding bootstrap sentinel for uid=${user.uid}');
      final sentinel = _bootstrapSentinel(uid: user.uid, email: user.email);
      lastYielded = sentinel;
      yield sentinel;
      continue;
    }

    final appUser = (userResult).value!;

    if (appUser.roleId == null) {
      // User record exists but roleId is missing — corrupted authorization state.
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] roleId=null → FAIL CLOSED: signing out');
      await fb.FirebaseAuth.instance.signOut();
      lastYielded = null;
      yield null;
      continue;
    }

    // Resolve the role from SQLite.
    final roleResult = await roleRepository.getRoleById(appUser.roleId!);

    if (roleResult is! Success || (roleResult as Success<UserRole?>).value == null) {
      // Role referenced by user does not exist locally — referential integrity failure.
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] role not found in SQLite → FAIL CLOSED: signing out');
      await fb.FirebaseAuth.instance.signOut();
      lastYielded = null;
      yield null;
      continue;
    }

    final userRole = (roleResult).value!;
    final nextUser = CurrentAppUser(user: appUser, role: userRole);

    // Only yield if there's a meaningful change (we use updatedAt as a reliable signal)
    if (lastYielded == null || 
        lastYielded.user.updatedAt != nextUser.user.updatedAt || 
        lastYielded.role.updatedAt != nextUser.role.updatedAt) {
      
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] resolved uid=${appUser.uid} businessId=${appUser.businessId} roleId=${userRole.id} → yielding updated CurrentAppUser');
      lastYielded = nextUser;
      yield nextUser;
    } else {
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] state unchanged for uid=${appUser.uid}, skipping rebuild');
    }
  }
  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] unified trigger stream closed — StreamProvider ending');
});

/// A sentinel [CurrentAppUser] that represents a Firebase-authenticated user
/// who has no local business association yet.
///
/// [AppUser.requiresBootstrap] returns true when [businessId] is null,
/// which causes [FirebaseAuthController] to emit [FirebaseAuthState.bootstrapping],
/// which causes [GoRouter] to redirect to /firebase-bootstrap.
CurrentAppUser _bootstrapSentinel({required String uid, required String email}) {
  final now = DateTime.now();
  return CurrentAppUser(
    user: AppUser(
      uid: uid,
      email: email,
      businessId: null, // null → requiresBootstrap == true
      roleId: null,
      isSuperAdmin: false,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    role: UserRole(
      id: '_bootstrap_sentinel',
      name: 'Bootstrap',
      isSystemRole: true,
      permissions: const [],
      priority: 999,
      createdAt: now,
      updatedAt: now,
    ),
  );
}
