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
      isDeleted: entity.isDeleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      remoteId: entity.remoteId,
      syncedAt: entity.syncedAt,
      isDirty: entity.isDirty,
    );
  }
}
