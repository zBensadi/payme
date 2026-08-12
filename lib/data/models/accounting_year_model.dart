import '../../domain/entities/accounting_year.dart';

class AccountingYearModel extends AccountingYear {
  const AccountingYearModel({
    required super.id,
    required super.name,
    required super.isActive,
    super.createdBy,
    super.updatedBy,
    required super.createdAt,
    required super.updatedAt,
    super.remoteId,
    super.syncedAt,
    super.isDirty,
  });

  factory AccountingYearModel.fromMap(Map<String, dynamic> map) {
    return AccountingYearModel(
      id: map['id'] as String,
      name: map['name'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdBy: map['created_by'] as String?,
      updatedBy: map['updated_by'] as String?,
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
      'is_active': isActive ? 1 : 0,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'remote_id': remoteId,
      'synced_at': syncedAt?.toUtc().toIso8601String(),
      'is_dirty': isDirty ? 1 : 0,
    };
  }

  factory AccountingYearModel.fromEntity(AccountingYear entity) {
    return AccountingYearModel(
      id: entity.id,
      name: entity.name,
      isActive: entity.isActive,
      createdBy: entity.createdBy,
      updatedBy: entity.updatedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      remoteId: entity.remoteId,
      syncedAt: entity.syncedAt,
      isDirty: entity.isDirty,
    );
  }
}
