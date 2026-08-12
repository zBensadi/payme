import '../entities/app_user.dart';
import '../entities/user_role.dart';
import '../../core/error/result.dart';

/// Result of a bootstrap operation.
/// Contains both the AppUser and the UserRole created in Firestore,
/// so the caller can seed them into SQLite without a round-trip.
class BootstrapResult {
  final AppUser user;
  final UserRole role;

  const BootstrapResult({required this.user, required this.role});
}

abstract class BootstrapRepository {
  /// Checks if the routing pointer `users/{uid}` exists.
  /// If it exists, fetches the user and role from their canonical business subcollections
  /// and returns them so they can be seeded into SQLite.
  /// Returns null if the pointer does not exist (genuine new user).
  Future<Result<BootstrapResult?>> checkExistingBusiness({
    required String uid,
    required String email,
  });

  /// Creates the business, the owner role, and the owner user in Firestore.
  ///
  /// ARCHITECTURAL NOTE:
  /// Bootstrap is the ONLY workflow permitted to write AppUser and UserRole
  /// directly to both Firestore and SQLite. This is a deliberate exception to
  /// the synchronization architecture. Bootstrap is a provisioning operation
  /// (not a sync operation): SQLite must contain the user and role before
  /// SyncService can start, and SyncService needs businessId from
  /// currentUserProvider, which in turn needs SQLite data. Writing directly
  /// to SQLite here breaks the circular dependency.
  /// 
  /// ARCHITECTURAL INVARIANT 2:
  /// The root `users/{uid}` collection is an authentication routing layer, not 
  /// a domain model. The canonical user data always lives under 
  /// `businesses/{businessId}/users/{uid}`.
  ///
  /// After this call succeeds, the caller (BootstrapController) is responsible
  /// for seeding ONLY [BootstrapResult.user] and [BootstrapResult.role] into
  /// SQLite. No other entities may be seeded. Everything else is SyncService's
  /// responsibility.
  Future<Result<BootstrapResult>> bootstrapBusiness({
    required String uid,
    required String email,
    required String? displayName,
    required String businessName,
  });
}
