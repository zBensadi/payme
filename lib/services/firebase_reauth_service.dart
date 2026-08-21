import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/error/failures.dart';
import '../core/error/result.dart';

final firebaseReauthServiceProvider = Provider<FirebaseReauthService>((ref) {
  return FirebaseReauthService(FirebaseAuth.instance);
});

class FirebaseReauthService {
  final FirebaseAuth _firebaseAuth;

  FirebaseReauthService(this._firebaseAuth);

  Future<Result<void>> reauthenticate(String password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      return const Failure(AuthFailure('Authentication failed. Please log in again.'));
    }
    
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return const Failure(AuthFailure('Incorrect password.'));
        case 'too-many-requests':
          return const Failure(AuthFailure('Too many attempts. Please try again later.'));
        case 'user-disabled':
          return const Failure(AuthFailure('This account has been disabled.'));
        case 'requires-recent-login':
          return const Failure(AuthFailure('Please log out and log back in to perform this action.'));
        case 'network-request-failed':
          return const Failure(AuthFailure('Network error. Please check your connection.'));
        default:
          return Failure(AuthFailure('Authentication failed: ${e.message}'));
      }
    } catch (e) {
      return const Failure(AuthFailure('An unexpected error occurred.'));
    }
  }
}
