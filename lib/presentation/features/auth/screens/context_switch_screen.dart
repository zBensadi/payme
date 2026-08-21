import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app.dart';
import '../../../../core/database/database_provider.dart';
import '../../../providers/sync_providers.dart';
import '../controllers/context_resolution_controller.dart';
import '../controllers/firebase_auth_controller.dart';

class ContextSwitchScreen extends ConsumerStatefulWidget {
  const ContextSwitchScreen({super.key});

  @override
  ConsumerState<ContextSwitchScreen> createState() => _ContextSwitchScreenState();
}

class _ContextSwitchScreenState extends ConsumerState<ContextSwitchScreen> {
  bool _isWiping = false;

  Future<void> _performWipeAndRestart() async {
    setState(() => _isWiping = true);
    try {
      // 1. Pause sync service safely
      final syncService = ref.read(syncServiceProvider);
      await syncService.pause();

      // 2. Wipe database and attachments
      final dbService = ref.read(databaseProvider);
      await dbService.wipeAndClose();

      // 3. Restart application Riverpod container
      if (mounted) {
        await PayMeRoot.restartApp(context);
      }
    } catch (e) {
      debugPrint('[CONTEXT_SWITCH] Error during wipe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching business: $e')),
        );
        setState(() => _isWiping = false);
      }
    }
  }

  Future<void> _cancelAndLogout() async {
    final authController = ref.read(firebaseAuthControllerProvider.notifier);
    await authController.logout();
  }

  @override
  void initState() {
    super.initState();
    // Auto-wipe if dirtyCount is 0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contextData = ref.read(contextResolutionProvider);
      if (contextData.state == ContextResolutionState.contextSwitchPending &&
          contextData.dirtyCount == 0) {
        _performWipeAndRestart();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contextData = ref.watch(contextResolutionProvider);

    if (_isWiping || contextData.dirtyCount == 0) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text('Switching business context...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unsaved Changes Detected'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              'You have ${contextData.dirtyCount} unsynchronized changes.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You are logging into a different business account. Switching businesses will permanently discard your local offline changes from the previous session.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _cancelAndLogout,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel & Logout'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _performWipeAndRestart,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Discard & Switch'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
