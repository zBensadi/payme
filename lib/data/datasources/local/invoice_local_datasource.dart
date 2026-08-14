import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/visibility_sql_builder.dart';
import '../../models/invoice_model.dart';

class InvoiceLocalDataSource {
  final DatabaseService _dbService;

  InvoiceLocalDataSource(this._dbService);

  Future<List<InvoiceModel>> getInvoicesForYear(String accountingYearId, {String? visibleToUserId}) async {
    final db = _dbService.db;
    
    String query = 'SELECT invoices.* FROM invoices';
    List<Object?> args = [accountingYearId];
    String where = 'invoices.accounting_year_id = ? AND invoices.is_deleted = 0';

    if (visibleToUserId != null && visibleToUserId.isNotEmpty) {
      query += ' INNER JOIN clients ON invoices.client_id = clients.id';
      where += VisibilitySqlBuilder.buildVisibilityClause('clients', visibleToUserId);
      args.add(visibleToUserId);
    }

    query += ' WHERE $where ORDER BY invoices.invoice_number DESC';

    final results = await db.rawQuery(query, args);
    return results.map((e) => InvoiceModel.fromMap(e)).toList();
  }

  Future<List<InvoiceModel>> getInvoicesForClient(String accountingYearId, String clientId, {String? visibleToUserId}) async {
    final db = _dbService.db;
    
    String query = 'SELECT invoices.* FROM invoices';
    List<Object?> args = [accountingYearId, clientId];
    String where = 'invoices.accounting_year_id = ? AND invoices.client_id = ? AND invoices.is_deleted = 0';

    if (visibleToUserId != null && visibleToUserId.isNotEmpty) {
      query += ' INNER JOIN clients ON invoices.client_id = clients.id';
      where += VisibilitySqlBuilder.buildVisibilityClause('clients', visibleToUserId);
      args.add(visibleToUserId);
    }

    query += ' WHERE $where ORDER BY invoices.invoice_number DESC';

    final results = await db.rawQuery(query, args);
    return results.map((e) => InvoiceModel.fromMap(e)).toList();
  }

  Future<InvoiceModel?> getById(String id) async {
    final db = _dbService.db;
    final results = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return InvoiceModel.fromMap(results.first);
  }

  Future<InvoiceModel> create(InvoiceModel invoice) async {
    final db = _dbService.db;
    await db.transaction((txn) async {
      // 1. Insert the invoice
      await txn.insert('invoices', invoice.toMap());
      
      // 2. Upsert the invoice sequence tracking table
      await txn.insert(
        'invoice_sequences',
        {
          'accounting_year_id': invoice.accountingYearId,
          'last_invoice_number': invoice.invoiceNumber,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    return invoice;
  }

  Future<InvoiceModel> update(InvoiceModel invoice) async {
    final db = _dbService.db;
    await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
    return invoice;
  }

  Future<void> delete(String id) async {
    final db = _dbService.db;
    await db.update(
      'invoices',
      {
        'is_deleted': 1,
        'is_dirty': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<InvoiceModel>> getDirtyInvoices() async {
    final db = _dbService.db;
    final results = await db.query(
      'invoices',
      where: 'is_dirty = 1',
    );
    return results.map((e) => InvoiceModel.fromMap(e)).toList();
  }

  Future<void> overwriteInvoice(InvoiceModel invoice) async {
    final db = _dbService.db;
    final map = invoice.toMap();
    map['is_dirty'] = 0;
    map['synced_at'] = invoice.updatedAt;

    await db.transaction((txn) async {
      await txn.insert(
        'invoices',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final seqResults = await txn.query(
        'invoice_sequences',
        columns: ['last_invoice_number'],
        where: 'accounting_year_id = ?',
        whereArgs: [invoice.accountingYearId],
      );

      int currentMax = 0;
      if (seqResults.isNotEmpty) {
        currentMax = seqResults.first['last_invoice_number'] as int;
      }

      if (invoice.invoiceNumber > currentMax) {
        await txn.insert(
          'invoice_sequences',
          {
            'accounting_year_id': invoice.accountingYearId,
            'last_invoice_number': invoice.invoiceNumber,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> updateSyncMetadata(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    
    final db = _dbService.db;
    for (var i = 0; i < ids.length; i += 900) {
      final chunk = ids.skip(i).take(900).toList();
      final placeholders = List.filled(chunk.length, '?').join(',');
      
      await db.update(
        'invoices',
        {
          'is_dirty': 0,
          'synced_at': syncedAt.toUtc().toIso8601String(),
        },
        where: 'id IN ($placeholders)',
        whereArgs: chunk,
      );
    }
  }

  Future<int> getHighestInvoiceNumber(String accountingYearId) async {
    final db = _dbService.db;
    final results = await db.query(
      'invoice_sequences',
      columns: ['last_invoice_number'],
      where: 'accounting_year_id = ?',
      whereArgs: [accountingYearId],
      limit: 1,
    );
    
    if (results.isEmpty) return 0;
    return results.first['last_invoice_number'] as int;
  }

  Future<void> transferInvoicesToClient(String oldClientId, String newClientId, {Transaction? txn}) async {
    final executor = txn ?? _dbService.db;
    await executor.update(
      'invoices',
      {
        'client_id': newClientId,
        'is_dirty': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'client_id = ?',
      whereArgs: [oldClientId],
    );
  }

  Future<void> deleteAllForClient(String clientId, {Transaction? txn}) async {
    final executor = txn ?? _dbService.db;
    await executor.update(
      'invoices',
      {
        'is_deleted': 1,
        'is_dirty': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
  }

  Future<int> countAllForClient(String clientId) async {
    final db = _dbService.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices WHERE client_id = ? AND is_deleted = 0',
      [clientId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countAllForYear(String accountingYearId) async {
    final db = _dbService.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices WHERE accounting_year_id = ? AND is_deleted = 0',
      [accountingYearId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
