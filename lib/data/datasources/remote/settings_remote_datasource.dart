import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/business_settings.dart';
import '../../models/business_settings_model.dart';

class SettingsRemoteDataSource {
  final FirebaseFirestore _firestore;

  SettingsRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> pushSettings(String businessId, BusinessSettings settings) async {
    final map = {
      'businessId': businessId,
      'businessName': settings.businessName,
      'address': settings.address,
      'phone': settings.phone,
      'email': settings.email,
      'logoPath': settings.logoPath,
      'currencyCode': settings.currencyCode,
      'languageCode': settings.languageCode,
      'defaultDocumentTitle': settings.defaultDocumentTitle,
      'defaultDocumentLayout': settings.defaultDocumentLayout,
      'currencyLockedAt': settings.currencyLockedAt?.toUtc().toIso8601String(),
      'updatedAt': settings.updatedAt?.toUtc().toIso8601String(),
    };

    // Remove null values so we don't overwrite with nulls unnecessarily during merge
    map.removeWhere((key, value) => value == null);

    final batch = _firestore.batch();

    // 1. Update business_settings document
    final settingsRef = _firestore.collection('business_settings').doc(businessId);
    batch.set(settingsRef, map, SetOptions(merge: true));

    // 2. Update businesses document atomically
    if (settings.businessName != null) {
      final businessRef = _firestore.collection('businesses').doc(businessId);
      batch.update(businessRef, {'name': settings.businessName});
    }

    await batch.commit();
  }

  Future<BusinessSettings?> pullSettings(String businessId) async {
    final doc = await _firestore.collection('business_settings').doc(businessId).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate().toUtc();
      if (val is String) return DateTime.tryParse(val)?.toUtc();
      return null;
    }
    
    return BusinessSettings(
      id: 1,
      businessName: data['businessName'],
      address: data['address'],
      phone: data['phone'],
      email: data['email'],
      logoPath: data['logoPath'],
      currencyCode: data['currencyCode'] ?? 'DZD',
      languageCode: data['languageCode'] ?? 'en',
      defaultDocumentTitle: data['defaultDocumentTitle'] ?? 'Invoice',
      defaultDocumentLayout: data['defaultDocumentLayout'] ?? 'standard',
      currencyLockedAt: parseDate(data['currencyLockedAt']),
      updatedAt: parseDate(data['updatedAt']),
      isDirty: false,
      remoteId: doc.id,
      syncedAt: parseDate(data['updatedAt']),
    );
  }
}
