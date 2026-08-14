import sys

# 1. Instrument SyncTrigger
file = "lib/core/sync/sync_trigger.dart"
with open(file, "r", encoding="utf-8") as f:
    content = f.read()
if "TRACE:" not in content:
    content = content.replace(
        "void requestSync([SyncDomain? domain]) {",
        "void requestSync([SyncDomain? domain]) {\n    print('TRACE [${DateTime.now().toIso8601String()}] SyncTrigger.requestSync: $domain');"
    )
    with open(file, "w", encoding="utf-8") as f:
        f.write(content)

# 2. Instrument SyncService
file = "lib/core/sync/sync_service.dart"
with open(file, "r", encoding="utf-8") as f:
    content = f.read()
if "TRACE:" not in content:
    content = content.replace(
        "Future<void> _executeSync(Set<SyncDomain> domains) async {",
        "Future<void> _executeSync(Set<SyncDomain> domains) async {\n    print('TRACE [${DateTime.now().toIso8601String()}] SyncService._executeSync started for domains: $domains');"
    )
    with open(file, "w", encoding="utf-8") as f:
        f.write(content)

# 3. Instrument ClientLocalDataSource
file = "lib/data/datasources/local/client_local_datasource.dart"
with open(file, "r", encoding="utf-8") as f:
    content = f.read()
if "TRACE:" not in content:
    content = content.replace(
        "if (count == 0) {\n      await _db.insert('clients', map);\n    }",
        "if (count == 0) {\n      await _db.insert('clients', map);\n    }\n    final postOverwrite = await _db.rawQuery('SELECT * FROM client_user_visibility WHERE client_id = ?', [client.id]);\n    print('TRACE [${DateTime.now().toIso8601String()}] ClientLocalDataSource.overwriteClient(${client.id}) UPDATE count: $count, client_user_visibility rows: ${postOverwrite.length}');"
    )
    content = content.replace(
        "Future<List<ClientModel>> getAllVisible(String businessId, String visibleToUserId) async {",
        "Future<List<ClientModel>> getAllVisible(String businessId, String visibleToUserId) async {\n    print('TRACE [${DateTime.now().toIso8601String()}] ClientLocalDataSource.getAllVisible: businessId=$businessId, visibleToUserId=$visibleToUserId');"
    )
    content = content.replace(
        "return result.map((map) => ClientModel.fromMap(map)).toList();",
        "final clients = result.map((map) => ClientModel.fromMap(map)).toList();\n    print('TRACE [${DateTime.now().toIso8601String()}] ClientLocalDataSource.getAllVisible returns: ${clients.map((c) => c.id).toList()}');\n    return clients;"
    )
    with open(file, "w", encoding="utf-8") as f:
        f.write(content)

# 4. Instrument ClientVisibilityRepositoryImpl
file = "lib/data/repositories_impl/client_visibility_repository_impl.dart"
with open(file, "r", encoding="utf-8") as f:
    content = f.read()
if "TRACE:" not in content:
    content = content.replace(
        "await _localDataSource.addVisibility(ClientVisibilityModel.fromEntity(visibility));",
        "await _localDataSource.addVisibility(ClientVisibilityModel.fromEntity(visibility));\n      print('TRACE [${DateTime.now().toIso8601String()}] ClientVisibilityRepositoryImpl.addVisibility: ${visibility.clientId} -> ${visibility.userId}');"
    )
    with open(file, "w", encoding="utf-8") as f:
        f.write(content)

