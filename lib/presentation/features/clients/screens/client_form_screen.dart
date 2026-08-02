import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/client.dart';
import '../../../widgets/confirm_dialog.dart';
import '../controllers/client_form_controller.dart';
import '../widgets/client_form.dart';

class ClientFormScreen extends ConsumerWidget {
  final Client? client;

  const ClientFormScreen({super.key, this.client});

  Future<void> _handleSave(BuildContext context, WidgetRef ref, Client newClient, {bool force = false}) async {
    try {
      final controller = ref.read(clientFormControllerProvider.notifier);
      final success = force ? await controller.saveForce(newClient) : await controller.save(newClient);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(client == null ? 'Client created successfully' : 'Client updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } on FormatException catch (e) {
      if (e.message == 'duplicate_warning' && context.mounted) {
        final proceed = await ConfirmDialog.show(
          context,
          title: 'Duplicate Client',
          content: 'A client with the same name and phone number already exists. Do you want to save anyway?',
          confirmLabel: 'Save Anyway',
        );
        if (proceed && context.mounted) {
          await _handleSave(context, ref, newClient, force: true);
        }
      }
    } catch (e) {
      // Unhandled exceptions are caught by the controller and turned into AsyncError
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(clientFormControllerProvider);
    final isEditing = client != null;

    ref.listen(clientFormControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client' : 'New Client'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Stack(
            children: [
              ClientForm(
                initialClient: client,
                onSave: (newClient) => _handleSave(context, ref, newClient),
              ),
              if (formState is AsyncLoading)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
