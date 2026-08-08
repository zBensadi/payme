import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/client.dart';

class ClientRemoteDataSource {
  final FirebaseFirestore _firestore;

  ClientRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> pushClients(String businessId, List<Client> clients) async {
    if (clients.isEmpty) return;

    // Process in batches of 500 (Firestore limit)
    for (var i = 0; i < clients.length; i += 500) {
      final batch = _firestore.batch();
      final chunk = clients.skip(i).take(500);

      for (final client in chunk) {
        final ref = _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('clients')
            .doc(client.id);

        final map = {
          'id': client.id,
          'name': client.name,
          'phone': client.phone,
          'email': client.email,
          'address': client.address,
          'notes': client.notes,
          'isDeleted': client.isDeleted,
          'createdAt': client.createdAt.toUtc().toIso8601String(),
          'updatedAt': client.updatedAt.toUtc().toIso8601String(),
        };

        // Remove null values so we don't overwrite with nulls unnecessarily during merge
        map.removeWhere((key, value) => value == null);

        batch.set(ref, map, SetOptions(merge: true));
      }

      await batch.commit();
    }
  }

  Future<List<Client>> pullClients(String businessId, DateTime? lastSyncTime) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('clients');

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
      
      return Client(
        id: data['id'] ?? doc.id,
        name: data['name'] ?? '',
        phone: data['phone'],
        email: data['email'],
        address: data['address'],
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
