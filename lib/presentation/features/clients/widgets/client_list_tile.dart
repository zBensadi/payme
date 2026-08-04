import 'package:flutter/material.dart';
import '../../../../domain/entities/client.dart';
import 'package:payme/l10n/app_localizations.dart';

class ClientListTile extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const ClientListTile({
    super.key,
    required this.client,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.blue.shade800,
        child: Text(client.name.isNotEmpty ? client.name.substring(0, 1).toUpperCase() : '?'),
      ),
      title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: client.phone != null && client.phone!.isNotEmpty
          ? Text(client.phone!)
          : (client.email != null && client.email!.isNotEmpty ? Text(client.email!) : null),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit?.call();
              break;
            case 'delete':
              onDelete?.call();
              break;
            case 'restore':
              onRestore?.call();
              break;
          }
        },
        itemBuilder: (context) => [
          if (onEdit != null)
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit, size: 20),
                title: Text(AppLocalizations.of(context)!.edit),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          if (onRestore != null)
            PopupMenuItem(
              value: 'restore',
              child: ListTile(
                leading: const Icon(Icons.restore, size: 20, color: Colors.green),
                title: Text(AppLocalizations.of(context)!.restore, style: const TextStyle(color: Colors.green)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          if (onDelete != null)
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete, size: 20, color: Colors.red),
                title: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
        ],
      ),
    );
  }
}
