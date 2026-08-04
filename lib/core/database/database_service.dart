import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _db;

  DatabaseService(this._db);

  /// Provides access to the underlying sqflite Database instance.
  /// Used by Repositories.
  Database get db {
    if (_db == null || !_db!.isOpen) {
      throw Exception('Database is closed. It must be reopened first.');
    }
    return _db!;
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  Future<void> reopen(String dbPath) async {
    if (_db != null && _db!.isOpen) {
      return;
    }
    _db = await openDatabase(
      dbPath,
      version: null,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Executes a function within an SQLite transaction.
  Future<T> runInTransaction<T>(Future<T> Function(Transaction txn) action) async {
    return await db.transaction(action);
  }
}
