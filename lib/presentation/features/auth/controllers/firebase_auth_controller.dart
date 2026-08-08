import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/firebase_authentication_service.dart';
import '../../../../core/error/result.dart';
import '../../../../data/repositories_impl/firebase_authentication_repository.dart';

import 'current_user_controller.dart';

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
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (profile) {
        if (profile == null) {
          return FirebaseAuthState.unauthenticated;
        } else if (profile.requiresBootstrap) {
          return FirebaseAuthState.bootstrapping;
        } else {
          return FirebaseAuthState.authenticated;
        }
      },
      loading: () => FirebaseAuthState.loading,
      error: (_, __) => FirebaseAuthState.failure,
    );
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
