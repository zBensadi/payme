import sys

def patch_file(path, replacements):
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
            
        modified = False
        for old_text, new_text in replacements:
            if old_text in content:
                content = content.replace(old_text, new_text)
                modified = True
                print(f"Patched '{old_text[:30]}...' in {path}")
            else:
                print(f"Failed to find '{old_text[:30]}...' in {path}")
                
        if modified:
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
    except Exception as e:
        print(f"Error processing {path}: {e}")

# 1. ClientFormController
patch_file("lib/presentation/features/clients/controllers/client_form_controller.dart", [
    (
        "  Future<bool> _executeSave(Client client, ClientFormState formState) async {",
        "  Future<bool> _executeSave(Client client, ClientFormState formState) async {\n    print('[TRACE-VISIBILITY-TEST] ===== SAVE START =====');\n    print('[TRACE-VISIBILITY] ClientFormController._executeSave: clientId=${client.id.isEmpty ? \"NEW\" : client.id}, businessId=${client.businessId}, visibilityType=${formState.visibilityType}, selectedUserIds=${formState.selectedUserIds}');"
    ),
    (
        "    if (finalClient.id.isEmpty) {\n      final newClient = finalClient.copyWith(\n        id: IdGenerator.generateUniqueId(),\n        createdAt: DateTime.now().toUtc(),\n      );\n      result = await repo.create(newClient);\n    } else {\n      result = await repo.update(finalClient);\n    }",
        "    if (finalClient.id.isEmpty) {\n      final newClient = finalClient.copyWith(\n        id: IdGenerator.generateUniqueId(),\n        createdAt: DateTime.now().toUtc(),\n      );\n      result = await repo.create(newClient);\n    } else {\n      result = await repo.update(finalClient);\n    }\n    print('[TRACE-VISIBILITY] ClientRepository create/update result: ${result is Success}');"
    ),
    (
        "           state = AsyncData(formState);\n           ref.invalidate(clientListControllerProvider);\n           return true;\n         }(),",
        "           state = AsyncData(formState);\n           ref.invalidate(clientListControllerProvider);\n           print('[TRACE-VISIBILITY-TEST] ===== SAVE END =====');\n           return true;\n         }(),"
    )
])

# 2. ClientVisibilityLocalDataSource
patch_file("lib/data/datasources/local/client_visibility_local_datasource.dart", [
    (
        "  Future<void> addVisibility(ClientVisibilityModel visibility) async {",
        "  Future<void> addVisibility(ClientVisibilityModel visibility) async {\n    print('[TRACE-VISIBILITY] ClientVisibilityLocalDataSource.addVisibility: ${visibility.clientId} -> ${visibility.userId}');"
    ),
    (
        "        // Reconciliation: remove any pending deletion tombstone\n        await txn.delete(\n          'deleted_client_visibilities',\n          where: 'client_id = ? AND user_id = ?',\n          whereArgs: [visibility.clientId, visibility.userId],\n        );\n      });\n    }",
        "        // Reconciliation: remove any pending deletion tombstone\n        await txn.delete(\n          'deleted_client_visibilities',\n          where: 'client_id = ? AND user_id = ?',\n          whereArgs: [visibility.clientId, visibility.userId],\n        );\n      });\n      final postInsert = await db.rawQuery('SELECT * FROM client_user_visibility WHERE client_id = ? AND user_id = ?', [visibility.clientId, visibility.userId]);\n      print('[TRACE-VISIBILITY] ClientVisibilityLocalDataSource.addVisibility resulting SQLite row: $postInsert');\n    }"
    )
])

# 3. ClientVisibilityRepositoryImpl
patch_file("lib/data/repositories_impl/client_visibility_repository_impl.dart", [
    (
        "      await _localDataSource.addVisibility(ClientVisibilityModel.fromEntity(visibility));\n      _syncTrigger.requestSync(syncDomain);\n      _changeController.add(null);\n\n      return const Success(null);",
        "      await _localDataSource.addVisibility(ClientVisibilityModel.fromEntity(visibility));\n      print('[TRACE-VISIBILITY] ClientVisibilityRepositoryImpl.addVisibility: requestSync(SyncDomain.clientVisibility)');\n      _syncTrigger.requestSync(syncDomain);\n      _changeController.add(null);\n\n      return const Success(null);"
    )
])

# 4. SyncTrigger
patch_file("lib/core/sync/sync_trigger.dart", [
    (
        "  void requestSync([SyncDomain? domain]) {",
        "  void requestSync([SyncDomain? domain]) {\n    print('[TRACE-VISIBILITY] SyncTrigger.requestSync: $domain');"
    )
])

# 5. SyncService
patch_file("lib/core/sync/sync_service.dart", [
    (
        "  Future<void> _executeSyncCycle(Set<SyncDomain> domains) async {",
        "  Future<void> _executeSyncCycle(Set<SyncDomain> domains) async {\n    print('[TRACE-VISIBILITY] SyncService._executeSyncCycle processing domains: $domains');"
    )
])

# 6. ClientRemoteDataSource
patch_file("lib/data/datasources/remote/client_remote_datasource.dart", [
    (
        "  Future<void> pushClients(String businessId, List<ClientModel> clients) async {",
        "  Future<void> pushClients(String businessId, List<ClientModel> clients) async {\n    print('[TRACE-VISIBILITY] ClientRemoteDataSource.pushClients: ${clients.map((c) => c.id).toList()}');"
    ),
    (
        "  Future<List<ClientModel>> getModifiedSince(String businessId, DateTime? since) async {",
        "  Future<List<ClientModel>> getModifiedSince(String businessId, DateTime? since) async {\n    print('[TRACE-VISIBILITY] ClientRemoteDataSource.getModifiedSince($since)');"
    )
])

# 7. ClientVisibilityRemoteDataSource
patch_file("lib/data/datasources/remote/client_visibility_remote_datasource.dart", [
    (
        "  Future<void> pushVisibilities(String businessId, List<ClientVisibilityModel> visibilities) async {",
        "  Future<void> pushVisibilities(String businessId, List<ClientVisibilityModel> visibilities) async {\n    print('[TRACE-VISIBILITY] ClientVisibilityRemoteDataSource.pushVisibilities: ${visibilities.map((e) => e.clientId + \"_\" + e.userId).toList()}');\n    for (var v in visibilities) {\n      print('[TRACE-VISIBILITY] Firestore path: businesses/$businessId/client_visibility/${v.clientId}_${v.userId}');\n    }"
    ),
    (
        "  Future<List<ClientVisibilityModel>> getModifiedSince(String businessId, DateTime? since) async {",
        "  Future<List<ClientVisibilityModel>> getModifiedSince(String businessId, DateTime? since) async {\n    print('[TRACE-VISIBILITY] ClientVisibilityRemoteDataSource.getModifiedSince($since)');"
    )
])

# 8. ClientLocalDataSource
patch_file("lib/data/datasources/local/client_local_datasource.dart", [
    (
        "  Future<void> overwriteClient(ClientModel client) async {",
        "  Future<void> overwriteClient(ClientModel client) async {\n    print('[TRACE-VISIBILITY] ClientLocalDataSource.overwriteClient(${client.id})');"
    ),
    (
        "    if (count == 0) {\n      await _db.insert('clients', map);\n    }\n  }",
        "    if (count == 0) {\n      await _db.insert('clients', map);\n    }\n    final postOverwrite = await _db.rawQuery('SELECT * FROM client_user_visibility WHERE client_id = ?', [client.id]);\n    print('[TRACE-VISIBILITY] SQLite visibility rows after overwriteClient: $postOverwrite');\n  }"
    ),
    (
        "  Future<List<ClientModel>> getAllVisible({String? searchQuery, String? visibleToUserId}) async {",
        "  Future<List<ClientModel>> getAllVisible({String? searchQuery, String? visibleToUserId}) async {\n    print('[TRACE-VISIBILITY] ClientLocalDataSource.getAllVisible: visibleToUserId=$visibleToUserId');"
    ),
    (
        "    final clients = result.map((map) => ClientModel.fromMap(map)).toList();\n    return clients;\n  }",
        "    final clients = result.map((map) => ClientModel.fromMap(map)).toList();\n    print('[TRACE-VISIBILITY] Final visible client IDs: ${clients.map((c) => c.id).toList()}');\n    return clients;\n  }"
    )
])

# 9. ClientForm (UI Trace)
patch_file("lib/presentation/features/clients/widgets/client_form.dart", [
    (
        "                          children: formState.selectedUserIds.map((id) {\n                            final user = usersAsync.valueOrNull?.where((u) => u.uid == id).firstOrNull;",
        "                          children: formState.selectedUserIds.map((id) {\n                            final user = usersAsync.valueOrNull?.where((u) => u.uid == id).firstOrNull;\n                            print('[TRACE-VISIBILITY] UI Chip mapping: selectedUserId=$id, totalUsers=${usersAsync.valueOrNull?.length}, matchedUserUid=${user?.uid}, displayName=${user?.displayName}, email=${user?.email}');"
    )
])

