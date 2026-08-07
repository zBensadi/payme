import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/firebase_authentication_service.dart';
import '../../../../core/error/result.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import '../../../../data/repositories_impl/firebase_authentication_repository.dart';

// Abstract Auth State for UI
enum FirebaseAuthState {
  loading,
  authenticated,
  unauthenticated,
  failure,
  bootstrapping,
}

// Providers
final firebaseAuthRepositoryProvider = Provider((ref) {
  return FirebaseAuthenticationRepository();
});

final firebaseAuthServiceProvider = Provider((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return FirebaseAuthenticationService(repo);
});

class FirebaseAuthController extends Notifier<FirebaseAuthState> {
  @override
  FirebaseAuthState build() {
    // Listen to Firebase auth state changes
    final authService = ref.watch(firebaseAuthServiceProvider);
    
    // We don't want to use ref.listen directly in build for async streams without careful handling,
    // so we'll just listen to the stream manually.
    authService.authStateChanges().listen((user) {
      if (user == null) {
        state = FirebaseAuthState.unauthenticated;
      } else if (user.requiresBootstrap) {
        state = FirebaseAuthState.bootstrapping;
      } else {
        state = FirebaseAuthState.authenticated;
      }
    });

    return FirebaseAuthState.loading;
  }

  Future<Result<void>> login(String email, String password) async {
    final authService = ref.read(firebaseAuthServiceProvider);
    return await authService.signIn(email, password);
  }

  Future<Result<void>> logout() async {
    final authService = ref.read(firebaseAuthServiceProvider);
    return await authService.signOut();
  }

  Future<Result<void>> resetPassword(String email) async {
    final authService = ref.read(firebaseAuthServiceProvider);
    return await authService.resetPassword(email);
  }
}

final firebaseAuthControllerProvider = NotifierProvider<FirebaseAuthController, FirebaseAuthState>(
  FirebaseAuthController.new,
);
