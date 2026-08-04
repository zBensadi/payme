import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../core/storage/app_paths.dart';

class LogoFileDataSource {
  Future<String> saveLogo(String sourceFilePath, String newFileName) async {
    final logosDirStr = await AppPaths.getLogosPath();
    final sourceFile = File(sourceFilePath);
    
    if (!await sourceFile.exists()) {
      throw Exception('Source file does not exist: $sourceFilePath');
    }

    final destPath = p.join(logosDirStr, newFileName);
    await sourceFile.copy(destPath);
    
    return newFileName;
  }

  Future<void> deleteLogo(String relativeFilePath) async {
    final logosDirStr = await AppPaths.getLogosPath();
    final file = File(p.join(logosDirStr, relativeFilePath));
    
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> getAbsolutePath(String relativeFilePath) async {
    final logosDirStr = await AppPaths.getLogosPath();
    return p.join(logosDirStr, relativeFilePath);
  }
}
