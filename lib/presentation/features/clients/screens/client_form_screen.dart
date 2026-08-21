import 'package:flutter/material.dart';
import 'package:payme/presentation/utils/failure_localizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/client.dart';
import '../../../widgets/confirm_dialog.dart';
import '../controllers/client_form_controller.dart';
import '../widgets/client_form.dart';
import 'package:payme/l10n/app_localizations.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  final Client? client;

  const ClientFormScreen({super.key, this.client});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize controller state in microtask to avoid modifying providers during build
    Future.microtask(() {
      ref.read(clientFormControllerProvider.notifier).init(widget.client);
    });
  }

  Future<void> _handleSave(BuildContext context, Client newClient, {bool force = false}) async {
    try {
      final controller = ref.read(clientFormControllerProvider.notifier);
      final success = force ? await controller.saveForce(newClient) : await controller.save(newClient);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.client == null ? AppLocalizations.of(context)!.clientCreated : AppLocalizations.of(context)!.clientUpdated),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } on FormatException catch (e) {
      if (e.message == 'duplicate_warning' && context.mounted) {
        final proceed = await ConfirmDialog.show(
          context,
          title: AppLocalizations.of(context)!.duplicateClientTitle,
          content: AppLocalizations.of(context)!.duplicateClientMessage,
          confirmLabel: AppLocalizations.of(context)!.saveAnyway,
        );
        if (proceed && context.mounted) {
          await _handleSave(context, newClient, force: true);
        }
      }
    } catch (e) {
      // Unhandled exceptions are caught by the controller and turned into AsyncError
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(clientFormControllerProvider);
    final isEditing = widget.client != null;

    ref.listen(clientFormControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().localize(context).replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppLocalizations.of(context)!.editClient : AppLocalizations.of(context)!.newClient),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Stack(
            children: [
              if (formState.value != null)
                ClientForm(
                  initialClient: widget.client,
                  onSave: (newClient) => _handleSave(context, newClient),
                ),
              if (formState is AsyncLoading || formState.value == null)
                Container(
                  color: Colors.black.withValues(alpha: 0.1),
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