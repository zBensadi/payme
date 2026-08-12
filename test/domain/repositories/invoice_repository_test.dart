import 'package:flutter_test/flutter_test.dart';
import 'package:payme/domain/entities/client_visibility_context.dart';
import 'package:payme/core/database/database_service.dart';
import 'package:payme/core/database/migration_runner.dart';
import 'package:payme/core/error/result.dart';
import 'package:logger/logger.dart';
import 'package:payme/core/logging/logger_service.dart';
import 'package:payme/data/datasources/local/invoice_local_datasource.dart';
import 'package:payme/data/repositories_impl/invoice_repository_impl.dart';
import 'package:payme/domain/entities/invoice.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payme/domain/repositories/payment_repository.dart';
import 'package:payme/domain/entities/payment.dart';
import 'package:payme/domain/repositories/settings_repository.dart';
import 'package:payme/domain/entities/business_settings.dart';
import 'package:payme/data/datasources/file/attachment_file_datasource.dart';
import 'package:payme/core/sync/conflict_resolver.dart';
import 'package:payme/core/sync/sync_trigger.dart';
import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/data/datasources/remote/invoice_remote_datasource.dart';

class FakeSettingsRepository implements SettingsRepository {
  bool currencyLocked = false;
  
  @override
  Future<Result<BusinessSettings>> getSettings() async => const Success(BusinessSettings());

  @override
  Future<Result<BusinessSettings>> updateSettings(BusinessSettings settings, {String? newLogoSourcePath}) async => Success(settings);

  @override
  Future<Result<void>> lockCurrency() async {
    currencyLocked = true;
    return const Success(null);
  }
}



class FakePaymentRepository implements PaymentRepository {
  @override
  Future<Result<List<Payment>>> getPaymentsForInvoice(String invoiceId, {ClientVisibilityContext? visibilityContext}) async => const Success([]);
  @override
  Future<Result<List<Payment>>> getPaymentsByPeriod(String yearId, {DateTime? start, DateTime? end, ClientVisibilityContext? visibilityContext}) async => const Success([]);
  @override
  Future<Result<Payment?>> getById(String id) async => const Success(null);
  @override
  Future<Result<Payment>> create(Payment payment, {List<String>? newAttachmentSourcePaths}) async => Success(payment);
  @override
  Future<Result<Payment>> update(Payment payment, {List<String>? newAttachmentSourcePaths, List<String>? deletedAttachmentIds}) async => Success(payment);
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<List<String>>> getAttachmentPathsForInvoice(String invoiceId) async => const Success([]);
  @override
  Future<Result<List<String>>> getAttachmentPathsForYear(String yearId) async => const Success([]);
}

class FakeAttachmentFileDataSource extends AttachmentFileDataSource {
  @override
  Future<void> deleteAttachment(String relativeFilePath) async {}
}

class FakeInvoiceRemoteDataSource implements InvoiceRemoteDataSource {
  @override
  Future<void> pushInvoices(String businessId, List<Invoice> invoices) async {}
  @override
  Future<List<Invoice>> pullInvoices(String businessId, DateTime? lastSyncTime) async => [];
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
  late DatabaseService dbService;
  late InvoiceLocalDataSource localDataSource;
  late InvoiceRepositoryImpl repository;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    dbService = DatabaseService(db);
    final runner = MigrationRunner(LoggerService(Logger()));
    
    // Simulate initial setup manually for tests or use applyMigration
    final v1 = await runner.loadMigrationScript('v1_initial.sql');
    await runner.applyMigration(db, v1, 1);
    
    final v2 = await runner.loadMigrationScript('v2_invoice_sequence.sql');
    await runner.applyMigration(db, v2, 2);

    final v3 = await runner.loadMigrationScript('v3_add_language.sql');
    await runner.applyMigration(db, v3, 3);

    final v4 = await runner.loadMigrationScript('v4_business_settings_sync.sql');
    await runner.applyMigration(db, v4, 4);

    final v5 = await runner.loadMigrationScript('v5_invoice_soft_delete.sql');
    await runner.applyMigration(db, v5, 5);

    final v6 = await runner.loadMigrationScript('v6_accounting_year_sync.sql');
    await runner.applyMigration(db, v6, 6);

    final v7 = await runner.loadMigrationScript('v7_payment_sync.sql');
    await runner.applyMigration(db, v7, 7);

    final v8 = await runner.loadMigrationScript('v8_document_settings.sql');
    await runner.applyMigration(db, v8, 8);

    final v9 = await runner.loadMigrationScript('v9_algerian_compliance.sql');
    await runner.applyMigration(db, v9, 9);

    final v10 = await runner.loadMigrationScript('v10_users_and_roles.sql');
    await runner.applyMigration(db, v10, 10);

    localDataSource = InvoiceLocalDataSource(dbService);
    final fakePaymentRepo = FakePaymentRepository();
    final fileDataSource = FakeAttachmentFileDataSource();
    final remoteDataSource = FakeInvoiceRemoteDataSource();
    final conflictResolver = DefaultConflictResolver<Invoice>();
    final syncTrigger = FakeSyncTrigger();

    repository = InvoiceRepositoryImpl(
      localDataSource, 
      fakePaymentRepo, 
      fileDataSource,
      remoteDataSource,
      conflictResolver,
      syncTrigger,
    );

    // Setup required parent entities
    await db.insert('accounting_years', {
      'id': 'year1', 
      'name': '2026', 
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('clients', {
      'id': 'client1',
      'name': 'Test Client',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'is_deleted': 0,
      'is_dirty': 0,
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('Invoice numbering is sequential and never reused after deletion', () async {
    final now = DateTime.now();
    
    // 1. Initial highest number should be 0
    final r1 = await repository.getHighestInvoiceNumber('year1');
    expect(r1, isA<Success<int>>());
    expect((r1 as Success<int>).value, 0);

    // 2. Create invoice 1
    final inv1 = Invoice(
      id: 'inv1',
      accountingYearId: 'year1',
      clientId: 'client1',
      invoiceNumber: 1,
      date: now,
      amount: 100.0,
      createdAt: now,
      updatedAt: now,
      isDirty: false,
      isDeleted: false,
    );
    await repository.create(inv1);

    // Highest is now 1
    final r2 = await repository.getHighestInvoiceNumber('year1');
    expect((r2 as Success<int>).value, 1);

    // 3. Create invoice 2
    final inv2 = Invoice(
      id: 'inv2',
      accountingYearId: 'year1',
      clientId: 'client1',
      invoiceNumber: 2,
      date: now,
      amount: 200.0,
      createdAt: now,
      updatedAt: now,
      isDirty: false,
      isDeleted: false,
    );
    await repository.create(inv2);

    // Highest is now 2
    final r3 = await repository.getHighestInvoiceNumber('year1');
    expect((r3 as Success<int>).value, 2);

    // 4. Hard delete invoice 2
    await repository.delete('inv2');

    // 5. Verify highest is STILL 2 (so the next generator will issue 3, never reusing 2)
    final r4 = await repository.getHighestInvoiceNumber('year1');
    expect((r4 as Success<int>).value, 2);
  });
}
