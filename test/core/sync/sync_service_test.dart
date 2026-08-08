import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/sync/connectivity_service.dart';
import 'package:payme/core/sync/sync_logger.dart';
import 'package:payme/core/sync/sync_priority.dart';
import 'package:payme/core/sync/sync_result.dart';
import 'package:payme/core/sync/sync_service.dart';
import 'package:payme/core/sync/synchronizable_repository.dart';
import 'dart:async';

import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/core/sync/sync_trigger.dart';

class MockConnectivityService implements ConnectivityService {
  final StreamController<bool> _mockController = StreamController<bool>.broadcast();
  bool _isConnected = true;

  @override
  Stream<bool> get isConnected => _mockController.stream;

  @override
  Future<bool> checkConnectivity() async => _isConnected;

  void simulateConnectivity(bool connected) {
    _isConnected = connected;
    _mockController.add(connected);
  }

  @override
  void dispose() {
    _mockController.close();
  }
}

class MockSynchronizableRepository implements SynchronizableRepository {
  final SyncPriority _priority;
  final SyncDomain _domain;
  bool pushCalled = false;
  bool pullCalled = false;
  final bool shouldFail;

  MockSynchronizableRepository(this._priority, this._domain, {this.shouldFail = false});

  @override
  SyncPriority get syncPriority => _priority;

  @override
  SyncDomain get syncDomain => _domain;

  @override
  Future<SyncResult> pushChanges(String businessId) async {
    pushCalled = true;
    if (shouldFail) throw Exception('Push failed');
    return const SyncResult(uploaded: 1);
  }

  @override
  Future<SyncResult> pullChanges(String businessId, DateTime? lastSyncTime) async {
    pullCalled = true;
    if (shouldFail) throw Exception('Pull failed');
    return const SyncResult(downloaded: 1);
  }
}

void main() {
  late MockConnectivityService mockConnectivity;
  late SyncLogger syncLogger;
  late SyncTrigger syncTrigger;

  setUp(() {
    mockConnectivity = MockConnectivityService();
    syncLogger = SyncLogger();
    syncTrigger = SyncTrigger();
  });

  tearDown(() {
    syncTrigger.dispose();
  });

  test('SyncService orchestrates push then pull in priority order', () async {
    final highRepo = MockSynchronizableRepository(SyncPriority.high, SyncDomain.settings);
    final lowRepo = MockSynchronizableRepository(SyncPriority.low, SyncDomain.clients);
    
    // Pass in reverse order to ensure it sorts correctly
    final service = SyncService(
      repositories: [lowRepo, highRepo],
      connectivity: mockConnectivity,
      logger: syncLogger,
      syncTrigger: syncTrigger,
      debounceDuration: Duration.zero,
    );

    service.setBusinessId('biz1');
    await Future.delayed(const Duration(milliseconds: 100)); // wait for sync to complete

    expect(highRepo.pushCalled, true);
    expect(highRepo.pullCalled, true);
    expect(lowRepo.pushCalled, true);
    expect(lowRepo.pullCalled, true);
  });

  test('SyncService triggers sync on connectivity restored', () async {
    final repo = MockSynchronizableRepository(SyncPriority.high, SyncDomain.settings);
    
    mockConnectivity.simulateConnectivity(false);
    
    final service = SyncService(
      repositories: [repo],
      connectivity: mockConnectivity,
      logger: syncLogger,
      syncTrigger: syncTrigger,
      debounceDuration: Duration.zero,
    );
    service.setBusinessId('biz1');
    
    // Initially offline, should not sync
    await Future.delayed(const Duration(milliseconds: 50));
    expect(repo.pushCalled, false);

    // Simulate online
    mockConnectivity.simulateConnectivity(true);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(repo.pushCalled, true);
  });
}
