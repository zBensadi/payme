import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/client_model.dart';
import '../../../core/database/visibility_sql_builder.dart';

class ClientLocalDataSource {
  final Database _db;

  ClientLocalDataSource(this._db);

  Future<List<ClientModel>> getAllVisible({String? searchQuery, String? visibleToUserId}) async {
    debugPrint('[TRACE-VISIBILITY] ClientLocalDataSource.getAllVisible: visibleToUserId=$visibleToUserId');
    String whereClause = 'is_deleted = 0';
    List<Object?> whereArgs = [];

    if (visibleToUserId != null && visibleToUserId.trim().isNotEmpty) {
      whereClause += VisibilitySqlBuilder.buildVisibilityClause('clients', visibleToUserId);
      whereArgs.add(visibleToUserId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR phone LIKE ? OR rc LIKE ? OR nif LIKE ? OR nis LIKE ? OR art LIKE ?)';
      final likeQuery = '%${searchQuery.trim()}%';
      whereArgs.addAll([likeQuery, likeQuery, likeQuery, likeQuery, likeQuery, likeQuery]);
    }

    final result = await _db.query(
      'clients',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC', // Phase 4 requirement: Alphabetical by client name
    );

    final clients = result.map((map) => ClientModel.fromMap(map)).toList();
    debugPrint('TRACE [${DateTime.now().toIso8601String()}] ClientLocalDataSource.getAllVisible returns: ${clients.map((c) => c.id).toList()}');
    return clients;
  }

  Future<List<ClientModel>> getAllDeleted({String? searchQuery}) async {
    String whereClause = 'is_deleted = 1';
    List<Object?> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR phone LIKE ? OR rc LIKE ? OR nif LIKE ? OR nis LIKE ? OR art LIKE ?)';
      final likeQuery = '%${searchQuery.trim()}%';
      whereArgs.addAll([likeQuery, likeQuery, likeQuery, likeQuery, likeQuery, likeQuery]);
    }

    final result = await _db.query(
      'clients',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );

    final clients = result.map((map) => ClientModel.fromMap(map)).toList();
    debugPrint('TRACE [${DateTime.now().toIso8601String()}] ClientLocalDataSource.getAllVisible returns: ${clients.map((c) => c.id).toList()}');
    return clients;
  }

  Future<ClientModel?> getById(String id) async {
    final result = await _db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ClientModel.fromMap(result.first);
  }

  Future<List<ClientModel>> getByNameAndPhone(String name, String? phone) async {
    String whereClause = 'is_deleted = 0 AND name = ?';
    List<Object?> whereArgs = [name];
    
    if (phone != null && phone.trim().isNotEmpty) {
      whereClause += ' AND phone = ?';
      whereArgs.add(phone.trim());
    } else {
      whereClause += ' AND (phone IS NULL OR phone = \'\')';
    }

    final result = await _db.query(
      'clients',
      where: whereClause,
      whereArgs: whereArgs,
    );

    final clients = result.map((map) => ClientModel.fromMap(map)).toList();
    debugPrint('TRACE [${DateTime.now().toIso8601String()}] ClientLocalDataSource.getAllVisible returns: ${clients.map((c) => c.id).toList()}');
    return clients;
  }

  Future<void> create(ClientModel client) async {
    await _db.insert('clients', client.toMap());
  }

  Future<void> update(ClientModel client) async {
    await _db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> softDelete(String id, {Transaction? txn}) async {
    final executor = txn ?? _db;
    await executor.update(
      'clients',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'is_dirty': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(String id) async {
    await _db.update(
      'clients',
      {
        'is_deleted': 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'is_dirty': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ClientModel>> getDirtyClients() async {
    final result = await _db.query(
      'clients',
      where: 'is_dirty = 1',
    );
    final clients = result.map((map) => ClientModel.fromMap(map)).toList();
    debugPrint('TRACE [${DateTime.now().toIso8601String()}] ClientLocalDataSource.getAllVisible returns: ${clients.map((c) => c.id).toList()}');
    return clients;
  }

  Future<void> overwriteClient(ClientModel client) async {
    debugPrint('[TRACE-VISIBILITY] ClientLocalDataSource.overwriteClient(${client.id})');
    // Explicitly reset dirty flag and update synced_at
    final map = client.toMap();
    map['is_dirty'] = 0;
    map['synced_at'] = client.updatedAt.toUtc().toIso8601String();

    final count = await _db.update(
      'clients',
      map,
      where: 'id = ?',
      whereArgs: [client.id],
    );

    if (count == 0) {
      await _db.insert('clients', map);
    }
    final postOverwrite = await _db.rawQuery('SELECT * FROM client_user_visibility WHERE client_id = ?', [client.id]);
    debugPrint('[TRACE-VISIBILITY] SQLite visibility rows after overwriteClient: $postOverwrite');
  }

  Future<void> updateSyncMetadata(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    
    // SQLite limits variables, so process in chunks if necessary
    for (var i = 0; i < ids.length; i += 900) {
      final chunk = ids.skip(i).take(900).toList();
      final placeholders = List.filled(chunk.length, '?').join(',');
      
      await _db.update(
        'clients',
        {
          'is_dirty': 0,
          'synced_at': syncedAt.toUtc().toIso8601String(),
        },
        where: 'id IN ($placeholders)',
        whereArgs: chunk,
      );
    }
  }
}
