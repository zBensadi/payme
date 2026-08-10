import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/payment_method.dart';

class PaymentRemoteDataSource {
  final FirebaseFirestore _firestore;

  PaymentRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> pushPayments(String businessId, List<Payment> payments) async {
    if (payments.isEmpty) return;

    for (var i = 0; i < payments.length; i += 500) {
      final batch = _firestore.batch();
      final chunk = payments.skip(i).take(500);

      for (final payment in chunk) {
        final ref = _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('payments')
            .doc(payment.id);

        final map = {
          'id': payment.id,
          'invoiceId': payment.invoiceId,
          'date': payment.date.toUtc().toIso8601String(),
          'amount': payment.amount,
          'method': payment.method.toDbString(),
          'reference': payment.reference,
          'notes': payment.notes,
          'isDeleted': payment.isDeleted,
          'createdAt': payment.createdAt.toUtc().toIso8601String(),
          'updatedAt': payment.updatedAt.toUtc().toIso8601String(),
        };

        batch.set(ref, map, SetOptions(merge: true));
      }

      await batch.commit();
    }
  }

  Future<List<Payment>> pullPayments(String businessId, DateTime? lastSyncTime) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payments');

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
      
      return Payment(
        id: data['id'] ?? doc.id,
        invoiceId: data['invoiceId'] ?? '',
        date: parseDate(data['date']),
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        method: PaymentMethod.fromString(data['method'] ?? ''),
        reference: data['reference'],
        notes: data['notes'],
        isDeleted: data['isDeleted'] ?? false,
        createdAt: parseDate(data['createdAt']),
        updatedAt: parseDate(data['updatedAt']),
        isDirty: false,
        remoteId: doc.id,
        syncedAt: parseDate(data['updatedAt']),
        attachments: [], // Attachments are strictly local for now
      );
    }).toList();
  }
}
