import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user_model.dart';
import '../../../domain/entities/app_user.dart';

class UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  UserRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> pushUsers(String businessId, List<AppUser> users) async {
    if (users.isEmpty) return;

    for (var i = 0; i < users.length; i += 500) {
      final batch = _firestore.batch();
      final chunk = users.skip(i).take(500);

      for (final user in chunk) {
        final ref = _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('users')
            .doc(user.uid);

        final model = AppUserModel.fromEntity(user);
        final map = model.toFirestore();
        map.removeWhere((key, value) => value == null);

        batch.set(ref, map, SetOptions(merge: true));
      }

      await batch.commit();
    }
  }

  Future<List<AppUserModel>> pullUsers(String businessId, DateTime? lastSyncTime) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('users');

    if (lastSyncTime != null) {
      query = query.where('updatedAt', isGreaterThan: lastSyncTime.toUtc().toIso8601String());
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return AppUserModel.fromFirestore(doc.data(), doc.id);
    }).toList();
  }
}
