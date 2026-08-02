import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/confirm_dialog.dart';
import '../controllers/deleted_clients_controller.dart';
import '../widgets/client_list_tile.dart';

class DeletedClientsScreen extends ConsumerStatefulWidget {
  const DeletedClientsScreen({super.key});

  @override
  ConsumerState<DeletedClientsScreen> createState() => _DeletedClientsScreenState();
}

class _DeletedClientsScreenState extends ConsumerState<DeletedClientsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(deletedClientSearchQueryProvider.notifier).updateQuery(query);
  }

  Future<void> _handleRestore(String id, String name) async {
    final proceed = await ConfirmDialog.show(
      context,
      title: 'Restore Client',
      content: 'Are you sure you want to restore $name?',
      confirmLabel: 'Restore',
    );

    if (proceed && mounted) {
      try {
        await ref.read(deletedClientsControllerProvider.notifier).restore(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client restored'), backgroundColor: Colors.green),
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
    final state = ref.watch(deletedClientsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Clients'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search deleted clients...',
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
                final isSearching = ref.read(deletedClientSearchQueryProvider).isNotEmpty;
                if (isSearching) {
                  return const EmptyStateView(
                    message: 'No deleted clients match your search.',
                    icon: Icons.search_off,
                  );
                }
                return const EmptyStateView(
                  message: 'No deleted clients.',
                  icon: Icons.delete_outline,
                );
              }

              return ListView.separated(
                itemCount: clients.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return ClientListTile(
                    client: client,
                    onRestore: () => _handleRestore(client.id, client.name),
                  );
                },
              );
            },
            loading: () => const LoadingView(message: 'Loading deleted clients...'),
            error: (error, stack) => ErrorView(
              message: error.toString().replaceAll('Exception: ', ''),
            ),
          ),
        ),
      ),
    );
  }
}
