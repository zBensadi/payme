import '../../core/error/result.dart';
import '../../core/sync/synchronizable_repository.dart';
import '../entities/client_visibility.dart';

import '../../core/events/repository_change_publisher.dart';

abstract class ClientVisibilityRepository implements SynchronizableRepository, RepositoryChangePublisher {
  Future<Result<void>> addVisibility(ClientVisibility visibility);
  Future<Result<void>> removeVisibility(String clientId, String userId);
  Future<Result<List<ClientVisibility>>> getVisibilityForClient(String clientId);
}
