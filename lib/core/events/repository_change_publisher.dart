import 'repository_event.dart';

abstract class RepositoryChangePublisher {
  /// Emits strongly typed events when the repository mutates local data.
  Stream<RepositoryEvent> watchEvents();
  
  /// Frees stream resources.
  void dispose();
}
