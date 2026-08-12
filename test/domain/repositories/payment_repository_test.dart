import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payme/core/database/database_service.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/data/datasources/local/payment_local_datasource.dart';
import 'package:payme/data/datasources/file/attachment_file_datasource.dart';
import 'package:payme/data/repositories_impl/payment_repository_impl.dart';
import 'package:payme/domain/entities/payment.dart';
import 'package:payme/domain/entities/payment_method.dart';
import 'package:path/path.dart' as p;
import 'package:payme/core/sync/sync_trigger.dart';
import 'package:payme/core/sync/conflict_resolver.dart';
import 'package:payme/data/datasources/remote/payment_remote_datasource.dart';

class FakePaymentRemoteDataSource implements PaymentRemoteDataSource {
  @override
  Future<void> pushPayments(String businessId, List<Payment> payments) async {}
  @override
  Future<List<Payment>> pullPayments(String businessId, DateTime? lastSyncTime) async => [];
}

class FakePaymentConflictResolver implements ConflictResolver<Payment> {
  @override
  Payment resolve(Payment local, Payment remote) => remote;
}

class TestDatabaseService implements DatabaseService {
  late Database _db;

  @override
  Database get db => _db;

  @override
  Future<T> runInTransaction<T>(Future<T> Function(Transaction txn) action) async {
    return _db.transaction(action);
  }

  @override
  Future<void> reopen(String dbPath) async {}

  Future<void> initForTest() async {
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;
    _db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        // Just the minimal tables needed for payments test
        await db.execute('''
          CREATE TABLE accounting_years (
            id TEXT PRIMARY KEY,
            year INTEGER NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 0,
            is_closed INTEGER NOT NULL DEFAULT 0,
            created_by TEXT,
            updated_by TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE clients (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            rc TEXT,
            nif TEXT,
            nis TEXT,
            art TEXT,
            visibility_type TEXT NOT NULL DEFAULT 'everyone',
            created_by TEXT,
            updated_by TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE invoices (
            id TEXT PRIMARY KEY,
            accounting_year_id TEXT NOT NULL,
            client_id TEXT NOT NULL,
            invoice_number INTEGER NOT NULL,
            date TEXT NOT NULL,
            due_date TEXT NOT NULL,
            amount REAL NOT NULL,
            notes TEXT,
            created_by TEXT,
            updated_by TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            remote_id TEXT,
            synced_at TEXT,
            is_dirty INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (accounting_year_id) REFERENCES accounting_years(id) ON DELETE CASCADE,
            FOREIGN KEY (client_id) REFERENCES clients(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE payments (
            id TEXT PRIMARY KEY,
            invoice_id TEXT NOT NULL,
            date TEXT NOT NULL,
            amount REAL NOT NULL,
            method TEXT NOT NULL,
            reference TEXT,
            notes TEXT,
            created_by TEXT,
            updated_by TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            remote_id TEXT,
            synced_at TEXT,
            is_dirty INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE payment_attachments (
            id TEXT PRIMARY KEY,
            payment_id TEXT NOT NULL,
            file_path TEXT NOT NULL,
            original_file_name TEXT NOT NULL,
            file_type TEXT NOT NULL,
            file_size_bytes INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE
          )
        ''');
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    ));
  }

  @override
  Future<void> close() async {
    await _db.close();
  }
}

class TestAttachmentFileDataSource extends AttachmentFileDataSource {
  final Directory tempDir;

  TestAttachmentFileDataSource(this.tempDir);

  @override
  Future<String> saveAttachment(String sourceFilePath, String newFileName) async {
    final destPath = p.join(tempDir.path, newFileName);
    final sourceFile = File(sourceFilePath);
    await sourceFile.copy(destPath);
    return newFileName;
  }

  @override
  Future<void> deleteAttachment(String relativeFilePath) async {
    final file = File(p.join(tempDir.path, relativeFilePath));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<String> getAbsolutePath(String relativeFilePath) async {
    return p.join(tempDir.path, relativeFilePath);
  }
}

void main() {
  late TestDatabaseService dbService;
  late PaymentRepositoryImpl repository;
  late Directory tempAttachmentsDir;

  setUp(() async {
    dbService = TestDatabaseService();
    await dbService.initForTest();
    
    // Set up temp directory for files
    tempAttachmentsDir = await Directory.systemTemp.createTemp('payme_test_attachments');
    
    final localDataSource = PaymentLocalDataSource(dbService);
    final fileDataSource = TestAttachmentFileDataSource(tempAttachmentsDir);
    final remoteDataSource = FakePaymentRemoteDataSource();
    final conflictResolver = FakePaymentConflictResolver();
    final syncTrigger = SyncTrigger();
    
    repository = PaymentRepositoryImpl(
      localDataSource, 
      fileDataSource,
      remoteDataSource,
      conflictResolver,
      syncTrigger,
    );

    // Seed dependencies: Year, Client, Invoice
    await dbService.db.insert('accounting_years', {
      'id': 'year_1',
      'year': 2026,
      'start_date': '2026-01-01T00:00:00.000',
      'end_date': '2026-12-31T23:59:59.000',
      'is_active': 1,
      'is_closed': 0,
      'created_at': '2026-01-01T00:00:00.000',
      'updated_at': '2026-01-01T00:00:00.000',
    });

    await dbService.db.insert('clients', {
      'id': 'client_1',
      'name': 'Test Client',
      'created_at': '2026-01-01T00:00:00.000',
      'updated_at': '2026-01-01T00:00:00.000',
      'is_deleted': 0,
    });

    await dbService.db.insert('invoices', {
      'id': 'inv_1',
      'accounting_year_id': 'year_1',
      'client_id': 'client_1',
      'invoice_number': 1,
      'date': '2026-02-01T00:00:00.000',
      'due_date': '2026-03-01T00:00:00.000',
      'amount': 1000.0,
      'created_at': '2026-02-01T00:00:00.000',
      'updated_at': '2026-02-01T00:00:00.000',
      'is_dirty': 0,
    });
  });

  tearDown(() async {
    await dbService.close();
    if (tempAttachmentsDir.existsSync()) {
      tempAttachmentsDir.deleteSync(recursive: true);
    }
  });

  test('create Payment successfully adds row without attachments', () async {
    final payment = Payment(
      id: 'pay_1',
      invoiceId: 'inv_1',
      date: DateTime.parse('2026-02-15T00:00:00.000Z'),
      amount: 250.0,
      method: PaymentMethod.bankTransfer,
      reference: 'TX123',
      createdAt: DateTime.parse('2026-02-15T00:00:00.000Z'),
      updatedAt: DateTime.parse('2026-02-15T00:00:00.000Z'),
      isDirty: true,
      attachments: [],
    );

    final result = await repository.create(payment);
    
    expect(result, isA<Success<Payment>>());
    final saved = (result as Success<Payment>).value;
    expect(saved.id, 'pay_1');
    expect(saved.amount, 250.0);
    expect(saved.method, PaymentMethod.bankTransfer);
    
    // Verify in db
    final rows = await dbService.db.query('payments');
    expect(rows.length, 1);
  });

  test('create Payment with file paths copies files and creates attachments', () async {
    // Create a dummy file to simulate user picking a file
    final dummySourceFile = File(p.join(tempAttachmentsDir.path, 'source_dummy.pdf'));
    await dummySourceFile.writeAsString('dummy pdf content');

    final payment = Payment(
      id: 'pay_2',
      invoiceId: 'inv_1',
      date: DateTime.parse('2026-02-16T00:00:00.000Z'),
      amount: 500.0,
      method: PaymentMethod.cheque,
      createdAt: DateTime.parse('2026-02-16T00:00:00.000Z'),
      updatedAt: DateTime.parse('2026-02-16T00:00:00.000Z'),
      isDirty: true,
      attachments: [],
    );

    final result = await repository.create(payment, newAttachmentSourcePaths: [dummySourceFile.path]);
    
    expect(result, isA<Success<Payment>>());
    final saved = (result as Success<Payment>).value;
    expect(saved.attachments.length, 1);
    expect(saved.attachments.first.originalFileName, 'source_dummy.pdf');
    expect(saved.attachments.first.fileType, 'pdf');

    // Verify DB
    final attachRows = await dbService.db.query('payment_attachments');
    expect(attachRows.length, 1);
    
    // Verify physical file was copied
    final copiedFilePath = p.join(tempAttachmentsDir.path, attachRows.first['file_path'] as String);
    final copiedFile = File(copiedFilePath);
    expect(await copiedFile.exists(), true);
  });

  test('delete Payment cascades in SQLite and we manually delete physical files', () async {
    final dummySourceFile = File(p.join(tempAttachmentsDir.path, 'source_dummy2.jpg'));
    await dummySourceFile.writeAsString('dummy jpg content');

    final payment = Payment(
      id: 'pay_3',
      invoiceId: 'inv_1',
      date: DateTime.now(),
      amount: 100.0,
      method: PaymentMethod.cash,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDirty: true,
    );

    final createResult = await repository.create(payment, newAttachmentSourcePaths: [dummySourceFile.path]);
    final saved = (createResult as Success<Payment>).value;
    
    final relativePath = saved.attachments.first.filePath;
    final expectedFile = File(p.join(tempAttachmentsDir.path, relativePath));
    expect(await expectedFile.exists(), true);

    // Act
    await repository.delete('pay_3');

    // Assert
    final rows = await dbService.db.query('payments');
    expect(rows.length, 1);
    expect(rows.first['is_deleted'], 1);

    final attachRows = await dbService.db.query('payment_attachments');
    expect(attachRows.length, 1);

    // Verify physical file is gone
    expect(await expectedFile.exists(), false);
  });
  
  test('Invoice deletion cascades to Payment in DB (but repository must fetch paths to clean files)', () async {
    // This tests the paths helper methods and the ON DELETE CASCADE behavior of SQLite
    final dummySourceFile = File(p.join(tempAttachmentsDir.path, 'source_dummy3.png'));
    await dummySourceFile.writeAsString('dummy png content');

    final payment = Payment(
      id: 'pay_4',
      invoiceId: 'inv_1',
      date: DateTime.now(),
      amount: 50.0,
      method: PaymentMethod.cash,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDirty: true,
    );

    await repository.create(payment, newAttachmentSourcePaths: [dummySourceFile.path]);
    
    // Test helper methods
    final pathsResult = await repository.getAttachmentPathsForInvoice('inv_1');
    expect(pathsResult, isA<Success<List<String>>>());
    expect((pathsResult as Success<List<String>>).value.length, 1);

    // Delete invoice directly in DB to trigger ON DELETE CASCADE
    await dbService.db.delete('invoices', where: 'id = ?', whereArgs: ['inv_1']);

    // Check that payments are gone
    final pRows = await dbService.db.query('payments');
    expect(pRows.length, 0);

    // Check that attachments rows are gone
    final aRows = await dbService.db.query('payment_attachments');
    expect(aRows.length, 0);
  });
}
