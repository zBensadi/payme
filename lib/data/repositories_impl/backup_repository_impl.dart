import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import '../../core/error/result.dart';
import '../../core/error/failures.dart';
import '../../domain/repositories/backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  @override
  Future<Result<void>> createZip({
    required List<String> sourcePaths,
    required String destinationZipPath,
  }) async {
    try {
      final encoder = ZipFileEncoder();
      encoder.create(destinationZipPath);
      
      for (final path in sourcePaths) {
        final entity = FileSystemEntity.typeSync(path);
        if (entity == FileSystemEntityType.file) {
          encoder.addFile(File(path));
        } else if (entity == FileSystemEntityType.directory) {
          // Add directory and its contents
          encoder.addDirectory(Directory(path));
        }
      }
      
      encoder.close();
      return Success(null);
    } catch (e) {
      return Failure(FileSystemFailure('Failed to create ZIP archive: $e'));
    }
  }

  @override
  Future<Result<void>> extractZip({
    required String zipPath,
    required String destinationDirPath,
  }) async {
    try {
      final destDir = Directory(destinationDirPath);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      
      extractFileToDisk(zipPath, destinationDirPath);
      return Success(null);
    } catch (e) {
      return Failure(FileSystemFailure('Failed to extract ZIP archive: $e'));
    }
  }

  @override
  Future<Result<void>> atomicReplaceLiveFiles({
    required List<String> livePaths,
    required String tempSourceDir,
  }) async {
    final List<Map<String, String>> renamedBackups = [];

    try {
      // Step 1: Rename live files/directories to .old
      for (final livePath in livePaths) {
        if (FileSystemEntity.typeSync(livePath) != FileSystemEntityType.notFound) {
          final backupPath = '$livePath.old';
          
          // Delete old backup if it somehow exists
          if (FileSystemEntity.typeSync(backupPath) != FileSystemEntityType.notFound) {
            final oldEntity = FileSystemEntity.isDirectorySync(backupPath) 
                ? Directory(backupPath) 
                : File(backupPath);
            await oldEntity.delete(recursive: true);
          }

          final entity = FileSystemEntity.isDirectorySync(livePath) 
              ? Directory(livePath) 
              : File(livePath);
              
          await entity.rename(backupPath);
          renamedBackups.add({'live': livePath, 'backup': backupPath});
        }
      }

      // Step 2: Move files from temp to live
      for (final livePath in livePaths) {
        final filename = p.basename(livePath);
        final tempPath = p.join(tempSourceDir, filename);
        
        if (FileSystemEntity.typeSync(tempPath) != FileSystemEntityType.notFound) {
          final tempEntity = FileSystemEntity.isDirectorySync(tempPath) 
              ? Directory(tempPath) 
              : File(tempPath);
              
          // Ensure parent directory exists before renaming
          final parentDir = Directory(p.dirname(livePath));
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
          
          await tempEntity.rename(livePath);
        }
      }

      // Step 3: Delete the .old backups
      for (final backup in renamedBackups) {
        final backupPath = backup['backup']!;
        if (FileSystemEntity.typeSync(backupPath) != FileSystemEntityType.notFound) {
          final oldEntity = FileSystemEntity.isDirectorySync(backupPath) 
              ? Directory(backupPath) 
              : File(backupPath);
          await oldEntity.delete(recursive: true);
        }
      }

      return Success(null);

    } catch (e) {
      // Step 4: Rollback - delete whatever we just moved, and restore the .old
      for (final livePath in livePaths) {
        if (FileSystemEntity.typeSync(livePath) != FileSystemEntityType.notFound) {
          final newEntity = FileSystemEntity.isDirectorySync(livePath) 
              ? Directory(livePath) 
              : File(livePath);
          await newEntity.delete(recursive: true);
        }
      }
      
      for (final backup in renamedBackups) {
        final livePath = backup['live']!;
        final backupPath = backup['backup']!;
        
        if (FileSystemEntity.typeSync(backupPath) != FileSystemEntityType.notFound) {
          final oldEntity = FileSystemEntity.isDirectorySync(backupPath) 
              ? Directory(backupPath) 
              : File(backupPath);
          await oldEntity.rename(livePath);
        }
      }

      return Failure(FileSystemFailure('Atomic replacement failed, rolled back: $e'));
    }
  }
}
