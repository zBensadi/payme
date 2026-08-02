import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/screens/placeholder_home_screen.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/setup_password_screen.dart';
import '../features/auth/screens/recovery_key_display_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/fatal_auth_error_screen.dart';
import '../features/accounting_years/screens/accounting_years_screen.dart';
import '../features/clients/screens/client_list_screen.dart';
import '../features/clients/screens/client_form_screen.dart';
import '../features/clients/screens/deleted_clients_screen.dart';
import '../../domain/entities/client.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState == AuthState.initial || authState == AuthState.loading) {
        return '/splash';
      }

      final isGoingToAuth = state.uri.path == '/login' ||
          state.uri.path == '/setup' ||
          state.uri.path == '/forgot-password' ||
          state.uri.path == '/recovery-key-display' ||
          state.uri.path == '/fatal-error';

      if (authState == AuthState.setupRequired) {
        if (state.uri.path != '/setup' && state.uri.path != '/recovery-key-display') {
          return '/setup';
        }
      }

      if (authState == AuthState.unauthenticated) {
        if (!isGoingToAuth) {
          return '/login';
        }
      }

      if (authState == AuthState.fatalError) {
        if (state.uri.path != '/fatal-error') {
          return '/fatal-error';
        }
      }

      if (authState == AuthState.authenticated) {
        if (isGoingToAuth) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupPasswordScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/recovery-key-display',
        builder: (context, state) {
          final recoveryKey = state.extra as String? ?? 'ERROR_NO_KEY';
          return RecoveryKeyDisplayScreen(recoveryKey: recoveryKey);
        },
      ),
      GoRoute(
        path: '/fatal-error',
        builder: (context, state) => const FatalAuthErrorScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const PlaceholderHomeScreen(),
      ),
      GoRoute(
        path: '/accounting-years',
        builder: (context, state) => const AccountingYearsScreen(),
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) => const ClientListScreen(),
      ),
      GoRoute(
        path: '/clients/new',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/edit',
        builder: (context, state) {
          final client = state.extra as Client;
          return ClientFormScreen(client: client);
        },
      ),
      GoRoute(
        path: '/clients/deleted',
        builder: (context, state) => const DeletedClientsScreen(),
      ),
    ],
  );
});
