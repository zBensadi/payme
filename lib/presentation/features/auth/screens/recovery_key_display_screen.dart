import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import 'package:payme/l10n/app_localizations.dart';

class RecoveryKeyDisplayScreen extends ConsumerWidget {
  final String recoveryKey;

  const RecoveryKeyDisplayScreen({super.key, required this.recoveryKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.recoveryKey),
        automaticallyImplyLeading: false, // Prevent going back to setup
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.important,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.recoveryKeyWarning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: SelectableText(
                    recoveryKey,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: recoveryKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.copiedToClipboard)),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(AppLocalizations.of(context)!.copyToClipboard),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Mark as authenticated to let the router take us to dashboard
                    ref.read(authControllerProvider.notifier).markAsAuthenticated();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(AppLocalizations.of(context)!.savedRecoveryKey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
