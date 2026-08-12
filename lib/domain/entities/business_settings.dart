class BusinessSettings {
  final int id;
  final String? businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoPath;
  final String currencyCode;
  final String languageCode;
  final String defaultDocumentTitle;
  final String defaultDocumentLayout;
  final DateTime? currencyLockedAt;
  
  final String? rc;
  final String? nif;
  final String? nis;
  final String? art;
  
  // Sync metadata
  final String? createdBy;
  final String? updatedBy;
  final DateTime? updatedAt;
  final String? remoteId;
  final DateTime? syncedAt;
  final bool isDirty;

  const BusinessSettings({
    this.id = 1,
    this.businessName,
    this.address,
    this.phone,
    this.email,
    this.logoPath,
    this.currencyCode = 'USD',
    this.languageCode = 'en',
    this.defaultDocumentTitle = 'Invoice',
    this.defaultDocumentLayout = 'standard',
    this.currencyLockedAt,
    this.rc,
    this.nif,
    this.nis,
    this.art,
    this.createdBy,
    this.updatedBy,
    this.updatedAt,
    this.remoteId,
    this.syncedAt,
    this.isDirty = false,
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
    String? defaultDocumentTitle,
    String? defaultDocumentLayout,
    DateTime? currencyLockedAt,
    String? rc,
    String? nif,
    String? nis,
    String? art,
    String? createdBy,
    String? updatedBy,
    DateTime? updatedAt,
    String? remoteId,
    DateTime? syncedAt,
    bool? isDirty,
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
      defaultDocumentTitle: defaultDocumentTitle ?? this.defaultDocumentTitle,
      defaultDocumentLayout: defaultDocumentLayout ?? this.defaultDocumentLayout,
      currencyLockedAt: currencyLockedAt ?? this.currencyLockedAt,
      rc: rc ?? this.rc,
      nif: nif ?? this.nif,
      nis: nis ?? this.nis,
      art: art ?? this.art,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      syncedAt: syncedAt ?? this.syncedAt,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
