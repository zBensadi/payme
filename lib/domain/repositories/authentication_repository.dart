import '../entities/app_user.dart';
import '../../core/error/result.dart';

abstract class AuthenticationRepository {
  /// Stream of authentication state changes.
  Stream<AppUser?> authStateChanges();

  /// The currently authenticated user, or null if unauthenticated.
  AppUser? get currentUser;

  /// Signs in a user with the provided email and password.
  Future<Result<void>> signIn(String email, String password);

  /// Signs out the current user.
  Future<Result<void>> signOut();

  /// Sends a password reset email to the provided email address.
  Future<Result<void>> resetPassword(String email);
}
