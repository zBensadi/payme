import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/loading_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/empty_state_view.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/reports_controller.dart';
import '../../../../services/csv_export_service.dart';
import '../../../providers/repository_providers.dart';
import 'package:payme/l10n/app_localizations.dart';

class ClientBalancesReportScreen extends ConsumerWidget {
  const ClientBalancesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientBalancesReportProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final currency = settingsState.value?.currencyCode ?? '\$';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reportClientBalances),
        actions: [
          state.maybeWhen(
            data: (balances) => balances.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: AppLocalizations.of(context)!.exportCsv,
                    onPressed: () async {
                      try {
                        final csvService = ref.read(csvGenerationServiceProvider);
                        final csv = csvService.generateClientBalancesCsv(balances);
                        await ref.read(csvExportServiceProvider).exportCsv(context, csv, 'client_balances.csv');
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
        data: (clientBalances) {
          if (clientBalances.isEmpty) {
            return EmptyStateView(
              message: AppLocalizations.of(context)!.noClientBalances,
              icon: Icons.account_balance_wallet_outlined,
            );
          }
          
          double totalRemainingAll = clientBalances.fold(0, (sum, item) => sum + item.totals.remainingBalance);
          double totalPaidAll = clientBalances.fold(0, (sum, item) => sum + item.totals.totalPaid);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.purple.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.totalPaid, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${totalPaidAll.toStringAsFixed(2)} $currency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(AppLocalizations.of(context)!.totalOutstanding, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${totalRemainingAll.toStringAsFixed(2)} $currency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange.shade900)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: clientBalances.length,
                  itemBuilder: (context, index) {
                    final item = clientBalances[index];
                    return ListTile(
                      title: Text(item.client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(AppLocalizations.of(context)!.invoicesAndPaid(item.totals.invoiceCount.toString(), item.totals.totalPaid.toStringAsFixed(2), currency)),
                      trailing: Text(
                        '${item.totals.remainingBalance.toStringAsFixed(2)} $currency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: item.totals.remainingBalance > 0 ? Colors.orange.shade900 : Colors.green.shade900,
                        ),
                      ),
                      onTap: () => context.push('/clients/${item.client.id}'),
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
          onRetry: () => ref.invalidate(clientBalancesReportProvider),
        ),
      ),
    );
  }
}
