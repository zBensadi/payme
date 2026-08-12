import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/current_app_user.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/user_role.dart';
import '../../../providers/repository_providers.dart';
import 'firebase_auth_controller.dart';

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
  final authService = ref.watch(firebaseAuthServiceProvider);
  final userRepository = ref.watch(internalUserRepositoryProvider);
  final roleRepository = ref.watch(internalRoleRepositoryProvider);

  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] StreamProvider build — starting authStateChanges() listen loop');

  await for (final user in authService.authStateChanges()) {
    debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] authStateChanges() emitted: uid=${user?.uid} email=${user?.email}');

    if (user == null) {
      // No Firebase session → unauthenticated
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] user=null → yielding null (unauthenticated)');
      yield null;
    } else {
      // Attempt to resolve the user from SQLite only.
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] BEFORE userRepository.getUserById(${user.uid})');
      final userResult = await userRepository.getUserById(user.uid);
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] AFTER  userRepository.getUserById() → ${userResult.runtimeType} value=${userResult is Success ? (userResult as Success).value : (userResult as Failure).failure.message}');

      if (userResult is! Success || (userResult as Success<AppUser?>).value == null) {
        // User is authenticated with Firebase but has no local SQLite record.
        debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] no SQLite record → yielding bootstrap sentinel for uid=${user.uid}');
        yield _bootstrapSentinel(uid: user.uid, email: user.email);
        continue;
      }

      final appUser = (userResult as Success<AppUser?>).value!;

      if (appUser.roleId == null) {
        // User record exists but roleId is missing — corrupted authorization state.
        debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] roleId=null → FAIL CLOSED: signing out');
        await fb.FirebaseAuth.instance.signOut();
        yield null;
        continue;
      }

      // Resolve the role from SQLite.
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] BEFORE roleRepository.getRoleById(${appUser.roleId})');
      final roleResult = await roleRepository.getRoleById(appUser.roleId!);
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] AFTER  roleRepository.getRoleById() → ${roleResult.runtimeType} value=${roleResult is Success ? (roleResult as Success).value : (roleResult as Failure).failure.message}');

      if (roleResult is! Success || (roleResult as Success<UserRole?>).value == null) {
        // Role referenced by user does not exist locally — referential integrity failure.
        debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] role not found in SQLite → FAIL CLOSED: signing out');
        await fb.FirebaseAuth.instance.signOut();
        yield null;
        continue;
      }

      final userRole = (roleResult as Success<UserRole?>).value!;
      debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] resolved uid=${appUser.uid} businessId=${appUser.businessId} roleId=${userRole.id} → yielding CurrentAppUser (authenticated)');
      yield CurrentAppUser(user: appUser, role: userRole);
    }
  }
  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][currentUserProvider] authStateChanges() stream closed — StreamProvider ending');
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
