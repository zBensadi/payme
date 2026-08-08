import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';
import 'sync_trigger_provider.dart';
import '../features/auth/controllers/current_user_controller.dart';
import '../../core/sync/connectivity_service.dart';
import '../../core/sync/sync_logger.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/sync_status.dart';
import '../../core/sync/synchronizable_repository.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final syncLoggerProvider = Provider<SyncLogger>((ref) {
  return SyncLogger();
});

/// List of all repositories that implement the SynchronizableRepository interface.
/// In future milestones, this list will be populated with implementations like
/// ClientRepository, InvoiceRepository, etc.
final synchronizableRepositoriesProvider = Provider<List<SynchronizableRepository>>((ref) {
  return [
    ref.watch(settingsRepositoryProvider) as SynchronizableRepository,
    ref.watch(clientRepositoryProvider) as SynchronizableRepository,
  ];
});


final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    repositories: ref.watch(synchronizableRepositoriesProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    logger: ref.watch(syncLoggerProvider),
    syncTrigger: ref.watch(syncTriggerProvider),
  );

  ref.listen(currentUserProvider, (previous, next) {
    service.setBusinessId(next.value?.businessContext?.businessId);
  }, fireImmediately: true);

  ref.onDispose(() => service.dispose());
  return service;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.statusStream;
});
