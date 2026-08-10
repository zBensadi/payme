import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/data/datasources/local/accounting_year_local_datasource.dart';
import 'package:payme/data/repositories_impl/accounting_year_repository_impl.dart';
import 'package:payme/domain/entities/accounting_year.dart';
import 'package:payme/data/datasources/remote/accounting_year_remote_datasource.dart';
import 'package:payme/core/sync/accounting_year_conflict_resolver.dart';
import 'package:payme/core/sync/sync_trigger.dart';
import 'package:payme/core/sync/sync_domain.dart';

class FakeAccountingYearRemoteDataSource implements AccountingYearRemoteDataSource {
  @override
  Future<void> pushYears(String businessId, List<AccountingYear> years) async {}
  @override
  Future<List<AccountingYear>> pullYears(String businessId, DateTime? lastSyncTime) async => [];
}

class FakeSyncTrigger implements SyncTrigger {
  @override
  void requestSync(SyncDomain domain) {}
  @override
  void requestFullSync() {}
  @override
  Stream<SyncDomain> get syncRequested => const Stream.empty();
  @override
  void dispose() {}
}

void main() {
  late Database db;
  late AccountingYearRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE accounting_years (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL UNIQUE,
                    is_active INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    remote_id TEXT,
                    synced_at TEXT,
                    is_dirty INTEGER NOT NULL DEFAULT 0
                )
              ''');
            }));

    final dataSource = AccountingYearLocalDataSource(db);
    final remoteDataSource = FakeAccountingYearRemoteDataSource();
    final conflictResolver = AccountingYearConflictResolver();
    final syncTrigger = FakeSyncTrigger();
    
    repository = AccountingYearRepositoryImpl(
      dataSource,
      remoteDataSource,
      conflictResolver,
      syncTrigger,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Creating first year makes it automatically active', () async {
    final result = await repository.create('2025');
    expect(result, isA<Success>());
    
    final year = (result as Success).value;
    expect(year.isActive, isTrue);
  });

  test('Creating duplicate year returns Failure', () async {
    await repository.create('2025');
    final duplicate = await repository.create('2025');
    
    expect(duplicate, isA<Failure>());
  });

  test('Deleting active year returns Failure', () async {
    final result = await repository.create('2025');
    final activeId = (result as Success).value.id;
    
    final deleteResult = await repository.delete(activeId);
    expect(deleteResult, isA<Failure>());
  });

  test('Switching year ensures exactly one is active', () async {
    final firstResult = await repository.create('2025');
    final firstId = (firstResult as Success).value.id;
    
    final secondResult = await repository.create('2026');
    final secondId = (secondResult as Success).value.id;

    // Initially, 2025 is active, 2026 is not
    var activeYearResult = await repository.getActive();
    expect((activeYearResult as Success).value?.id, firstId);

    // Switch to 2026
    await repository.setActive(secondId);

    // Verify 2026 is active
    activeYearResult = await repository.getActive();
    expect((activeYearResult as Success).value?.id, secondId);

    // Verify 2025 is NO LONGER active
    final allYearsResult = await repository.getAll();
    final years = (allYearsResult as Success<List<AccountingYear>>).value;
    
    final firstYearAfterSwitch = years.firstWhere((y) => y.id == firstId);
    expect(firstYearAfterSwitch.isActive, isFalse);

    // Verify exactly one is active
    final activeCount = years.where((y) => y.isActive).length;
    expect(activeCount, 1);
  });
}
