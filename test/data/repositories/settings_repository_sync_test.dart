import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/core/sync/sync_trigger.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/sync/conflict_resolver.dart';
import 'package:payme/domain/entities/business_settings.dart';
import 'package:payme/data/repositories_impl/settings_repository_impl.dart';
import 'package:payme/data/datasources/local/settings_local_datasource.dart';
import 'package:payme/data/datasources/remote/settings_remote_datasource.dart';
import 'package:payme/data/datasources/file/logo_file_datasource.dart';

class MockSettingsLocalDataSource implements SettingsLocalDataSource {
  BusinessSettings? _dirtySettings;
  BusinessSettings _currentSettings = const BusinessSettings();
  bool wasOverwriteCalled = false;
  bool wasUpdateSyncMetadataCalled = false;
  bool wasUpdateSettingsCalled = false;

  @override
  Future<BusinessSettings?> getDirtySettings() async => _dirtySettings;

  @override
  Future<BusinessSettings> getSettings() async => _currentSettings;

  @override
  Future<void> overwriteSettings(BusinessSettings settings) async {
    wasOverwriteCalled = true;
    _currentSettings = settings;
  }

  @override
  Future<void> updateSettings(BusinessSettings settings) async {
    wasUpdateSettingsCalled = true;
    _currentSettings = settings;
  }

  @override
  Future<void> updateSyncMetadata({
    required int id,
    required String remoteId,
    required DateTime syncedAt,
    required bool isDirty,
  }) async {
    wasUpdateSyncMetadataCalled = true;
  }

  void setMockDirtySettings(BusinessSettings? settings) {
    _dirtySettings = settings;
  }
  
  void setMockCurrentSettings(BusinessSettings settings) {
    _currentSettings = settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSettingsRemoteDataSource implements SettingsRemoteDataSource {
  BusinessSettings? pushedSettings;
  BusinessSettings? _pulledSettings;

  @override
  Future<void> pushSettings(String businessId, BusinessSettings settings) async {
    pushedSettings = settings;
  }

  @override
  Future<BusinessSettings?> pullSettings(String businessId) async => _pulledSettings;

  void setMockPulledSettings(BusinessSettings? settings) {
    _pulledSettings = settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLogoFileDataSource implements LogoFileDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummySyncTrigger implements SyncTrigger {
  @override
  void requestSync(SyncDomain domain) {}

  @override
  void requestFullSync() {}

  @override
  Stream<SyncDomain> get syncRequested => Stream.empty();

  @override
  void dispose() {}
}

void main() {
  late SettingsRepositoryImpl repository;
  late MockSettingsLocalDataSource localDataSource;
  late MockSettingsRemoteDataSource remoteDataSource;
  late MockLogoFileDataSource logoFileDataSource;
  late ConflictResolver<BusinessSettings> conflictResolver;
  late DummySyncTrigger syncTrigger;

  setUp(() {
    localDataSource = MockSettingsLocalDataSource();
    remoteDataSource = MockSettingsRemoteDataSource();
    logoFileDataSource = MockLogoFileDataSource();
    conflictResolver = DefaultConflictResolver<BusinessSettings>();
    syncTrigger = DummySyncTrigger();

    repository = SettingsRepositoryImpl(
      localDataSource,
      remoteDataSource,
      logoFileDataSource,
      conflictResolver,
      syncTrigger,
    );
  });

  group('SettingsRepositoryImpl Sync', () {
    test('pushChanges uploads dirty settings and clears dirty flag', () async {
      final dirtySettings = const BusinessSettings(businessName: 'Dirty', isDirty: true);
      localDataSource.setMockDirtySettings(dirtySettings);

      final result = await repository.pushChanges('biz1');

      expect(result.uploaded, 1);
      expect(result.skipped, 0);
      expect(remoteDataSource.pushedSettings?.businessName, 'Dirty');
      expect(localDataSource.wasUpdateSyncMetadataCalled, true);
    });

    test('pushChanges skips if no dirty settings', () async {
      localDataSource.setMockDirtySettings(null);

      final result = await repository.pushChanges('biz1');

      expect(result.skipped, 1);
      expect(result.uploaded, 0);
      expect(remoteDataSource.pushedSettings, isNull);
    });

    test('pullChanges downloads and overwrites if local is clean', () async {
      final remoteSettings = const BusinessSettings(businessName: 'Remote', isDirty: false);
      remoteDataSource.setMockPulledSettings(remoteSettings);
      
      final localSettings = const BusinessSettings(businessName: 'Local', isDirty: false);
      localDataSource.setMockCurrentSettings(localSettings);

      final result = await repository.pullChanges('biz1', null);

      expect(result.downloaded, 1);
      expect(localDataSource.wasOverwriteCalled, true);
    });

    test('pullChanges resolves conflict if local is dirty', () async {
      final remoteSettings = const BusinessSettings(businessName: 'Remote', isDirty: false);
      remoteDataSource.setMockPulledSettings(remoteSettings);
      
      final localSettings = const BusinessSettings(businessName: 'Local', isDirty: true);
      localDataSource.setMockCurrentSettings(localSettings);

      // Default conflict resolver returns local
      final result = await repository.pullChanges('biz1', null);

      expect(result.conflicts, 1);
      // Since local is still dirty, we expect updateSettings to be called to keep it dirty and skip overwrite
      expect(localDataSource.wasUpdateSettingsCalled, true);
      expect(localDataSource.wasOverwriteCalled, false);
      expect(result.skipped, 1); // We skip pulling because local won
    });
  });
}
