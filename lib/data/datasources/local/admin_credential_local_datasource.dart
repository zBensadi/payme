import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';

final adminCredentialDataSourceProvider = Provider((ref) {
  final dbService = ref.watch(databaseProvider);
  return AdminCredentialLocalDataSource(dbService.db);
});

class AdminCredentialLocalDataSource {
  final Database _db;

  AdminCredentialLocalDataSource(this._db);

  /// Retrieves the admin credential row if it exists.
  Future<Map<String, dynamic>?> getCredential() async {
    final result = await _db.query('admin_credential', limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  /// Replaces the current admin credential with the new one.
  Future<void> saveCredential({
    required String passwordHash,
    required String passwordSalt,
    required String recoveryKeyHash,
    required String recoveryKeySalt,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    
    await _db.transaction((txn) async {
      await txn.delete('admin_credential');
      await txn.insert('admin_credential', {
        'id': 1,
        'password_hash': passwordHash,
        'password_salt': passwordSalt,
        'recovery_key_hash': recoveryKeyHash,
        'recovery_key_salt': recoveryKeySalt,
        'updated_at': now,
      });
    });
  }

  /// Checks if any business data (clients, invoices, or accounting years) exists.
  /// Used to determine if a missing admin credential indicates a fresh install or data corruption.
  Future<bool> hasBusinessData() async {
    final clients = await _db.query('clients', limit: 1);
    if (clients.isNotEmpty) return true;
    
    final invoices = await _db.query('invoices', limit: 1);
    if (invoices.isNotEmpty) return true;
    
    final years = await _db.query('accounting_years', limit: 1);
    if (years.isNotEmpty) return true;

    return false;
  }
}
