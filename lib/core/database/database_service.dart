import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../storage/app_paths.dart';

class AppMeta {
  final int schemaVersion;
  final String? currentBusinessId;
  final String? currentUid;

  AppMeta({
    required this.schemaVersion,
    this.currentBusinessId,
    this.currentUid,
  });

  factory AppMeta.fromMap(Map<String, dynamic> map) {
    return AppMeta(
      schemaVersion: map['schema_version'] as int,
      currentBusinessId: map['current_business_id'] as String?,
      currentUid: map['current_uid'] as String?,
    );
  }
}

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

  Future<AppMeta?> getAppMeta() async {
    final results = await db.query('app_meta', limit: 1);
    if (results.isEmpty) return null;
    return AppMeta.fromMap(results.first);
  }

  Future<void> updateAppMeta({String? businessId, String? uid}) async {
    await db.update(
      'app_meta',
      {
        'current_business_id': businessId,
        'current_uid': uid,
      },
      where: 'id = 1',
    );
  }

  Future<int> getTotalDirtyCount() async {
    int total = 0;
    // Exclude 'roles' from dirty count, as v12 explicitly inserts the system owner role.
    // Exclude 'users' and 'business_settings' as they are also initialized early or during bootstrap.
    final tables = [
      'clients',
      'invoices',
      'payments',
      'accounting_years',
    ];
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table WHERE is_dirty = 1');
      if (result.isNotEmpty) {
        total += (result.first['count'] as int?) ?? 0;
      }
    }
    return total;
  }

  Future<bool> hasAnyDomainData() async {
    // Only count pure user-generated domain tables to determine if the DB belongs
    // to an existing business. Do NOT count roles, users, or business_settings, 
    // as these are populated by schema migrations or the bootstrap process itself.
    final tables = [
      'clients',
      'invoices',
      'payments',
      'accounting_years',
    ];
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      if (result.isNotEmpty) {
        final count = (result.first['count'] as int?) ?? 0;
        if (count > 0) return true;
      }
    }
    return false;
  }

  Future<void> wipeAndClose() async {
    if (_db != null && _db!.isOpen) {
      final dbPath = _db!.path;
      await _db!.close();
      _db = null;

      // Delete the database file
      try {
        await deleteDatabase(dbPath);
      } catch (e) {
        debugPrint('Error deleting database file: $e');
      }
    }

    // Delete business-specific attachment and logo directories
    try {
      final attachmentsPath = await AppPaths.getAttachmentsPath();
      final attachmentsDir = Directory(attachmentsPath);
      if (await attachmentsDir.exists()) {
        await attachmentsDir.delete(recursive: true);
      }

      final logosPath = await AppPaths.getLogosPath();
      final logosDir = Directory(logosPath);
      if (await logosDir.exists()) {
        await logosDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error deleting attachment/logo directories: $e');
    }
  }
}
