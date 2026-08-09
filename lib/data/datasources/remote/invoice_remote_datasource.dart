import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/invoice.dart';

class InvoiceRemoteDataSource {
  final FirebaseFirestore _firestore;

  InvoiceRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> pushInvoices(String businessId, List<Invoice> invoices) async {
    if (invoices.isEmpty) return;

    // Process in batches of 500 (Firestore limit)
    for (var i = 0; i < invoices.length; i += 500) {
      final batch = _firestore.batch();
      final chunk = invoices.skip(i).take(500);

      for (final invoice in chunk) {
        final ref = _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('invoices')
            .doc(invoice.id);

        final map = {
          'id': invoice.id,
          'accountingYearId': invoice.accountingYearId,
          'clientId': invoice.clientId,
          'invoiceNumber': invoice.invoiceNumber,
          'date': invoice.date.toUtc().toIso8601String(),
          'description': invoice.description,
          'amount': invoice.amount,
          'dueDate': invoice.dueDate?.toUtc().toIso8601String(),
          'notes': invoice.notes,
          'isDeleted': invoice.isDeleted,
          'createdAt': invoice.createdAt.toUtc().toIso8601String(),
          'updatedAt': invoice.updatedAt.toUtc().toIso8601String(),
        };

        // Remove null values so we don't overwrite with nulls unnecessarily during merge
        map.removeWhere((key, value) => value == null);

        batch.set(ref, map, SetOptions(merge: true));
      }

      await batch.commit();
    }
  }

  Future<List<Invoice>> pullInvoices(String businessId, DateTime? lastSyncTime) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('invoices');

    if (lastSyncTime != null) {
      query = query.where('updatedAt', isGreaterThan: lastSyncTime.toUtc().toIso8601String());
    }

    final snapshot = await query.get();

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate().toUtc();
      if (val is String) return DateTime.tryParse(val)?.toUtc() ?? DateTime.now().toUtc();
      return DateTime.now().toUtc();
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      
      return Invoice(
        id: data['id'] ?? doc.id,
        accountingYearId: data['accountingYearId'] ?? '',
        clientId: data['clientId'] ?? '',
        invoiceNumber: data['invoiceNumber'] ?? 0,
        date: parseDate(data['date']),
        description: data['description'],
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        dueDate: data['dueDate'] != null ? parseDate(data['dueDate']) : null,
        notes: data['notes'],
        isDeleted: data['isDeleted'] ?? false,
        createdAt: parseDate(data['createdAt']),
        updatedAt: parseDate(data['updatedAt']),
        isDirty: false,
        remoteId: doc.id,
        syncedAt: parseDate(data['updatedAt']),
      );
    }).toList();
  }
}
