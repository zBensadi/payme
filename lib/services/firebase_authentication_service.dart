import '../core/error/result.dart';
import '../core/error/failures.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/authentication_repository.dart';

class FirebaseAuthenticationService {
  final AuthenticationRepository _repository;

  FirebaseAuthenticationService(this._repository);

  Stream<AppUser?> authStateChanges() {
    return _repository.authStateChanges();
  }

  AppUser? get currentUser {
    return _repository.currentUser;
  }

  Future<Result<void>> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return Failure(AuthFailure(email.isEmpty ? 'emailRequired' : 'passwordRequired'));
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return const Failure(AuthFailure('invalidEmailFormat'));
    }
    return _repository.signIn(email, password);
  }

  Future<Result<void>> signOut() async {
    return _repository.signOut();
  }

  Future<Result<void>> resetPassword(String email) async {
    if (email.isEmpty) {
      return const Failure(AuthFailure('emailRequired'));
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return const Failure(AuthFailure('invalidEmailFormat'));
    }
    return _repository.resetPassword(email);
  }
}
