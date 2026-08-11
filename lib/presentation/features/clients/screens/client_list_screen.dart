import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/confirm_dialog.dart';
import '../controllers/client_list_controller.dart';
import '../widgets/client_list_tile.dart';
import '../widgets/delete_client_dialog.dart';
import '../../../../services/client_deletion_service.dart';
import '../../../../domain/entities/client.dart';
import '../../../../core/error/result.dart';
import '../../../providers/repository_providers.dart';
import 'package:payme/l10n/app_localizations.dart';
import '../../../../services/csv_export_service.dart';
import 'package:intl/intl.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(clientSearchQueryProvider.notifier).updateQuery(query);
  }

  Future<void> _handleDelete(Client client) async {
    final invoiceRepo = ref.read(invoiceRepositoryProvider);
    final countResult = await invoiceRepo.countAllForClient(client.id);
    final count = countResult is Success ? (countResult as Success<int>).value : 0;

    if (count == 0) {
      // Normal soft delete
      final proceed = await ConfirmDialog.show(
        context,
        title: AppLocalizations.of(context)!.deleteClientDialogTitle,
        content: AppLocalizations.of(context)!.deleteClientConfirm(client.name),
        confirmLabel: AppLocalizations.of(context)!.delete,
        isDestructive: true,
      );
      if (proceed && mounted) {
        try {
          await ref.read(clientListControllerProvider.notifier).softDelete(client.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.clientDeleted), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
            );
          }
        }
      }
      return;
    }

    // Has invoices
    if (!mounted) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => DeleteClientDialog(
        client: client,
        invoiceCount: count,
      ),
    );

    if (result != null && mounted) {
      try {
        final action = result['action'] as DeleteClientAction;
        final targetClientId = result['targetClientId'] as String?;

        final service = ref.read(clientDeletionServiceProvider);
        final deleteResult = await service.deleteClientWithInvoices(
          client.id,
          transferToClientId: action == DeleteClientAction.transfer ? targetClientId : null,
        );
        
        if (deleteResult is Failure) {
          throw Exception((deleteResult as Failure<void>).failure.message);
        }

        // Refresh list
        ref.invalidate(clientListControllerProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.clientDeleted), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.clients),
        actions: [
          state.maybeWhen(
            data: (clients) => clients.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: AppLocalizations.of(context)!.exportCsv,
                    onPressed: () async {
                      try {
                        final csvService = ref.read(csvGenerationServiceProvider);
                        final csv = csvService.generateClientsCsv(clients);
                        final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
                        await ref.read(csvExportServiceProvider).exportCsv(context, csv, 'clients_$timestamp.csv');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorExportFailed(e.toString()))));
                        }
                      }
                    },
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: AppLocalizations.of(context)!.deletedClients,
            onPressed: () => context.push('/clients/deleted'),
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
                hintText: AppLocalizations.of(context)!.searchClientHint,
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
            data: (clients) {
              if (clients.isEmpty) {
                final isSearching = ref.read(clientSearchQueryProvider).isNotEmpty;
                if (isSearching) {
                  return EmptyStateView(
                    message: AppLocalizations.of(context)!.noDeletedClientsSearch,
                    icon: Icons.search_off,
                  );
                }
                return EmptyStateView(
                  message: AppLocalizations.of(context)!.clientListEmpty,
                  actionLabel: AppLocalizations.of(context)!.addClient,
                  icon: Icons.people_outline,
                  onAction: () => context.push('/clients/new'),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.read(clientListControllerProvider.notifier).refresh(),
                child: ListView.separated(
                  itemCount: clients.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return ClientListTile(
                      client: client,
                      onTap: () => context.push('/clients/${client.id}'),
                      onEdit: () => context.push('/clients/edit', extra: client),
                      onDelete: () => _handleDelete(client),
                    );
                  },
                ),
              );
            },
            loading: () => const LoadingView(message: '...'),
            error: (error, stack) => ErrorView(
              message: error.toString().replaceAll('Exception: ', ''),
              onRetry: () => ref.read(clientListControllerProvider.notifier).refresh(),
            ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/clients/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
