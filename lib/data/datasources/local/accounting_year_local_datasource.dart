import 'package:sqflite/sqflite.dart';
import '../../models/accounting_year_model.dart';

class AccountingYearLocalDataSource {
  final Database _db;

  AccountingYearLocalDataSource(this._db);

  Future<List<AccountingYearModel>> getAll() async {
    final result = await _db.query(
      'accounting_years', 
      where: 'is_deleted = 0',
      orderBy: 'name DESC'
    );
    return result.map((map) => AccountingYearModel.fromMap(map)).toList();
  }

  Future<AccountingYearModel?> getActive() async {
    final result = await _db.query(
      'accounting_years',
      where: 'is_active = ? AND is_deleted = 0',
      whereArgs: [1],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AccountingYearModel.fromMap(result.first);
  }

  Future<AccountingYearModel?> getById(String id) async {
    final result = await _db.query(
      'accounting_years',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AccountingYearModel.fromMap(result.first);
  }

  Future<void> create(AccountingYearModel year) async {
    await _db.insert('accounting_years', year.toMap());
  }

  Future<void> rename(String id, String newName) async {
    await _db.update(
      'accounting_years',
      {
        'name': newName, 
        'is_dirty': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setActive(String id) async {
    await _db.transaction((txn) async {
      final now = DateTime.now().toUtc().toIso8601String();
      await txn.update('accounting_years', {
        'is_active': 0, 
        'is_dirty': 1,
        'updated_at': now,
      });
      await txn.update(
        'accounting_years',
        {
          'is_active': 1, 
          'is_dirty': 1,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> delete(String id) async {
    await _db.update(
      'accounting_years',
      {
        'is_deleted': 1,
        'is_dirty': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<AccountingYearModel>> getDirtyYears() async {
    final results = await _db.query(
      'accounting_years',
      where: 'is_dirty = 1',
    );
    return results.map((e) => AccountingYearModel.fromMap(e)).toList();
  }

  Future<void> overwriteYear(AccountingYearModel year) async {
    final map = year.toMap();
    map['is_dirty'] = 0;
    map['synced_at'] = year.updatedAt.toUtc().toIso8601String();

    await _db.transaction((txn) async {
      if (year.isActive && !year.isDeleted) {
        // Enforce only one active year
        await txn.update('accounting_years', {
          'is_active': 0,
        });
      }

      await txn.insert(
        'accounting_years',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> updateSyncMetadata(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    
    for (var i = 0; i < ids.length; i += 900) {
      final chunk = ids.skip(i).take(900).toList();
      final placeholders = List.filled(chunk.length, '?').join(',');
      
      await _db.update(
        'accounting_years',
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
