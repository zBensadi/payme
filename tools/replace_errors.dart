import 'dart:io';

void main() {
  final files = [
    'lib/presentation/features/settings/screens/settings_screen.dart',
    'lib/presentation/features/reports/screens/payments_by_period_report_screen.dart',
    'lib/presentation/features/reports/screens/paid_invoices_report_screen.dart',
    'lib/presentation/features/reports/screens/outstanding_invoices_report_screen.dart',
    'lib/presentation/features/reports/screens/invoices_by_period_report_screen.dart',
    'lib/presentation/features/reports/screens/client_balances_report_screen.dart',
    'lib/presentation/features/payments/screens/payment_form_screen.dart',
    'lib/presentation/features/payments/screens/payment_list_screen.dart',
    'lib/presentation/features/invoices/screens/invoice_form_screen.dart',
    'lib/presentation/features/invoices/screens/global_invoice_list_screen.dart',
    'lib/presentation/features/dashboard/screens/dashboard_screen.dart',
    'lib/presentation/features/clients/screens/deleted_clients_screen.dart',
    'lib/presentation/features/clients/screens/client_ledger_screen.dart',
    'lib/presentation/features/clients/screens/client_form_screen.dart',
    'lib/presentation/features/clients/screens/client_list_screen.dart',
    'lib/presentation/features/backup/screens/backup_restore_screen.dart',
    'lib/presentation/features/settings/screens/change_password_screen.dart',
    'lib/presentation/features/auth/screens/setup_password_screen.dart',
    'lib/presentation/features/auth/screens/forgot_password_screen.dart',
    'lib/presentation/features/auth/screens/firebase_forgot_password_screen.dart',
    'lib/presentation/features/auth/screens/firebase_bootstrap_screen.dart',
    'lib/presentation/features/auth/screens/firebase_login_screen.dart',
    'lib/presentation/features/accounting_years/screens/accounting_years_screen.dart'
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();

    bool modified = false;

    if (content.contains('error.toString()') && !content.contains('error.toString().localize(context)')) {
      content = content.replaceAll('error.toString()', 'error.toString().localize(context)');
      modified = true;
    }
    
    if (content.contains('(result as Failure).failure.message') && !content.contains('(result as Failure).failure.message.localize(context)')) {
      content = content.replaceAll('(result as Failure).failure.message', '(result as Failure).failure.message.localize(context)');
      modified = true;
    }

    if (content.contains('result.failure.message') && !content.contains('result.failure.message.localize(context)')) {
      content = content.replaceAll('result.failure.message', 'result.failure.message.localize(context)');
      modified = true;
    }

    if (modified) {
      if (!content.contains('utils/failure_localizer.dart')) {
        content = content.replaceFirst('import \'package:flutter/material.dart\';', 'import \'package:flutter/material.dart\';\nimport \'package:payme/presentation/utils/failure_localizer.dart\';');
      }
      file.writeAsStringSync(content);
      print('Modified $path');
    }
  }
}
