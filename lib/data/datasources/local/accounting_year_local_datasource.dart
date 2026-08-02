import 'package:sqflite/sqflite.dart';
import '../../models/accounting_year_model.dart';

class AccountingYearLocalDataSource {
  final Database _db;

  AccountingYearLocalDataSource(this._db);

  Future<List<AccountingYearModel>> getAll() async {
    final result = await _db.query('accounting_years', orderBy: 'name DESC');
    return result.map((map) => AccountingYearModel.fromMap(map)).toList();
  }

  Future<AccountingYearModel?> getActive() async {
    final result = await _db.query(
      'accounting_years',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AccountingYearModel.fromMap(result.first);
  }

  Future<AccountingYearModel?> getById(String id) async {
    final result = await _db.query(
      'accounting_years',
      where: 'id = ?',
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
      {'name': newName, 'is_dirty': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setActive(String id) async {
    await _db.transaction((txn) async {
      // Ensure we switch active year transactionally
      await txn.update('accounting_years', {'is_active': 0, 'is_dirty': 1});
      await txn.update(
        'accounting_years',
        {'is_active': 1, 'is_dirty': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> delete(String id) async {
    await _db.delete(
      'accounting_years',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
