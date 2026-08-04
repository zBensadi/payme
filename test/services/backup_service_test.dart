import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/error/failures.dart';
import 'package:payme/core/storage/app_paths.dart';
import 'package:payme/core/database/database_service.dart';
import 'package:payme/domain/repositories/backup_repository.dart';
import 'package:payme/services/backup_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async => Directory.systemTemp.path;
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

class MockBackupRepository implements BackupRepository {
  bool failCreateZip = false;
  bool failExtractZip = false;
  bool failAtomicReplace = false;
  List<String>? capturedLivePaths;
  
  // To simulate extracting files without actually using archive package
  Map<String, String>? mockExtractedFiles;

  @override
  Future<Result<void>> atomicReplaceLiveFiles({required List<String> livePaths, required String tempSourceDir}) async {
    if (failAtomicReplace) return Failure(FileSystemFailure('Mock atomic failure'));
    capturedLivePaths = livePaths;
    return Success(null);
  }

  @override
  Future<Result<void>> createZip({required List<String> sourcePaths, required String destinationZipPath}) async {
    if (failCreateZip) return Failure(FileSystemFailure('Mock createZip failure'));
    final file = File(destinationZipPath);
    await file.parent.create(recursive: true);
    await file.writeAsString('mock zip content');
    return Success(null);
  }

  @override
  Future<Result<void>> extractZip({required String zipPath, required String destinationDirPath}) async {
    if (failExtractZip) return Failure(FileSystemFailure('Mock extractZip failure'));
    final dir = Directory(destinationDirPath);
    await dir.create(recursive: true);
    
    if (mockExtractedFiles != null) {
      for (final entry in mockExtractedFiles!.entries) {
        final f = File(p.join(destinationDirPath, entry.key));
        await f.parent.create(recursive: true);
        await f.writeAsString(entry.value);
      }
    }
    return Success(null);
  }
}

void main() {
  late MockBackupRepository mockRepo;
  late DatabaseService dbService;
  late BackupService service;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  setUp(() async {
    mockRepo = MockBackupRepository();
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE app_meta (schema_version INTEGER)');
    await db.insert('app_meta', {'schema_version': 1});
    dbService = DatabaseService(db);
    service = BackupService(mockRepo, dbService);
  });

  tearDown(() async {
    await dbService.close();
  });

  test('createBackup generates correct metadata and triggers zip creation', () async {
    final zipPath = p.join(await AppPaths.getTempPath(), 'test.zip');
    final result = await service.createBackup(zipPath);
    expect(result, isA<Success>());
    
    final file = File(zipPath);
    expect(await file.exists(), isTrue);
  });

  test('restoreBackup rejects if metadata.json is missing', () async {
    final zipPath = p.join(await AppPaths.getTempPath(), 'test.zip');
    mockRepo.mockExtractedFiles = {
      'payme.db': 'data',
    };

    final result = await service.restoreBackup(zipPath);
    expect(result, isA<Failure>());
    expect((result as Failure).failure.message, contains('metadata.json not found'));
  });

  test('restoreBackup rejects if backup schema is newer than current', () async {
    final zipPath = p.join(await AppPaths.getTempPath(), 'test.zip');
    mockRepo.mockExtractedFiles = {
      'metadata.json': jsonEncode({
        'type': 'full',
        'schema_version': 99,
        'manifest': ['payme.db']
      }),
      'payme.db': 'data',
    };

    final result = await service.restoreBackup(zipPath);
    expect(result, isA<Failure>());
    expect((result as Failure).failure.message, contains('schema version (99) is newer'));
  });

  test('restoreBackup rejects if manifest files are missing in extracted dir', () async {
    final zipPath = p.join(await AppPaths.getTempPath(), 'test.zip');
    mockRepo.mockExtractedFiles = {
      'metadata.json': jsonEncode({
        'type': 'full',
        'schema_version': 1,
        'manifest': ['payme.db', 'attachments']
      }),
      // Intentionally missing 'attachments' and 'payme.db'
    };

    final result = await service.restoreBackup(zipPath);
    expect(result, isA<Failure>());
    expect((result as Failure).failure.message, contains('manifested item'));
  });

  test('restoreBackup succeeds when zip is valid and manifest matches', () async {
    final zipPath = p.join(await AppPaths.getTempPath(), 'test.zip');
    mockRepo.mockExtractedFiles = {
      'metadata.json': jsonEncode({
        'type': 'full',
        'schema_version': 1,
        'manifest': ['payme.db', 'attachments', 'logos']
      }),
      'payme.db': 'data',
      'attachments/file1.txt': 'data',
      'logos/logo.png': 'data',
    };

    final result = await service.restoreBackup(zipPath);
    expect(result, isA<Success>());
    expect(mockRepo.capturedLivePaths, isNotNull);
    expect(mockRepo.capturedLivePaths!.length, 3);
  });
}
