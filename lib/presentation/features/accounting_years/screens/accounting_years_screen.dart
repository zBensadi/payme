import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/accounting_year_controller.dart';
import '../widgets/year_list_tile.dart';

class AccountingYearsScreen extends ConsumerWidget {
  const AccountingYearsScreen({super.key});

  Future<void> _handleCreate(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Accounting Year'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Year Name (e.g., 2026)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      try {
        await ref.read(accountingYearControllerProvider.notifier).create(newName.trim());
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountingYearControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting Years'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: state.when(
            data: (years) {
              if (years.isEmpty) {
                return const Center(
                  child: Text(
                    'No accounting years found.\nCreate one to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: years.length,
                itemBuilder: (context, index) {
                  return YearListTile(year: years[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleCreate(context, ref),
        tooltip: 'Create New Year',
        child: const Icon(Icons.add),
      ),
    );
  }
}
