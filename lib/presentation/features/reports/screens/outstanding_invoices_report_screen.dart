import 'package:flutter/material.dart';
import 'package:payme/presentation/utils/failure_localizer.dart';
import '../../../../core/formatters/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/loading_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/empty_state_view.dart';
import '../../invoices/widgets/invoice_status_badge.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/reports_controller.dart';
import '../../../../services/csv_export_service.dart';
import '../../../providers/repository_providers.dart';
import 'package:payme/l10n/app_localizations.dart';

class OutstandingInvoicesReportScreen extends ConsumerWidget {
  const OutstandingInvoicesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(outstandingInvoicesReportProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final currency = settingsState.value?.currencyCode ?? '\$';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reportOutstandingInvoices),
        actions: [
          state.maybeWhen(
            data: (invoices) => invoices.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: AppLocalizations.of(context)!.exportCsv,
                    onPressed: () async {
                      try {
                        final csvService = ref.read(csvGenerationServiceProvider);
                        final csv = await csvService.generateInvoicesCsv(invoices);
                        if (!context.mounted) return;
                        await ref.read(csvExportServiceProvider).exportCsv(context, csv, 'outstanding_invoices.csv');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorExportFailed(e.toString()))));
                        }
                      }
                    },
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: state.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return EmptyStateView(
              message: AppLocalizations.of(context)!.noOutstandingInvoices,
              icon: Icons.check_circle_outline,
            );
          }
          
          double totalRemaining = invoices.fold(0, (sum, item) => sum + item.remainingAmount);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.totalOutstanding, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${NumberFormatter.formatAmount(totalRemaining)} $currency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange.shade900)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final item = invoices[index];
                    return ListTile(
                      title: Text(AppLocalizations.of(context)!.invoiceNumberLabel(item.invoice.invoiceNumber.toString())),
                      subtitle: Text('${DateFormatter.formatDate(item.invoice.date)} • ${AppLocalizations.of(context)!.remainingAmount(NumberFormatter.formatAmount(item.remainingAmount), currency)}'),
                      trailing: InvoiceStatusBadge(status: item.status),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => LoadingView(message: AppLocalizations.of(context)!.loadingReport),
        error: (error, _) => ErrorView(
          message: error.toString().localize(context),
          onRetry: () => ref.invalidate(outstandingInvoicesReportProvider),
        ),
      ),
    );
  }
}
