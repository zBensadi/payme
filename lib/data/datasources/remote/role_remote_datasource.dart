import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_role_model.dart';
import '../../../domain/entities/user_role.dart';

class RoleRemoteDataSource {
  final FirebaseFirestore _firestore;

  RoleRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> pushRoles(String businessId, List<UserRole> roles) async {
    if (roles.isEmpty) return;

    for (var i = 0; i < roles.length; i += 500) {
      final batch = _firestore.batch();
      final chunk = roles.skip(i).take(500);

      for (final role in chunk) {
        final ref = _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('roles')
            .doc(role.id);

        final model = UserRoleModel.fromEntity(role);
        final map = model.toFirestore();
        map.removeWhere((key, value) => value == null);

        batch.set(ref, map, SetOptions(merge: true));
      }

      await batch.commit();
    }
  }

  Future<List<UserRoleModel>> pullRoles(String businessId, DateTime? lastSyncTime) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('roles');

    if (lastSyncTime != null) {
      query = query.where('updatedAt', isGreaterThan: lastSyncTime.toUtc().toIso8601String());
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return UserRoleModel.fromFirestore(doc.data(), doc.id);
    }).toList();
  }
}
