import sys

file_path = "test/features/clients/client_visibility_test.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

imports = """
import 'package:payme/data/datasources/local/client_local_datasource.dart';
import 'package:payme/data/models/client_model.dart';
"""
if "import 'package:payme/data/datasources/local/client_local_datasource.dart';" not in content:
    content = content.replace("import 'package:logger/logger.dart';", "import 'package:logger/logger.dart';\n" + imports)

setup_vars = """
  late Database db;
  late ClientVisibilityLocalDataSource dataSource;
  late ClientLocalDataSource clientDataSource;
"""
content = content.replace("  late Database db;\n  late ClientVisibilityLocalDataSource dataSource;", setup_vars)

setup_init = """
    final dbService = DatabaseService(db);
    dataSource = ClientVisibilityLocalDataSource(dbService);
    clientDataSource = ClientLocalDataSource(dbService);
"""
content = content.replace("    final dbService = DatabaseService(db);\n    dataSource = ClientVisibilityLocalDataSource(dbService);", setup_init)

test_code = """
  group('Client Visibility Sync Blocker Regression Tests', () {
    test('overwriteClient does not cascade delete visibility mapping', () async {
      // 1. Add mapping
      await dataSource.addVisibility(const ClientVisibilityModel(clientId: 'client_A', userId: 'user_B'));
      var visibilities = await dataSource.getVisibilityForClient('client_A');
      expect(visibilities.length, 1);

      // 2. Overwrite client (simulating a sync pull)
      final clientToOverwrite = ClientModel(
        id: 'client_A',
        name: 'Client A Updated',
        visibilityType: 'specific_users',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      await clientDataSource.overwriteClient(clientToOverwrite);

      // 3. Verify visibility mapping still exists
      visibilities = await dataSource.getVisibilityForClient('client_A');
      expect(visibilities.length, 1, reason: 'overwriteClient should not delete child visibility rows');
      expect(visibilities.first.userId, 'user_B');
    });
  });
"""

if "Client Visibility Sync Blocker Regression Tests" not in content:
    content = content + "\n" + test_code

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

