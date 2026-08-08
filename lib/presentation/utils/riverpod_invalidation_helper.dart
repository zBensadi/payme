import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/events/repository_change_publisher.dart';
import '../../core/events/repository_event.dart';

extension RepositoryInvalidation on Ref {
  /// Automatically invalidates this provider when a relevant background event occurs in the repository.
  /// Ignores `localMutation` by default to avoid redundant fetches if the UI optimistically updates.
  void invalidateOnRepositoryChange(
    Object repository, {
    List<RepositoryEventType> targetEvents = const [
      RepositoryEventType.remoteSynchronization,
      RepositoryEventType.conflictResolved,
      RepositoryEventType.bulkImport,
    ],
  }) {
    if (repository is RepositoryChangePublisher) {
      final sub = repository.watchEvents().listen((event) {
        if (targetEvents.contains(event.type)) {
          invalidateSelf();
        }
      });
      onDispose(sub.cancel);
    }
  }
}
