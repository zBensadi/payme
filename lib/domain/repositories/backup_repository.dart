import '../../core/error/result.dart';

abstract class BackupRepository {
  /// Compresses the specified file and directory paths into a single zip archive.
  Future<Result<void>> createZip({
    required List<String> sourcePaths,
    required String destinationZipPath,
  });

  /// Extracts the zip archive into the specified destination directory.
  Future<Result<void>> extractZip({
    required String zipPath,
    required String destinationDirPath,
  });

  /// Performs an atomic replacement of live files.
  /// 
  /// 1. Renames all matching files/directories in [livePaths] to a `.old` extension.
  /// 2. Moves the corresponding files from [tempSourceDir] into the live locations.
  /// 3. If successful, deletes the `.old` backups.
  /// 4. If any step fails, attempts to rollback by restoring the `.old` backups.
  Future<Result<void>> atomicReplaceLiveFiles({
    required List<String> livePaths,
    required String tempSourceDir,
  });
}
