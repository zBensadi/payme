import '../../../../core/formatters/formatters.dart';
import 'package:flutter/material.dart';
import 'package:payme/presentation/utils/failure_localizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_view.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/invoice_status.dart';
import '../controllers/global_invoice_list_controller.dart';
import '../widgets/invoice_status_badge.dart';
import '../../settings/controllers/settings_controller.dart';
import '../utils/pdf_preview_helper.dart';
import 'package:payme/l10n/app_localizations.dart';
import '../../../../presentation/utils/sync_refresh_helper.dart';

class GlobalInvoiceListScreen extends ConsumerStatefulWidget {
  const GlobalInvoiceListScreen({super.key});

  @override
  ConsumerState<GlobalInvoiceListScreen> createState() => _GlobalInvoiceListScreenState();
}

class _GlobalInvoiceListScreenState extends ConsumerState<GlobalInvoiceListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(globalInvoiceFilterProvider.notifier).update(
          (state) => state.copyWith(searchQuery: query),
        );
  }

  void _onStatusFilterChanged(InvoiceStatus? status) {
    ref.read(globalInvoiceFilterProvider.notifier).update(
          (state) => state.copyWith(status: status, clearStatus: status == null),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalInvoiceListControllerProvider);
    final filter = ref.watch(globalInvoiceFilterProvider);
    final currency = ref.watch(settingsControllerProvider).maybeWhen(data: (d) => d.currencyCode, orElse: () => '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.allInvoices),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<InvoiceStatus?>(
              value: filter.status,
              hint: Text(AppLocalizations.of(context)!.filterByStatus),
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.allStatuses)),
                ...InvoiceStatus.values.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.name.toUpperCase()),
                    )),
              ],
              onChanged: _onStatusFilterChanged,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchInvoiceHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
        ),
      ),
      body: state.when(
        data: (items) {
          if (items.isEmpty) {
            if (filter.searchQuery.isNotEmpty || filter.status != null) {
              return EmptyStateView(
                message: AppLocalizations.of(context)!.noInvoicesFilter,
                icon: Icons.search_off,
              );
            }
            return EmptyStateView(
              message: AppLocalizations.of(context)!.noInvoicesFound,
              icon: Icons.receipt_long,
            );
          }

          return RefreshIndicator(
            onRefresh: () => SyncRefreshHelper.refresh(ref),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                final invoice = item.invoice;
                final clientName = item.client?.name ?? AppLocalizations.of(context)!.unknownClient;

                return ListTile(
                  title: Text(AppLocalizations.of(context)!.clientInvoiceNumberTitle(clientName, invoice.invoiceNumber.toString())),
                  subtitle: Text('${DateFormatter.formatDate(invoice.date)} • ${NumberFormatter.formatAmount(invoice.amount)} $currency'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InvoiceStatusBadge(status: item.status),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'payments') {
                            context.push('/clients/${invoice.clientId}/invoices/${invoice.id}/payments');
                          } else if (value == 'export_pdf') {
                            PdfPreviewHelper.openPreview(context, ref, invoice);
                          } else if (value == 'edit') {
                            context.push('/clients/${invoice.clientId}/invoices/${invoice.id}');
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'payments', child: Text(AppLocalizations.of(context)!.viewPayments)),
                          PopupMenuItem(value: 'export_pdf', child: Text(AppLocalizations.of(context)!.exportPdf)),
                          PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit)),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => context.push('/clients/${invoice.clientId}/invoices/${invoice.id}/payments'),
                );
              },
            ),
          );
        },
        loading: () => LoadingView(message: AppLocalizations.of(context)!.loadingInvoices),
        error: (error, _) => ErrorView(
          message: error.toString().localize(context),
          onRetry: () => ref.read(globalInvoiceListControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}
