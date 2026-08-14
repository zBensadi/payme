import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../../models/client_visibility_model.dart';

class ClientVisibilityLocalDataSource {
  final DatabaseService _dbService;

  ClientVisibilityLocalDataSource(this._dbService);

  Future<void> addVisibility(ClientVisibilityModel visibility) async {
    print('[TRACE-VISIBILITY] ClientVisibilityLocalDataSource.addVisibility: ${visibility.clientId} -> ${visibility.userId}');
    print('TRACE [${DateTime.now().toIso8601String()}] ClientVisibilityLocalDataSource.addVisibility: ${visibility.clientId} -> ${visibility.userId}');
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
    final postInsert = await db.rawQuery('SELECT * FROM client_user_visibility WHERE client_id = ? AND user_id = ?', [visibility.clientId, visibility.userId]);
    print('[TRACE-VISIBILITY] ClientVisibilityLocalDataSource.addVisibility resulting SQLite row: $postInsert');
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
  }

  Future<List<ClientVisibilityModel>> getVisibilityForClient(String clientId) async {
    final db = _dbService.db;
    final results = await db.query(
      'client_user_visibility',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
    return results.map((e) => ClientVisibilityModel.fromMap(e)).toList();
  }

  Future<List<ClientVisibilityModel>> getAllVisibility() async {
    final db = _dbService.db;
    final results = await db.query('client_user_visibility');
    return results.map((e) => ClientVisibilityModel.fromMap(e)).toList();
  }

  // Get all missing local synced_at (needs push)
  Future<List<ClientVisibilityModel>> getUnsyncedVisibility() async {
    final db = _dbService.db;
    final results = await db.query(
      'client_user_visibility',
      where: 'synced_at IS NULL',
    );
    return results.map((e) => ClientVisibilityModel.fromMap(e)).toList();
  }

  Future<void> updateSyncMetadata(String clientId, String userId, DateTime syncedAt) async {
    final db = _dbService.db;
    await db.update(
      'client_user_visibility',
      {
        'synced_at': syncedAt.toUtc().toIso8601String(),
      },
      where: 'client_id = ? AND user_id = ?',
      whereArgs: [clientId, userId],
    );
  }

  Future<void> overwriteVisibility(ClientVisibilityModel visibility) async {
    final db = _dbService.db;
    await db.insert(
      'client_user_visibility',
      visibility.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
