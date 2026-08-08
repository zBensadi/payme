import 'sync_priority.dart';
import 'sync_result.dart';
import 'sync_domain.dart';

abstract class SynchronizableRepository {
  /// Domain of the repository for targeted synchronization
  SyncDomain get syncDomain;

  /// Priority determines the order of sync (e.g., Settings=high, Clients=medium)
  SyncPriority get syncPriority;
  
  /// Pushes local dirty records to Firestore.
  Future<SyncResult> pushChanges(String businessId);
  
  /// Pulls remote changes from Firestore and applies them to SQLite.
  Future<SyncResult> pullChanges(String businessId, DateTime? lastSyncTime);
}
