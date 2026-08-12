import '../../domain/entities/client.dart';

class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.name,
    super.phone,
    super.email,
    super.address,
    super.notes,
    super.rc,
    super.nif,
    super.nis,
    super.art,
    super.visibilityType = 'everyone',
    super.createdBy,
    super.updatedBy,
    super.isDeleted = false,
    required super.createdAt,
    required super.updatedAt,
    super.remoteId,
    super.syncedAt,
    super.isDirty = false,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      rc: map['rc'] as String?,
      nif: map['nif'] as String?,
      nis: map['nis'] as String?,
      art: map['art'] as String?,
      visibilityType: map['visibility_type'] as String? ?? 'everyone',
      createdBy: map['created_by'] as String?,
      updatedBy: map['updated_by'] as String?,
      isDeleted: (map['is_deleted'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      remoteId: map['remote_id'] as String?,
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String).toLocal() : null,
      isDirty: (map['is_dirty'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'rc': rc,
      'nif': nif,
      'nis': nis,
      'art': art,
      'visibility_type': visibilityType,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'remote_id': remoteId,
      'synced_at': syncedAt?.toUtc().toIso8601String(),
      'is_dirty': isDirty ? 1 : 0,
    };
  }

  factory ClientModel.fromEntity(Client entity) {
    return ClientModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      address: entity.address,
      notes: entity.notes,
      rc: entity.rc,
      nif: entity.nif,
      nis: entity.nis,
      art: entity.art,
      visibilityType: entity.visibilityType,
      createdBy: entity.createdBy,
      updatedBy: entity.updatedBy,
      isDeleted: entity.isDeleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      remoteId: entity.remoteId,
      syncedAt: entity.syncedAt,
      isDirty: entity.isDirty,
    );
  }

  factory ClientModel.fromFirestore(Map<String, dynamic> doc, String id) {
    return ClientModel(
      id: id,
      name: doc['name'] as String? ?? '',
      phone: doc['phone'] as String?,
      email: doc['email'] as String?,
      address: doc['address'] as String?,
      notes: doc['notes'] as String?,
      rc: doc['rc'] as String?,
      nif: doc['nif'] as String?,
      nis: doc['nis'] as String?,
      art: doc['art'] as String?,
      visibilityType: doc['visibilityType'] as String? ?? 'everyone',
      createdBy: doc['createdBy'] as String?,
      updatedBy: doc['updatedBy'] as String?,
      isDeleted: doc['isDeleted'] as bool? ?? false,
      createdAt: doc['createdAt'] != null ? DateTime.parse(doc['createdAt'] as String).toLocal() : DateTime.now(),
      updatedAt: doc['updatedAt'] != null ? DateTime.parse(doc['updatedAt'] as String).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'rc': rc,
      'nif': nif,
      'nis': nis,
      'art': art,
      'visibilityType': visibilityType,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}
