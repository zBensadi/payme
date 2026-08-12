import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/app_user_model.dart';

class UserLocalDataSource {
  final Database _db;

  UserLocalDataSource(this._db);

  Future<List<AppUserModel>> getAll() async {
    final result = await _db.query('users', where: 'is_deleted = 0', orderBy: 'email ASC');
    return result.map((map) => AppUserModel.fromMap(map)).toList();
  }

  Future<AppUserModel?> getById(String id) async {
    final result = await _db.query(
      'users',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    debugPrint('[TRACE-businessId] UserLocalDataSource.getById() -> SQLite row business_id=${result.first['business_id']}');
    return AppUserModel.fromMap(result.first);
  }

  Future<void> create(AppUserModel user) async {
    await _db.insert('users', user.toMap());
  }

  Future<void> update(AppUserModel user) async {
    await _db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.uid],
    );
  }

  Future<void> delete(String id) async {
    await _db.update(
      'users',
      {
        'is_deleted': 1,
        'is_dirty': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<AppUserModel>> getDirtyUsers() async {
    final results = await _db.query(
      'users',
      where: 'is_dirty = 1',
    );
    return results.map((e) => AppUserModel.fromMap(e)).toList();
  }

  Future<void> overwriteUser(AppUserModel user) async {
    final map = user.toMap();
    map['is_dirty'] = 0;
    map['synced_at'] = user.updatedAt.toUtc().toIso8601String();

    debugPrint('[TRACE-businessId] UserLocalDataSource.overwriteUser() -> inserting map with business_id=${map['business_id']}');
    await _db.insert(
      'users',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSyncMetadata(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    
    for (var i = 0; i < ids.length; i += 900) {
      final chunk = ids.skip(i).take(900).toList();
      final placeholders = List.filled(chunk.length, '?').join(',');
      
      await _db.update(
        'users',
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
