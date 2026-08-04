class BusinessSettings {
  final int id;
  final String? businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoPath;
  final String currencyCode;
  final String languageCode;
  final DateTime? currencyLockedAt;

  const BusinessSettings({
    this.id = 1,
    this.businessName,
    this.address,
    this.phone,
    this.email,
    this.logoPath,
    this.currencyCode = 'USD',
    this.languageCode = 'en',
    this.currencyLockedAt,
  });


  BusinessSettings copyWith({
    int? id,
    String? businessName,
    String? address,
    String? phone,
    String? email,
    String? logoPath,
    String? currencyCode,
    String? languageCode,
    DateTime? currencyLockedAt,
  }) {
    return BusinessSettings(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoPath: logoPath ?? this.logoPath,
      currencyCode: currencyCode ?? this.currencyCode,
      languageCode: languageCode ?? this.languageCode,
      currencyLockedAt: currencyLockedAt ?? this.currencyLockedAt,
    );
  }
}
