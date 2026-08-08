import '../sync/sync_domain.dart';

enum RepositoryEventType {
  localMutation,         // Data modified by the local user UI
  remoteSynchronization, // Data overwritten by background pull
  conflictResolved,      // Data modified during sync conflict resolution
  bulkImport             // Data imported from external files
}

class RepositoryEvent {
  final RepositoryEventType type;
  final SyncDomain domain;
  final DateTime timestamp;
  final int? affectedRows;

  const RepositoryEvent({
    required this.type,
    required this.domain,
    required this.timestamp,
    this.affectedRows,
  });
}
