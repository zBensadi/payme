import 'package:flutter/material.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../domain/services/client_ledger_calculator.dart';
import '../../settings/controllers/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/l10n/app_localizations.dart';

import '../../../../domain/entities/client.dart';

class LedgerSummaryCard extends ConsumerWidget {
  final ClientLedgerTotals totals;
  final Client client;

  const LedgerSummaryCard({super.key, required this.totals, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsControllerProvider);
    final currency = settingsState.value?.currencyCode ?? '\$';

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    title: AppLocalizations.of(context)!.totalInvoiced,
                    value: '${NumberFormatter.formatAmount(totals.totalInvoiced)} $currency',
                    color: Colors.blue.shade800,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    title: AppLocalizations.of(context)!.totalPaid,
                    value: '${NumberFormatter.formatAmount(totals.totalPaid)} $currency',
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryStat(
                  title: AppLocalizations.of(context)!.invoiceCount,
                  value: '${totals.invoiceCount}',
                  color: Colors.grey.shade800,
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
                _SummaryStat(
                  title: AppLocalizations.of(context)!.remainingBalance,
                  value: '${NumberFormatter.formatAmount(totals.remainingBalance)} $currency',
                  color: totals.remainingBalance > 0 ? Colors.red.shade800 : Colors.green.shade800,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ],
            ),
            if (client.rc?.isNotEmpty == true || client.nif?.isNotEmpty == true || client.nis?.isNotEmpty == true || client.art?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (client.rc?.isNotEmpty == true) Text('${AppLocalizations.of(context)!.rc}: ${client.rc}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800)),
                    if (client.nif?.isNotEmpty == true) Text('${AppLocalizations.of(context)!.nif}: ${client.nif}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800)),
                    if (client.nis?.isNotEmpty == true) Text('${AppLocalizations.of(context)!.nis}: ${client.nis}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800)),
                    if (client.art?.isNotEmpty == true) Text('${AppLocalizations.of(context)!.art}: ${client.art}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final CrossAxisAlignment crossAxisAlignment;

  const _SummaryStat({
    required this.title,
    required this.value,
    required this.color,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
