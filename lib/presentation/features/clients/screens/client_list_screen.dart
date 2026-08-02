import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/confirm_dialog.dart';
import '../controllers/client_list_controller.dart';
import '../widgets/client_list_tile.dart';

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

  Future<void> _handleDelete(String id, String name) async {
    final proceed = await ConfirmDialog.show(
      context,
      title: 'Delete Client',
      content: 'Are you sure you want to delete $name?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (proceed && mounted) {
      try {
        await ref.read(clientListControllerProvider.notifier).softDelete(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client deleted'), backgroundColor: Colors.green),
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
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Deleted Clients',
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
                hintText: 'Search by name or phone...',
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: state.when(
            data: (clients) {
              if (clients.isEmpty) {
                final isSearching = ref.read(clientSearchQueryProvider).isNotEmpty;
                if (isSearching) {
                  return const EmptyStateView(
                    message: 'No clients match your search.',
                    icon: Icons.search_off,
                  );
                }
                return EmptyStateView(
                  message: 'You haven\'t added any clients yet.',
                  actionLabel: 'Add Client',
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
                      onEdit: () => context.push('/clients/edit', extra: client),
                      onDelete: () => _handleDelete(client.id, client.name),
                    );
                  },
                ),
              );
            },
            loading: () => const LoadingView(message: 'Loading clients...'),
            error: (error, stack) => ErrorView(
              message: error.toString().replaceAll('Exception: ', ''),
              onRetry: () => ref.read(clientListControllerProvider.notifier).refresh(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/clients/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
