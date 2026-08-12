import 'package:sqflite/sqflite.dart';
import '../../models/user_role_model.dart';

class RoleLocalDataSource {
  final Database _db;

  RoleLocalDataSource(this._db);

  Future<List<UserRoleModel>> getAll() async {
    final result = await _db.query('roles', where: 'is_deleted = 0', orderBy: 'name ASC');
    return result.map((map) => UserRoleModel.fromMap(map)).toList();
  }

  Future<UserRoleModel?> getById(String id) async {
    final result = await _db.query(
      'roles',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return UserRoleModel.fromMap(result.first);
  }

  Future<void> create(UserRoleModel role) async {
    await _db.insert('roles', role.toMap());
  }

  Future<void> update(UserRoleModel role) async {
    await _db.update(
      'roles',
      role.toMap(),
      where: 'id = ?',
      whereArgs: [role.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.update(
      'roles',
      {
        'is_deleted': 1,
        'is_dirty': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<UserRoleModel>> getDirtyRoles() async {
    final results = await _db.query(
      'roles',
      where: 'is_dirty = 1',
    );
    return results.map((e) => UserRoleModel.fromMap(e)).toList();
  }

  Future<void> overwriteRole(UserRoleModel role) async {
    final map = role.toMap();
    map['is_dirty'] = 0;
    map['synced_at'] = role.updatedAt.toUtc().toIso8601String();

    await _db.insert(
      'roles',
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
        'roles',
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
