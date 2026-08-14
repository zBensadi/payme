import sys

file_path = "lib/presentation/features/clients/screens/client_form_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

replacement = """class ClientFormScreen extends ConsumerStatefulWidget {
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
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
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
}"""

import re
content = re.sub(r'class ClientFormScreen extends ConsumerWidget \{.*', replacement, content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
