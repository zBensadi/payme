import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/accounting_year.dart';
import '../../../../domain/entities/permissions.dart';
import '../../../widgets/require_permission.dart';
import '../controllers/accounting_year_controller.dart';
import 'package:payme/l10n/app_localizations.dart';

class YearListTile extends ConsumerWidget {
  final AccountingYear year;

  const YearListTile({super.key, required this.year});

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete),
        content: Text(AppLocalizations.of(context)!.deleteAccountingYearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(accountingYearControllerProvider.notifier).delete(year.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.accountingYearDeleted)),
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
        title: Text(AppLocalizations.of(context)!.renameAccountingYear),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.yearName,
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
            child: Text(AppLocalizations.of(context)!.save),
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
            ? Text(AppLocalizations.of(context)!.activeYear, style: const TextStyle(color: Colors.green)) 
            : null,
        trailing: RequirePermission(
          permission: Permissions.accountingYearsManage,
          child: Row(
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
                  child: Text(AppLocalizations.of(context)!.setActive),
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
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(AppLocalizations.of(context)!.rename),
                  ),
                  if (!year.isActive)
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
