import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/accounting_year.dart';

class AccountingYearRemoteDataSource {
  final FirebaseFirestore _firestore;

  AccountingYearRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> pushYears(String businessId, List<AccountingYear> years) async {
    if (years.isEmpty) return;

    for (var i = 0; i < years.length; i += 500) {
      final batch = _firestore.batch();
      final chunk = years.skip(i).take(500);

      for (final year in chunk) {
        final ref = _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('accounting_years')
            .doc(year.id);

        final map = {
          'id': year.id,
          'name': year.name,
          'isActive': year.isActive,
          'createdAt': year.createdAt.toUtc().toIso8601String(),
          'updatedAt': year.updatedAt.toUtc().toIso8601String(),
        };

        batch.set(ref, map, SetOptions(merge: true));
      }

      await batch.commit();
    }
  }

  Future<List<AccountingYear>> pullYears(String businessId, DateTime? lastSyncTime) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('accounting_years');

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
      
      return AccountingYear(
        id: data['id'] ?? doc.id,
        name: data['name'] ?? '',
        isActive: data['isActive'] ?? false,
        createdAt: parseDate(data['createdAt']),
        updatedAt: parseDate(data['updatedAt']),
        isDirty: false,
        remoteId: doc.id,
        syncedAt: parseDate(data['updatedAt']),
      );
    }).toList();
  }
}
