import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/accounting_year_controller.dart';
import '../widgets/year_list_tile.dart';
import 'package:payme/l10n/app_localizations.dart';

class AccountingYearsScreen extends ConsumerWidget {
  const AccountingYearsScreen({super.key});

  Future<void> _handleCreate(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.newAccountingYear),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.yearNameHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(AppLocalizations.of(context)!.create),
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
        title: Text(AppLocalizations.of(context)!.accountingYears),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: state.when(
            data: (years) {
              if (years.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.noAccountingYearsFound,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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
        tooltip: AppLocalizations.of(context)!.createNewYear,
        child: const Icon(Icons.add),
      ),
    );
  }
}
