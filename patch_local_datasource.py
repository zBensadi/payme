import sys

file_path = "lib/data/datasources/local/client_visibility_local_datasource.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

replacement = """  Future<void> addVisibility(ClientVisibilityModel visibility) async {
    final db = _dbService.db;
    await db.transaction((txn) async {
      await txn.insert(
        'client_user_visibility',
        {
          'client_id': visibility.clientId,
          'user_id': visibility.userId,
          'synced_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Reconciliation: remove any pending deletion tombstone
      await txn.delete(
        'deleted_client_visibilities',
        where: 'client_id = ? AND user_id = ?',
        whereArgs: [visibility.clientId, visibility.userId],
      );
    });
  }

  Future<void> removeVisibility(String clientId, String userId) async {
    final db = _dbService.db;
    await db.transaction((txn) async {
      await txn.delete(
        'client_user_visibility',
        where: 'client_id = ? AND user_id = ?',
        whereArgs: [clientId, userId],
      );
      
      // Idempotency: insert a tombstone
      await txn.insert(
        'deleted_client_visibilities',
        {
          'client_id': clientId,
          'user_id': userId,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
  }
  
  Future<List<Map<String, dynamic>>> getPendingDeletions() async {
    final db = _dbService.db;
    return await db.query('deleted_client_visibilities');
  }
  
  Future<void> clearDeletions(String clientId, String userId) async {
    final db = _dbService.db;
    await db.delete(
      'deleted_client_visibilities',
      where: 'client_id = ? AND user_id = ?',
      whereArgs: [clientId, userId],
    );
  }"""

import re
content = re.sub(r'  Future<void> addVisibility.*?Future<List<ClientVisibilityModel>> getVisibilityForClient', 
                 replacement + '\n\n  Future<List<ClientVisibilityModel>> getVisibilityForClient', 
                 content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
