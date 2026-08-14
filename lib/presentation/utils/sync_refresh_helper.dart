import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_providers.dart';
import '../providers/sync_trigger_provider.dart';
import '../../core/sync/sync_status.dart';

class SyncRefreshHelper {
  /// Triggers a full synchronization and waits for it to complete.
  /// 
  /// Resolves when the triggered sync completes successfully, fails, or is determined to be offline.
  /// It is immune to race conditions where the sync status might initially be idle before transitioning.
  static Future<void> refresh(WidgetRef ref) async {
    final syncTrigger = ref.read(syncTriggerProvider);
    final syncService = ref.read(syncServiceProvider);

    final isInitiallyOffline = syncService.currentStatus == SyncStatus.offline;
    
    // 1. Request a fresh full sync. 
    // This will enqueue domains into SyncService, which will start syncing either immediately
    // or after a very short debounce.
    syncTrigger.requestFullSync();

    if (isInitiallyOffline) {
       // If currently offline, the SyncService will abort immediately.
       return;
    }

    final completer = Completer<void>();
    
    bool hasSeenSyncing = syncService.currentStatus == SyncStatus.syncing;

    final sub = syncService.statusStream.listen((status) {
      if (status == SyncStatus.syncing) {
        hasSeenSyncing = true;
      } else if (hasSeenSyncing && (status == SyncStatus.idle || status == SyncStatus.failed || status == SyncStatus.offline)) {
        // Sync has finished
        if (!completer.isCompleted) {
          completer.complete();
        }
      } else if (!hasSeenSyncing && (status == SyncStatus.failed || status == SyncStatus.offline)) {
        // Edge case: Sync failed or went offline before reaching syncing state
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    try {
      // Because SyncService has a 2-second debounce, plus network roundtrips, 
      // the timeout should be generous.
      await completer.future.timeout(const Duration(seconds: 15));
    } catch (_) {
      // Timeout reached. Resolve gracefully so the UI doesn't hang indefinitely.
    } finally {
      await sub.cancel();
    }
  }
}
