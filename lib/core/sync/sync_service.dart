import 'dart:async';
import 'connectivity_service.dart';
import 'sync_logger.dart';
import 'sync_status.dart';
import 'synchronizable_repository.dart';
import 'sync_domain.dart';
import 'sync_trigger.dart';

class SyncService {
  final List<SynchronizableRepository> _repositories;
  final ConnectivityService _connectivity;
  final SyncLogger _logger;
  final SyncTrigger _syncTrigger;
  
  String? _businessId;
  SyncStatus _currentStatus = SyncStatus.idle;
  final _statusController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<SyncDomain>? _syncTriggerSub;
  
  // Debounce state
  final Set<SyncDomain> _pendingDomains = {};
  Timer? _debounceTimer;
  final Duration _debounceDuration;

  bool hasCompletedInitialSync = false;

  // Retry state
  int _retryAttempt = 0;
  Timer? _retryTimer;
  bool _isSyncing = false;

  SyncService({
    required List<SynchronizableRepository> repositories,
    required ConnectivityService connectivity,
    required SyncLogger logger,
    required SyncTrigger syncTrigger,
    Duration debounceDuration = const Duration(seconds: 2),
  })  : _repositories = List.from(repositories),
        _connectivity = connectivity,
        _logger = logger,
        _syncTrigger = syncTrigger,
        _debounceDuration = debounceDuration {
    
    // Sort repositories by priority: high -> medium -> low
    _repositories.sort((a, b) => a.syncPriority.index.compareTo(b.syncPriority.index));
    
    // Listen to connectivity to trigger recovery
    _connectivitySub = _connectivity.isConnected.listen((isConnected) {
      if (!isConnected) {
        _updateStatus(SyncStatus.offline);
        _cancelRetry();
      } else {
        // Connectivity restored
        _logger.logInfo('Connectivity restored. Triggering sync.');
        if (_businessId != null) {
          _syncTrigger.requestFullSync();
        }
      }
    });

    // Listen to autonomous sync triggers
    _syncTriggerSub = _syncTrigger.syncRequested.listen((domain) {
      _pendingDomains.add(domain);
      
      if (!hasCompletedInitialSync) {
        // Use a near-zero debounce for the very first sync to gather synchronously added domains, 
        // avoiding the 2-second delay but ensuring all domains from requestFullSync are collected.
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 50), () {
          if (_pendingDomains.isNotEmpty) {
            final domainsToSync = Set<SyncDomain>.from(_pendingDomains);
            _pendingDomains.clear();
            synchronizeDomains(domainsToSync);
          }
        });
        return;
      }
      
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDuration, () {
        if (_pendingDomains.isNotEmpty) {
          final domainsToSync = Set<SyncDomain>.from(_pendingDomains);
          _pendingDomains.clear();
          synchronizeDomains(domainsToSync);
        }
      });
    });
  }

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get currentStatus => _currentStatus;

  /// Sets the current business context. Required before synchronization can occur.
  void setBusinessId(String? businessId) {
    _businessId = businessId;
    if (_businessId != null) {
      _syncTrigger.requestFullSync();
    } else {
      _cancelRetry();
      _updateStatus(SyncStatus.idle);
    }
  }

  Future<void> synchronizeDomains(Set<SyncDomain> domains) async {
    if (_businessId == null) {
      _logger.logError('Cannot synchronize: businessId is null');
      return;
    }
    if (_isSyncing) {
      _logger.logInfo('Synchronization already in progress. Skipping trigger.');
      return;
    }

    final isOnline = await _connectivity.checkConnectivity();
    if (!isOnline) {
      _updateStatus(SyncStatus.offline);
      return;
    }

    _cancelRetry();
    await _executeSyncCycle(domains);
  }

  Future<void> _executeSyncCycle(Set<SyncDomain> domains) async {
    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);
    _logger.logInfo('Starting sync cycle for business: $_businessId, domains: $domains');

    try {
      final targetedRepositories = _repositories.where((r) => domains.contains(r.syncDomain)).toList();

      // 1. PUSH phase
      for (final repo in targetedRepositories) {
        _logger.logInfo('Pushing changes for ${repo.runtimeType}');
        final result = await repo.pushChanges(_businessId!);
        _logger.logOperation(repo.runtimeType.toString(), 'PUSH', result.uploaded, 'SUCCESS');
      }

      // 2. PULL phase
      for (final repo in targetedRepositories) {
        _logger.logInfo('Pulling changes for ${repo.runtimeType}');
        // null lastSyncTime signifies a full pull, or let the repo manage it internally.
        final result = await repo.pullChanges(_businessId!, null);
        _logger.logOperation(repo.runtimeType.toString(), 'PULL', result.downloaded, 'SUCCESS');
      }

      _retryAttempt = 0;
      hasCompletedInitialSync = true;
      _updateStatus(SyncStatus.idle);
      _logger.logInfo('Sync cycle completed successfully.');
    } catch (e, stack) {
      _logger.logError('Sync cycle failed', e, stack);
      _updateStatus(SyncStatus.failed);
      hasCompletedInitialSync = true; // Even if it fails, the initial attempt is over
      _scheduleRetry(domains);
    } finally {
      _isSyncing = false;
    }
  }

  void _scheduleRetry(Set<SyncDomain> domains) {
    _retryAttempt++;
    // Exponential backoff: 2s, 4s, 8s, 16s... max 60s
    final delaySeconds = (1 << _retryAttempt).clamp(2, 60);
    _logger.logInfo('Scheduling sync retry $_retryAttempt in $delaySeconds seconds.');
    
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_currentStatus != SyncStatus.offline) {
        synchronizeDomains(domains);
      }
    });
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void _updateStatus(SyncStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _syncTriggerSub?.cancel();
    _cancelRetry();
    _statusController.close();
  }
}
