import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/setup_password_screen.dart';
import '../features/auth/screens/recovery_key_display_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/fatal_auth_error_screen.dart';

import '../features/dashboard/screens/dashboard_screen.dart';

import '../features/accounting_years/screens/accounting_years_screen.dart';

import '../features/clients/screens/client_list_screen.dart';
import '../features/clients/screens/client_form_screen.dart';
import '../features/clients/screens/deleted_clients_screen.dart';
import '../features/clients/screens/client_ledger_screen.dart';

import '../features/invoices/screens/invoice_form_screen.dart';
import '../features/invoices/screens/global_invoice_list_screen.dart';

import '../features/payments/screens/payment_list_screen.dart';
import '../features/payments/screens/payment_form_screen.dart';
import '../features/payments/screens/attachment_viewer_screen.dart';

import '../features/reports/screens/reports_home_screen.dart';
import '../features/reports/screens/outstanding_invoices_report_screen.dart';
import '../features/reports/screens/paid_invoices_report_screen.dart';
import '../features/reports/screens/client_balances_report_screen.dart';
import '../features/reports/screens/payments_by_period_report_screen.dart';
import '../features/reports/screens/invoices_by_period_report_screen.dart';

import '../features/settings/screens/settings_screen.dart';
import '../features/backup/screens/backup_restore_screen.dart';
import '../features/settings/screens/change_password_screen.dart';

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
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/accounting-years',
        builder: (context, state) => const AccountingYearsScreen(),
      ),
      GoRoute(
        path: '/attachment-viewer',
        builder: (context, state) {
          final filePath = state.extra as String;
          return AttachmentViewerScreen(filePath: filePath);
        },
      ),
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const GlobalInvoiceListScreen(),
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) => const ClientListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ClientFormScreen(),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final client = state.extra as Client;
              return ClientFormScreen(client: client);
            },
          ),
          GoRoute(
            path: 'deleted',
            builder: (context, state) => const DeletedClientsScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => ClientLedgerScreen(
              clientId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'invoices',
                builder: (context, state) => Scaffold(body: Center(child: Text('Invoices for client ${state.pathParameters['id']}'))), // Fallback if somehow accessed
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => InvoiceFormScreen(
                      clientId: state.pathParameters['id']!,
                      invoiceId: 'new',
                    ),
                  ),
                  GoRoute(
                    path: ':invoiceId',
                    builder: (context, state) => InvoiceFormScreen(
                      clientId: state.pathParameters['id']!,
                      invoiceId: state.pathParameters['invoiceId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'payments',
                        builder: (context, state) {
                          return PaymentListScreen(
                            clientId: state.pathParameters['id']!,
                            invoiceId: state.pathParameters['invoiceId']!,
                          );
                        },
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (context, state) => PaymentFormScreen(
                              clientId: state.pathParameters['id']!,
                              invoiceId: state.pathParameters['invoiceId']!,
                              paymentId: 'new',
                            ),
                          ),
                          GoRoute(
                            path: ':paymentId',
                            builder: (context, state) => PaymentFormScreen(
                              clientId: state.pathParameters['id']!,
                              invoiceId: state.pathParameters['invoiceId']!,
                              paymentId: state.pathParameters['paymentId']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsHomeScreen(),
        routes: [
          GoRoute(
            path: 'outstanding',
            builder: (context, state) => const OutstandingInvoicesReportScreen(),
          ),
          GoRoute(
            path: 'paid',
            builder: (context, state) => const PaidInvoicesReportScreen(),
          ),
          GoRoute(
            path: 'client-balances',
            builder: (context, state) => const ClientBalancesReportScreen(),
          ),
          GoRoute(
            path: 'payments',
            builder: (context, state) => const PaymentsByPeriodReportScreen(),
          ),
          GoRoute(
            path: 'invoices-by-period',
            builder: (context, state) => const InvoicesByPeriodReportScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/backup',
        builder: (context, state) => const BackupRestoreScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});
