import sys

file_path = "lib/data/repositories_impl/client_visibility_repository_impl.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Add SyncTrigger import
if "import '../../core/sync/sync_trigger.dart';" not in content:
    content = content.replace(
        "import '../../core/sync/sync_result.dart';",
        "import '../../core/sync/sync_result.dart';\nimport '../../core/sync/sync_trigger.dart';"
    )

# 2. Inject SyncTrigger
content = content.replace(
    "final ClientVisibilityRemoteDataSource _remoteDataSource;",
    "final ClientVisibilityRemoteDataSource _remoteDataSource;\n  final SyncTrigger _syncTrigger;"
)
content = content.replace(
    "ClientVisibilityRepositoryImpl(this._localDataSource, this._remoteDataSource);",
    "ClientVisibilityRepositoryImpl(this._localDataSource, this._remoteDataSource, this._syncTrigger);"
)

# 3. Add requestSync
content = content.replace(
    "await _localDataSource.addVisibility(ClientVisibilityModel.fromEntity(visibility));\n\n        _changeController.add(null);",
    "await _localDataSource.addVisibility(ClientVisibilityModel.fromEntity(visibility));\n        _syncTrigger.requestSync(syncDomain);\n        _changeController.add(null);"
)
content = content.replace(
    "await _localDataSource.removeVisibility(clientId, userId);\n\n        _changeController.add(null);",
    "await _localDataSource.removeVisibility(clientId, userId);\n        _syncTrigger.requestSync(syncDomain);\n        _changeController.add(null);"
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

