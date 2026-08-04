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
      currencyLockedAt: map['currency_locked_at'] != null 
          ? DateTime.parse(map['currency_locked_at'] as String) 
          : null,
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
      'currency_locked_at': settings.currencyLockedAt?.toIso8601String(),
    };
  }
}
