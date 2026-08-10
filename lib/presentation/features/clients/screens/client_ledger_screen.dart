import '../../../../core/formatters/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../invoices/controllers/invoice_list_controller.dart';
import '../../invoices/widgets/invoice_status_badge.dart';
import '../controllers/client_ledger_controller.dart';
import '../widgets/ledger_summary_card.dart';
import '../../invoices/utils/pdf_preview_helper.dart';
import '../../settings/controllers/settings_controller.dart';
import 'package:payme/l10n/app_localizations.dart';

class ClientLedgerScreen extends ConsumerWidget {
  final String clientId;

  const ClientLedgerScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerState = ref.watch(clientLedgerControllerProvider(clientId));
    final settingsState = ref.watch(settingsControllerProvider);
    final currency = settingsState.value?.currencyCode ?? '\$';

    return ledgerState.when(
      data: (state) {
        final clientName = state.client.name;
        final invoices = state.items;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.ledgerTitle(clientName)),
          ),
          body: Column(
            children: [
              LedgerSummaryCard(totals: state.totals),
              Expanded(
                child: invoices.isEmpty
                    ? EmptyStateView(
                        message: AppLocalizations.of(context)!.noInvoicesFound,
                        icon: Icons.receipt_long,
                        actionLabel: AppLocalizations.of(context)!.createInvoice,
                        onAction: () => context.push('/clients/$clientId/invoices/new'),
                      )
                    : ListView.builder(
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final item = invoices[index];
                  final invoice = item.invoice;
                  final status = item.status;

                  return ListTile(
                    title: Text(AppLocalizations.of(context)!.invoiceNumberTitle(invoice.invoiceNumber.toString())),
                    subtitle: Text('${DateFormatter.formatDate(invoice.date)} • ${NumberFormatter.formatAmount(invoice.amount)} $currency'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InvoiceStatusBadge(status: status),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'payments') {
                              context.push('/clients/$clientId/invoices/${invoice.id}/payments');
                            } else if (value == 'export_pdf') {
                              if (context.mounted) {
                                PdfPreviewHelper.openPreview(context, ref, invoice);
                              }
                            } else if (value == 'edit') {
                              context.push('/clients/$clientId/invoices/${invoice.id}');
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => ConfirmDialog(
                                  title: AppLocalizations.of(context)!.deleteInvoiceTitle,
                                  content: AppLocalizations.of(context)!.deleteInvoiceConfirm,
                                  isDestructive: true,
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await InvoiceDeleter.delete(ref, invoice.id, clientId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(AppLocalizations.of(context)!.invoiceDeleted), backgroundColor: Colors.green),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'payments', child: Text(AppLocalizations.of(context)!.payments)),
                            PopupMenuItem(value: 'export_pdf', child: Text(AppLocalizations.of(context)!.exportPdf)),
                            PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit)),
                            PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => context.push('/clients/$clientId/invoices/${invoice.id}/payments'),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/clients/$clientId/invoices/new'),
          child: const Icon(Icons.add),
        ),
      );
      },
      loading: () => Scaffold(body: LoadingView(message: AppLocalizations.of(context)!.loadingLedger)),
      error: (error, _) => Scaffold(
        body: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(clientLedgerControllerProvider(clientId)),
        ),
      ),
    );
  }
}
