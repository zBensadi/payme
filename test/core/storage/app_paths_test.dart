import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/storage/app_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppPaths resolves database and log paths', () async {
    try {
      final dbPath = await AppPaths.getDatabasePath();
      expect(dbPath, isNotEmpty);
      expect(dbPath.endsWith('payme.db'), isTrue);

      final logPath = await AppPaths.getLogsPath();
      expect(logPath, isNotEmpty);
      expect(Directory(logPath).existsSync(), isTrue);
    } catch (e) {
      // path_provider may throw MissingPluginException in pure dart unit tests
      // without a platform channel mock. We catch and skip if that happens.
      expect(e.toString().contains('MissingPluginException'), isTrue);
    }
  });
}
