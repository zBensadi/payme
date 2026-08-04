import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../../models/invoice_model.dart';

class InvoiceLocalDataSource {
  final DatabaseService _dbService;

  InvoiceLocalDataSource(this._dbService);

  Future<List<InvoiceModel>> getInvoicesForYear(String accountingYearId) async {
    final db = _dbService.db;
    final results = await db.query(
      'invoices',
      where: 'accounting_year_id = ?',
      whereArgs: [accountingYearId],
      orderBy: 'invoice_number DESC',
    );
    return results.map((e) => InvoiceModel.fromMap(e)).toList();
  }

  Future<List<InvoiceModel>> getInvoicesForClient(String accountingYearId, String clientId) async {
    final db = _dbService.db;
    final results = await db.query(
      'invoices',
      where: 'accounting_year_id = ? AND client_id = ?',
      whereArgs: [accountingYearId, clientId],
      orderBy: 'invoice_number DESC',
    );
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
    await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
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
      {'client_id': newClientId},
      where: 'client_id = ?',
      whereArgs: [oldClientId],
    );
  }

  Future<void> deleteAllForClient(String clientId, {Transaction? txn}) async {
    final executor = txn ?? _dbService.db;
    await executor.delete(
      'invoices',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
  }

  Future<int> countAllForClient(String clientId) async {
    final db = _dbService.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices WHERE client_id = ?',
      [clientId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
