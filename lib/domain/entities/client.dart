class Client {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final String? rc;
  final String? nif;
  final String? nis;
  final String? art;
  final String? activity;
  final String visibilityType;
  final String? createdBy;
  final String? updatedBy;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remoteId;
  final DateTime? syncedAt;
  final bool isDirty;

  const Client({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.rc,
    this.nif,
    this.nis,
    this.art,
    this.activity,
    this.visibilityType = 'everyone',
    this.createdBy,
    this.updatedBy,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncedAt,
    this.isDirty = false,
  });

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    String? rc,
    String? nif,
    String? nis,
    String? art,
    String? activity,
    String? visibilityType,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remoteId,
    DateTime? syncedAt,
    bool? isDirty,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      rc: rc ?? this.rc,
      nif: nif ?? this.nif,
      nis: nis ?? this.nis,
      art: art ?? this.art,
      activity: activity ?? this.activity,
      visibilityType: visibilityType ?? this.visibilityType,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      syncedAt: syncedAt ?? this.syncedAt,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Client &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          email == other.email &&
          address == other.address &&
          notes == other.notes &&
          activity == other.activity &&
          isDeleted == other.isDeleted;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      address.hashCode ^
      notes.hashCode ^
      activity.hashCode ^
      isDeleted.hashCode;
}
