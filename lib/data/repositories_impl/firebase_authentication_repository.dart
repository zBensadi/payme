import 'package:firebase_auth/firebase_auth.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/authentication_repository.dart';

class FirebaseAuthenticationRepository implements AuthenticationRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthenticationRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_userFromFirebase);
  }

  @override
  AppUser? get currentUser {
    // Synchronous currentUser cannot fetch Firestore document, so it just returns the base AppUser without businessId
    return _userFromFirebase(_firebaseAuth.currentUser);
  }

  @override
  Future<Result<void>> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      String key = 'firebaseAuthInvalidCredentials';
      if (e.code == 'user-not-found') {
        key = 'firebaseAuthUserNotFound';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        key = 'firebaseAuthInvalidCredentials';
      } else if (e.code == 'invalid-email') {
        key = 'invalidEmailFormat';
      }
      return Failure(AuthFailure(key));
    } catch (e) {
      return Failure(AuthFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure('Failed to sign out'));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      String key = 'passwordResetFailed';
      if (e.code == 'user-not-found') {
        key = 'firebaseAuthUserNotFound';
      } else if (e.code == 'invalid-email') {
        key = 'invalidEmailFormat';
      }
      return Failure(AuthFailure(key));
    } catch (e) {
      return Failure(AuthFailure('An unexpected error occurred'));
    }
  }

  AppUser? _userFromFirebase(User? user) {
    if (user == null) {
      return null;
    }
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      businessId: null, // Not loaded in Phase 17
      roleId: null, // Not loaded in Phase 17
      isSuperAdmin: false, // Not loaded in Phase 17
      isActive: true, // Defaulting to true for now
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: user.metadata.lastSignInTime ?? DateTime.now(),
    );
  }
}
