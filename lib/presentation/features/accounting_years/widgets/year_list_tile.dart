import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/accounting_year.dart';
import '../../../../core/security/reauth_guard.dart';
import '../controllers/accounting_year_controller.dart';

class YearListTile extends ConsumerWidget {
  final AccountingYear year;

  const YearListTile({super.key, required this.year});

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    // Phase 3 Requirement: Destructive action on non-active year requires ReauthGuard
    final authenticated = await ReauthGuard.requestReauth(context, ref);
    if (!authenticated) return;

    try {
      await ref.read(accountingYearControllerProvider.notifier).delete(year.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accounting year deleted successfully')),
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

  Future<void> _handleRename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: year.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Accounting Year'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Year Name',
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty && newName != year.name) {
      try {
        await ref.read(accountingYearControllerProvider.notifier).rename(year.id, newName.trim());
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          year.isActive ? Icons.event_available : Icons.event,
          color: year.isActive ? Colors.green : Colors.grey,
        ),
        title: Text(
          year.name, 
          style: TextStyle(
            fontWeight: year.isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: year.isActive 
            ? const Text('Active Year', style: TextStyle(color: Colors.green)) 
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!year.isActive)
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(accountingYearControllerProvider.notifier).setActive(year.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Set Active'),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') {
                  _handleRename(context, ref);
                } else if (value == 'delete') {
                  _handleDelete(context, ref);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename'),
                ),
                if (!year.isActive)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
