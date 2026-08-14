import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/data/datasources/local/accounting_year_local_datasource.dart';
import 'package:payme/data/repositories_impl/accounting_year_repository_impl.dart';
import 'package:payme/data/datasources/local/invoice_local_datasource.dart';
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

class FakeInvoiceLocalDataSource implements InvoiceLocalDataSource {
  int invoiceCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #countAllForYear) {
      return Future.value(invoiceCount);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late Database db;
  late AccountingYearRepositoryImpl repository;
  late FakeInvoiceLocalDataSource invoiceDataSource;
  late AccountingYearLocalDataSource localDataSource;

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
                    created_by TEXT,
                    updated_by TEXT,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    remote_id TEXT,
                    synced_at TEXT,
                    is_dirty INTEGER NOT NULL DEFAULT 0,
                    is_deleted INTEGER NOT NULL DEFAULT 0
                )
              ''');
            }));

    localDataSource = AccountingYearLocalDataSource(db);
    invoiceDataSource = FakeInvoiceLocalDataSource();
    final remoteDataSource = FakeAccountingYearRemoteDataSource();
    final conflictResolver = AccountingYearConflictResolver();
    final syncTrigger = FakeSyncTrigger();
    
    repository = AccountingYearRepositoryImpl(
      localDataSource,
      invoiceDataSource,
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

  test('Year with undeleted invoices cannot be soft-deleted', () async {
    final result = await repository.create('2028');
    final id = (result as Success).value.id;

    // Create another year and activate it to allow deletion of 2028
    await repository.create('2028_other');
    final otherYears = await repository.getAll();
    final otherId = (otherYears as Success<List<AccountingYear>>).value.firstWhere((y) => y.id != id).id;
    await repository.setActive(otherId);

    // Simulate invoices attached
    invoiceDataSource.invoiceCount = 1;

    final deleteResult = await repository.delete(id);
    expect(deleteResult, isA<Failure>());
    expect((deleteResult as Failure).failure.message, contains('contains invoices'));
    
    // Cleanup invoice count for other tests
    invoiceDataSource.invoiceCount = 0;
  });

  test('Year with no undeleted invoices can be soft-deleted and is marked is_deleted=1, is_dirty=1', () async {
    final result = await repository.create('2029');
    final id = (result as Success).value.id;

    invoiceDataSource.invoiceCount = 0;
    
    // We cannot delete the active year, so let's make another year active first
    await repository.create('2030');
    final activeResult = await repository.getActive();
    if (activeResult is Success && (activeResult as Success).value?.id == id) {
      // It's active, switch active year
      final otherYears = await repository.getAll();
      final otherId = (otherYears as Success<List<AccountingYear>>).value.firstWhere((y) => y.id != id).id;
      await repository.setActive(otherId);
    }

    final deleteResult = await repository.delete(id);
    expect(deleteResult, isA<Success>());

    // Verify raw SQLite to ensure soft-delete behavior
    final rawData = await db.query('accounting_years', where: 'id = ?', whereArgs: [id]);
    expect(rawData.isNotEmpty, isTrue);
    expect(rawData.first['is_deleted'], 1);
    expect(rawData.first['is_dirty'], 1);
  });

  test('Deleted year is excluded from getAll, getActive, and getById', () async {
    final result = await repository.create('2031');
    final id = (result as Success).value.id;
    
    await repository.create('2032'); // Ensure 2031 can be deleted by having another year

    // Make sure 2031 is not active
    final activeResult = await repository.getActive();
    if (activeResult is Success && (activeResult as Success).value?.id == id) {
      final otherYears = await repository.getAll();
      final otherId = (otherYears as Success<List<AccountingYear>>).value.firstWhere((y) => y.id != id).id;
      await repository.setActive(otherId);
    }

    await repository.delete(id);

    final allYears = await repository.getAll();
    expect((allYears as Success<List<AccountingYear>>).value.any((y) => y.id == id), isFalse);

    final byId = await localDataSource.getById(id);
    expect(byId, isNull);
    
    // If it was somehow active (which shouldn't be allowed, but just in case), getActive shouldn't return it
    final active = await repository.getActive();
    expect((active as Success).value?.id, isNot(equals(id)));
  });
}
