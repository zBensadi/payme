import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/client.dart';
import '../controllers/client_list_controller.dart';
import 'package:payme/l10n/app_localizations.dart';

enum DeleteClientAction {
  transfer,
  delete,
}

class DeleteClientDialog extends ConsumerStatefulWidget {
  final Client client;
  final int invoiceCount;

  const DeleteClientDialog({
    super.key,
    required this.client,
    required this.invoiceCount,
  });

  @override
  ConsumerState<DeleteClientDialog> createState() => _DeleteClientDialogState();
}

class _DeleteClientDialogState extends ConsumerState<DeleteClientDialog> {
  DeleteClientAction _action = DeleteClientAction.transfer;
  String? _selectedClientId;

  @override
  Widget build(BuildContext context) {
    // Exclude the current client from the transfer list
    final allClients = ref.watch(clientListControllerProvider).maybeWhen(data: (d) => d, orElse: () => <Client>[]);
    final availableClients = allClients.where((c) => c.id != widget.client.id).toList();

    // If there are no other clients to transfer to, force "delete" action
    if (availableClients.isEmpty && _action == DeleteClientAction.transfer) {
      _action = DeleteClientAction.delete;
    }

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.deleteClientDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.deleteClientDialogContent(widget.invoiceCount)),
            const SizedBox(height: 16),
            const Text('Choose what should happen:'),
            const SizedBox(height: 8),
            
            if (availableClients.isNotEmpty)
              RadioListTile<DeleteClientAction>(
                title: Text(AppLocalizations.of(context)!.deleteClientDialogTransfer),
                value: DeleteClientAction.transfer,
                groupValue: _action,
                onChanged: (val) => setState(() => _action = val!),
              ),
              
            if (_action == DeleteClientAction.transfer && availableClients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  hint: Text(AppLocalizations.of(context)!.targetClient),
                  items: availableClients.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedClientId = val),
                ),
              ),

            RadioListTile<DeleteClientAction>(
              title: Text(AppLocalizations.of(context)!.deleteClientDialogDelete),
              subtitle: Text(AppLocalizations.of(context)!.deleteClientDialogDeleteWarning, style: const TextStyle(color: Colors.red)),
              value: DeleteClientAction.delete,
              groupValue: _action,
              onChanged: (val) => setState(() => _action = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canProceed()
              ? () {
                  Navigator.of(context).pop({
                    'action': _action,
                    'targetClientId': _selectedClientId,
                  });
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Delete Client'),
        ),
      ],
    );
  }

  bool _canProceed() {
    if (_action == DeleteClientAction.transfer) {
      return _selectedClientId != null;
    }
    return true; // For delete action
  }
}
