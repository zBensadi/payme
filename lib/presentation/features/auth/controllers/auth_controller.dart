import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/auth_service.dart';

enum AuthState {
  initial,
  loading,
  setupRequired,
  unauthenticated,
  authenticated,
  fatalError,
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // We do an async init, but return initial state synchronously
    Future.microtask(() => _init());
    return AuthState.initial;
  }

  Future<void> _init() async {
    state = AuthState.loading;
    final authService = ref.read(authServiceProvider);
    final status = await authService.checkStatus();
    switch (status) {
      case AuthStatus.setupRequired:
        state = AuthState.setupRequired;
        break;
      case AuthStatus.loginRequired:
        state = AuthState.unauthenticated;
        break;
      case AuthStatus.fatalError:
        state = AuthState.fatalError;
        break;
    }
  }

  /// Called upon successful password verification.
  void markAsAuthenticated() {
    state = AuthState.authenticated;
  }

  /// Locks the application.
  void logout() {
    state = AuthState.unauthenticated;
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
