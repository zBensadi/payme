import '../../../../core/formatters/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/loading_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/reports_controller.dart';
import '../controllers/report_filter_controller.dart';
import '../../clients/controllers/client_list_controller.dart';
import '../../../../services/csv_export_service.dart';
import '../../../providers/repository_providers.dart';
import 'package:payme/l10n/app_localizations.dart';
import '../../payments/widgets/payment_method_badge.dart'; // we may need to localize payment methods via badge

class PaymentsByPeriodReportScreen extends ConsumerWidget {
  const PaymentsByPeriodReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(reportFilterProvider);
    final start = filters.startDate;
    final end = filters.endDate;
    
    final state = ref.watch(paymentsByPeriodReportProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final currency = settingsState.value?.currencyCode ?? '\$';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reportPaymentsByPeriod),
        actions: [
          state.maybeWhen(
            data: (payments) => payments.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: AppLocalizations.of(context)!.exportCsv,
                    onPressed: () async {
                      try {
                        final csvService = ref.read(csvGenerationServiceProvider);
                        final csv = await csvService.generatePaymentsCsv(payments);
                        if (!context.mounted) return;
                        await ref.read(csvExportServiceProvider).exportCsv(context, csv, 'payments_by_period.csv');
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(start != null ? DateFormatter.formatDate(start) : AppLocalizations.of(context)!.startDate),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: start ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        ref.read(reportFilterProvider.notifier).setDateRange(date, end);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(end != null ? DateFormatter.formatDate(end) : AppLocalizations.of(context)!.endDate),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: end ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        // Set end date to end of day
                        ref.read(reportFilterProvider.notifier).setDateRange(start, DateTime(date.year, date.month, date.day, 23, 59, 59));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Expanded(
                  child: ref.watch(clientListControllerProvider).when(
                        data: (clients) {
                          return DropdownButtonFormField<String?>(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.filterByClient,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            initialValue: filters.clientId,
                            items: [
                              DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.allClients)),
                              ...clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                            ],
                            onChanged: (val) {
                              ref.read(reportFilterProvider.notifier).setClient(val);
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Text(AppLocalizations.of(context)!.errorLoadingClients),
                      ),
                ),
                if (start != null || end != null || filters.clientId != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      ref.read(reportFilterProvider.notifier).clearFilters();
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: state.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return EmptyStateView(
                    message: AppLocalizations.of(context)!.noPaymentsForPeriod,
                    icon: Icons.search_off,
                  );
                }
                
                double total = payments.fold(0, (sum, p) => sum + p.amount);

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      alignment: Alignment.centerRight,
                      child: Text(
                        AppLocalizations.of(context)!.totalAmountLabel(NumberFormatter.formatAmount(total), currency),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          return ListTile(
                            title: Text('${NumberFormatter.formatAmount(payment.amount)} $currency'),
                            subtitle: Text('${DateFormatter.formatDate(payment.date)}'), // Removed displayName as we can just show the badge below if needed, or translate it
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (payment.notes != null && payment.notes!.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Icon(Icons.notes, color: Colors.grey),
                                  ),
                                PaymentMethodBadge(method: payment.method),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => LoadingView(message: AppLocalizations.of(context)!.loadingReport),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(paymentsByPeriodReportProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
