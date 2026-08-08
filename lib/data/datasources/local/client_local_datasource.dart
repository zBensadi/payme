import 'package:sqflite/sqflite.dart';
import '../../models/client_model.dart';

class ClientLocalDataSource {
  final Database _db;

  ClientLocalDataSource(this._db);

  Future<List<ClientModel>> getAllVisible({String? searchQuery}) async {
    String whereClause = 'is_deleted = 0';
    List<Object?> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR phone LIKE ?)';
      final likeQuery = '%${searchQuery.trim()}%';
      whereArgs.addAll([likeQuery, likeQuery]);
    }

    final result = await _db.query(
      'clients',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC', // Phase 4 requirement: Alphabetical by client name
    );

    return result.map((map) => ClientModel.fromMap(map)).toList();
  }

  Future<List<ClientModel>> getAllDeleted({String? searchQuery}) async {
    String whereClause = 'is_deleted = 1';
    List<Object?> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR phone LIKE ?)';
      final likeQuery = '%${searchQuery.trim()}%';
      whereArgs.addAll([likeQuery, likeQuery]);
    }

    final result = await _db.query(
      'clients',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );

    return result.map((map) => ClientModel.fromMap(map)).toList();
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

    return result.map((map) => ClientModel.fromMap(map)).toList();
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
    return result.map((map) => ClientModel.fromMap(map)).toList();
  }

  Future<void> overwriteClient(ClientModel client) async {
    // Explicitly reset dirty flag and update synced_at
    final map = client.toMap();
    map['is_dirty'] = 0;
    map['synced_at'] = client.updatedAt.toUtc().toIso8601String();

    await _db.insert(
      'clients',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
