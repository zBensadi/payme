import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/client.dart';
import '../controllers/client_list_controller.dart';
import '../../../../core/extensions/l10n_extension.dart';

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
      title: Text(context.l10n.deleteClientDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.deleteClientDialogContent(widget.invoiceCount)),
            const SizedBox(height: 16),
            Text(context.l10n.chooseWhatShouldHappen),
            const SizedBox(height: 8),
            
            if (availableClients.isNotEmpty)
              RadioListTile<DeleteClientAction>(
                title: Text(context.l10n.deleteClientDialogTransfer),
                value: DeleteClientAction.transfer,
                groupValue: _action,
                onChanged: (val) => setState(() => _action = val!),
              ),
              
            if (_action == DeleteClientAction.transfer && availableClients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  hint: Text(context.l10n.targetClient),
                  items: availableClients.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedClientId = val),
                ),
              ),

            RadioListTile<DeleteClientAction>(
              title: Text(context.l10n.deleteClientDialogDelete),
              subtitle: Text(context.l10n.deleteClientDialogDeleteWarning, style: const TextStyle(color: Colors.red)),
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
          child: Text(context.l10n.cancel),
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
          child: Text(context.l10n.delete),
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
