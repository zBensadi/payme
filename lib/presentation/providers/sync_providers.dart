import 'package:flutter/foundation.dart';
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
    ref.watch(internalSettingsRepositoryProvider) as SynchronizableRepository,
    ref.watch(internalClientRepositoryProvider) as SynchronizableRepository,
    ref.watch(accountingYearRepositoryProvider) as SynchronizableRepository,
    ref.watch(internalInvoiceRepositoryProvider) as SynchronizableRepository,
    ref.watch(internalPaymentRepositoryProvider) as SynchronizableRepository,
    ref.watch(internalRoleRepositoryProvider) as SynchronizableRepository,
    ref.watch(internalUserRepositoryProvider) as SynchronizableRepository,
  ];
});


final syncServiceProvider = Provider<SyncService>((ref) {
  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] ENTER provider build');
  final repositories = ref.watch(synchronizableRepositoriesProvider);
  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] synchronizableRepositoriesProvider resolved → ${repositories.length} repos: ${repositories.map((r) => r.runtimeType).join(', ')}');
  final connectivity = ref.watch(connectivityServiceProvider);
  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] connectivityServiceProvider resolved');
  final logger = ref.watch(syncLoggerProvider);
  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] syncLoggerProvider resolved');
  final syncTrigger = ref.watch(syncTriggerProvider);
  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] syncTriggerProvider resolved');

  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] BEFORE SyncService() constructor');
  final service = SyncService(
    repositories: repositories,
    connectivity: connectivity,
    logger: logger,
    syncTrigger: syncTrigger,
  );
  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] AFTER  SyncService() constructor → ok');

  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] BEFORE ref.listen(currentUserProvider, fireImmediately: true)');
  ref.listen(currentUserProvider, (previous, next) {
    debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] currentUserProvider changed → businessId=${next.value?.user.businessId}');
    service.setBusinessId(next.value?.user.businessId);
  }, fireImmediately: true);
  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] AFTER  ref.listen(currentUserProvider) registered');

  ref.onDispose(() => service.dispose());
  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] EXIT provider build → returning SyncService');
  return service;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.statusStream;
});
