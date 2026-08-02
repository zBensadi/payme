import 'package:sqflite/sqflite.dart';

class DatabaseService {
  final Database _db;

  DatabaseService(this._db);

  /// Provides access to the underlying sqflite Database instance.
  /// Used by Repositories.
  Database get db => _db;
}
