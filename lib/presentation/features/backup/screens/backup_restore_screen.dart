import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/backup_controller.dart';
import '../../../../core/security/reauth_guard.dart';
import 'package:payme/l10n/app_localizations.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final destinationPath = await FilePicker.saveFile(
      dialogTitle: AppLocalizations.of(context)!.saveBackup,
      fileName: 'payme_backup_${DateTime.now().toIso8601String().split('T')[0]}.zip',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (destinationPath != null && context.mounted) {
      final success = await ref.read(backupControllerProvider.notifier).createBackup(destinationPath);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.backupCreatedSuccess), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final isAuthenticated = await ReauthGuard.requestReauth(context, ref);

    if (isAuthenticated != true || !context.mounted) return;

    // 2. Pick the backup file
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty && context.mounted) {
      final sourcePath = result.files.first.path;
      if (sourcePath != null) {
        final success = await ref.read(backupControllerProvider.notifier).restoreBackup(sourcePath);
        if (success && context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.restoreSuccessfulTitle),
              content: Text(AppLocalizations.of(context)!.restoreSuccessfulDesc),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupControllerProvider);
    final isLoading = state.isLoading;

    ref.listen<AsyncValue<void>>(backupControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString()), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.backupAndRestore),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.backup, size: 64, color: Colors.blue),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.backupDesc,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: isLoading ? null : () => _createBackup(context, ref),
                    icon: const Icon(Icons.download),
                    label: Text(AppLocalizations.of(context)!.createBackup),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : () => _restoreBackup(context, ref),
                    icon: const Icon(Icons.restore),
                    label: Text(AppLocalizations.of(context)!.restoreBackup),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
