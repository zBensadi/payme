import '../../../domain/entities/business_settings.dart';

class BusinessSettingsModel {
  static BusinessSettings fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      id: map['id'] as int,
      businessName: map['business_name'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      logoPath: map['logo_path'] as String?,
      currencyCode: map['currency_code'] as String,
      languageCode: map['language_code'] as String? ?? 'en',
      defaultDocumentTitle: map['default_document_title'] as String? ?? 'Invoice',
      defaultDocumentLayout: map['default_document_layout'] as String? ?? 'standard',
      currencyLockedAt: map['currency_locked_at'] != null 
          ? DateTime.parse(map['currency_locked_at'] as String) 
          : null,
      rc: map['rc'] as String?,
      nif: map['nif'] as String?,
      nis: map['nis'] as String?,
      art: map['art'] as String?,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      remoteId: map['remote_id'] as String?,
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String) : null,
      isDirty: (map['is_dirty'] as int? ?? 0) == 1,
    );
  }

  static Map<String, dynamic> toMap(BusinessSettings settings) {
    return {
      'id': settings.id,
      'business_name': settings.businessName,
      'address': settings.address,
      'phone': settings.phone,
      'email': settings.email,
      'logo_path': settings.logoPath,
      'currency_code': settings.currencyCode,
      'language_code': settings.languageCode,
      'default_document_title': settings.defaultDocumentTitle,
      'default_document_layout': settings.defaultDocumentLayout,
      'currency_locked_at': settings.currencyLockedAt?.toUtc().toIso8601String(),
      'rc': settings.rc,
      'nif': settings.nif,
      'nis': settings.nis,
      'art': settings.art,
      'updated_at': settings.updatedAt?.toUtc().toIso8601String(),
      'remote_id': settings.remoteId,
      'synced_at': settings.syncedAt?.toUtc().toIso8601String(),
      'is_dirty': settings.isDirty ? 1 : 0,
    };
  }
}
