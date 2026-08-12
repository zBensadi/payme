import 'package:flutter/foundation.dart';
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
    debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][FirebaseAuthController] build() called — watching currentUserProvider');
    final currentUserAsync = ref.watch(currentUserProvider);

    final result = currentUserAsync.when(
      data: (currentAppUser) {
        if (currentAppUser == null) {
          debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][FirebaseAuthController] currentUserProvider=data(null) → unauthenticated');
          return FirebaseAuthState.unauthenticated;
        } else if (currentAppUser.user.requiresBootstrap) {
          debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][FirebaseAuthController] currentUserProvider=data(sentinel uid=${currentAppUser.user.uid}) → bootstrapping');
          return FirebaseAuthState.bootstrapping;
        } else {
          debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][FirebaseAuthController] currentUserProvider=data(uid=${currentAppUser.user.uid} businessId=${currentAppUser.user.businessId}) → authenticated');
          return FirebaseAuthState.authenticated;
        }
      },
      loading: () {
        debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][FirebaseAuthController] currentUserProvider=loading → loading');
        return FirebaseAuthState.loading;
      },
      error: (e, s) {
        debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][FirebaseAuthController] currentUserProvider=error: $e → failure');
        return FirebaseAuthState.failure;
      },
    );
    debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][FirebaseAuthController] build() returning $result');
    return result;
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
