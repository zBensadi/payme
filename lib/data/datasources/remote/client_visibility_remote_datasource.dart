import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/client_visibility_model.dart';

class ClientVisibilityRemoteDataSource {
  final FirebaseFirestore _firestore;

  ClientVisibilityRemoteDataSource(this._firestore);

  /// We use a flat collection under the business to allow efficient pulling
  /// without requiring N queries or collection group queries.
  /// Path: businesses/{businessId}/client_visibility/{clientId_userId}
  CollectionReference<Map<String, dynamic>> _collection(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('client_visibility');
  }

  Future<List<ClientVisibilityModel>> getModifiedSince(String businessId, DateTime? since) async {
    debugPrint('[TRACE-VISIBILITY] ClientVisibilityRemoteDataSource.getModifiedSince($since)');
    Query<Map<String, dynamic>> query = _collection(businessId);
    
    if (since != null) {
      query = query.where('syncedAt', isGreaterThan: since.toUtc().toIso8601String());
    }

    final snapshot = await query.get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ClientVisibilityModel(
        clientId: data['clientId'] as String,
        userId: data['userId'] as String,
        syncedAt: data['syncedAt'] != null ? DateTime.parse(data['syncedAt'] as String).toLocal() : null,
      );
    }).toList();
  }

  Future<void> pushVisibilities(String businessId, List<ClientVisibilityModel> visibilities) async {
    debugPrint('[TRACE-VISIBILITY] ClientVisibilityRemoteDataSource.pushVisibilities: ${visibilities.map((e) => "${e.clientId}_${e.userId}").toList()}');
    for (var v in visibilities) {
      debugPrint('[TRACE-VISIBILITY] Firestore path: businesses/$businessId/client_visibility/${v.clientId}_${v.userId}');
    }
    debugPrint('TRACE [${DateTime.now().toIso8601String()}] ClientVisibilityRemoteDataSource.pushVisibilities: ${visibilities.map((e) => "${e.clientId}_${e.userId}").toList()}');
    if (visibilities.isEmpty) return;

    final batch = _firestore.batch();
    final collection = _collection(businessId);
    final now = DateTime.now().toUtc().toIso8601String();

    for (final v in visibilities) {
      final docId = '${v.clientId}_${v.userId}';
      final docRef = collection.doc(docId);
      
      batch.set(
        docRef,
        {
          'clientId': v.clientId,
          'userId': v.userId,
          'syncedAt': now,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> pushDeletions(String businessId, List<String> deletedDocIds) async {
    if (deletedDocIds.isEmpty) return;

    final batch = _firestore.batch();
    final collection = _collection(businessId);

    for (final docId in deletedDocIds) {
      final docRef = collection.doc(docId);
      batch.delete(docRef);
    }

    await batch.commit();
  }
}
