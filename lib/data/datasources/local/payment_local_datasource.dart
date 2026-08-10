import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../../models/payment_model.dart';
import '../../models/payment_attachment_model.dart';
import '../../../domain/entities/payment.dart';

class PaymentLocalDataSource {
  final DatabaseService _dbService;

  PaymentLocalDataSource(this._dbService);

  Future<List<Payment>> getPaymentsForInvoice(String invoiceId) async {
    final db = _dbService.db;
    final paymentMaps = await db.query(
      'payments',
      where: 'invoice_id = ? AND is_deleted = 0',
      whereArgs: [invoiceId],
      orderBy: 'date DESC, created_at DESC',
    );

    final List<Payment> payments = [];
    for (var map in paymentMaps) {
      final payment = PaymentModel.fromMap(map);
      final attachmentMaps = await db.query(
        'payment_attachments',
        where: 'payment_id = ?',
        whereArgs: [payment.id],
      );
      final attachments = attachmentMaps.map((m) => PaymentAttachmentModel.fromMap(m)).toList();
      payments.add(payment.copyWith(attachments: attachments));
    }
    return payments;
  }

  Future<List<Payment>> getPaymentsByPeriod(String yearId, {DateTime? start, DateTime? end}) async {
    final db = _dbService.db;
    
    String whereClause = 'i.accounting_year_id = ?';
    List<dynamic> whereArgs = [yearId];

    if (start != null) {
      whereClause += ' AND p.date >= ?';
      whereArgs.add(start.toIso8601String());
    }
    if (end != null) {
      whereClause += ' AND p.date <= ?';
      whereArgs.add(end.toIso8601String());
    }

    final paymentMaps = await db.rawQuery('''
      SELECT p.*
      FROM payments p
      JOIN invoices i ON p.invoice_id = i.id
      WHERE $whereClause AND p.is_deleted = 0
      ORDER BY p.date DESC, p.created_at DESC
    ''', whereArgs);

    final List<Payment> payments = [];
    for (var map in paymentMaps) {
      final payment = PaymentModel.fromMap(map);
      // For reports, we might not strictly need attachments, but let's load them to keep Payment entity complete
      final attachmentMaps = await db.query(
        'payment_attachments',
        where: 'payment_id = ?',
        whereArgs: [payment.id],
      );
      final attachments = attachmentMaps.map((m) => PaymentAttachmentModel.fromMap(m)).toList();
      payments.add(payment.copyWith(attachments: attachments));
    }
    return payments;
  }

  Future<Payment?> getById(String id) async {
    final db = _dbService.db;
    final paymentMaps = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (paymentMaps.isEmpty) return null;

    final payment = PaymentModel.fromMap(paymentMaps.first);
    final attachmentMaps = await db.query(
      'payment_attachments',
      where: 'payment_id = ?',
      whereArgs: [id],
    );
    final attachments = attachmentMaps.map((m) => PaymentAttachmentModel.fromMap(m)).toList();
    return payment.copyWith(attachments: attachments);
  }

  Future<Payment> create(Payment payment) async {
    final db = _dbService.db;
    
    await db.transaction((txn) async {
      await txn.insert('payments', PaymentModel.toMap(payment));
      for (final attachment in payment.attachments) {
        await txn.insert('payment_attachments', PaymentAttachmentModel.toMap(attachment));
      }
    });
    
    return payment;
  }

  Future<Payment> update(Payment payment, List<String> deletedAttachmentIds) async {
    final db = _dbService.db;
    
    await db.transaction((txn) async {
      await txn.update(
        'payments',
        PaymentModel.toMap(payment),
        where: 'id = ?',
        whereArgs: [payment.id],
      );
      
      for (final id in deletedAttachmentIds) {
        await txn.delete(
          'payment_attachments',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      
      for (final attachment in payment.attachments) {
        // Only insert if it doesnt exist (we use a simple check, or insert OR IGNORE)
        await txn.insert(
          'payment_attachments',
          PaymentAttachmentModel.toMap(attachment),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });

    return payment;
  }

  Future<void> delete(String id) async {
    final db = _dbService.db;
    await db.update(
      'payments',
      {
        'is_deleted': 1,
        'is_dirty': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Payment>> getDirtyPayments() async {
    final db = _dbService.db;
    final results = await db.query(
      'payments',
      where: 'is_dirty = 1',
    );
    return results.map((e) => PaymentModel.fromMap(e)).toList();
  }

  Future<void> overwritePayment(Payment payment) async {
    final db = _dbService.db;
    final map = PaymentModel.toMap(payment);
    map['is_dirty'] = 0;
    map['synced_at'] = payment.updatedAt.toIso8601String();

    await db.transaction((txn) async {
      await txn.insert(
        'payments',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> updateSyncMetadata(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    
    final db = _dbService.db;
    for (var i = 0; i < ids.length; i += 900) {
      final chunk = ids.skip(i).take(900).toList();
      final placeholders = List.filled(chunk.length, '?').join(',');
      
      await db.update(
        'payments',
        {
          'is_dirty': 0,
          'synced_at': syncedAt.toUtc().toIso8601String(),
        },
        where: 'id IN ($placeholders)',
        whereArgs: chunk,
      );
    }
  }
  
  Future<List<String>> getAttachmentPathsForInvoice(String invoiceId) async {
    final db = _dbService.db;
    final maps = await db.rawQuery('''
      SELECT pa.file_path 
      FROM payment_attachments pa
      JOIN payments p ON pa.payment_id = p.id
      WHERE p.invoice_id = ?
    ''', [invoiceId]);
    return maps.map((m) => m['file_path'] as String).toList();
  }

  Future<List<String>> getAttachmentPathsForYear(String yearId) async {
    final db = _dbService.db;
    final maps = await db.rawQuery('''
      SELECT pa.file_path 
      FROM payment_attachments pa
      JOIN payments p ON pa.payment_id = p.id
      JOIN invoices i ON p.invoice_id = i.id
      WHERE i.accounting_year_id = ?
    ''', [yearId]);
    return maps.map((m) => m['file_path'] as String).toList();
  }
}
