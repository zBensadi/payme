import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class AppPaths {
  /// Resolves the base application support directory.
  static Future<Directory> getAppSupportDirectory() async {
    if (Platform.isWindows) {
      final appData = await getApplicationSupportDirectory();
      return Directory(p.join(appData.path, AppConstants.appName));
    } else {
      // Android: App-private external storage directory
      final dir = await getExternalStorageDirectory();
      if (dir != null) {
        return dir;
      }
      return getApplicationSupportDirectory();
    }
  }

  static Future<String> getDatabasePath() async {
    final baseDir = await getAppSupportDirectory();
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    return p.join(baseDir.path, AppConstants.databaseName);
  }

  static Future<String> getAttachmentsPath() async {
    final baseDir = await getAppSupportDirectory();
    final dir = Directory(p.join(baseDir.path, AppConstants.attachmentsDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> getLogsPath() async {
    final baseDir = await getAppSupportDirectory();
    final dir = Directory(p.join(baseDir.path, AppConstants.logsDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }
}
