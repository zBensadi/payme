import 'dart:convert';
import '../../domain/entities/user_role.dart';

class UserRoleModel extends UserRole {
  const UserRoleModel({
    required super.id,
    required super.name,
    super.description,
    super.color,
    super.priority,
    required super.isSystemRole,
    super.isEditable,
    super.isDeletable,
    required super.permissions,
    super.isDeleted,
    required super.createdAt,
    required super.updatedAt,
    super.remoteId,
    super.syncedAt,
    super.isDirty,
  });

  factory UserRoleModel.fromEntity(UserRole entity) {
    return UserRoleModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      color: entity.color,
      priority: entity.priority,
      isSystemRole: entity.isSystemRole,
      isEditable: entity.isEditable,
      isDeletable: entity.isDeletable,
      permissions: entity.permissions,
      isDeleted: entity.isDeleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      remoteId: entity.remoteId,
      syncedAt: entity.syncedAt,
      isDirty: entity.isDirty,
    );
  }

  factory UserRoleModel.fromMap(Map<String, dynamic> map) {
    return UserRoleModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      color: map['color'] as String?,
      priority: map['priority'] as int? ?? 100,
      isSystemRole: (map['is_system_role'] ?? 0) == 1,
      isEditable: (map['is_editable'] ?? 1) == 1,
      isDeletable: (map['is_deletable'] ?? 1) == 1,
      permissions: List<String>.from(jsonDecode(map['permissions'] as String)),
      isDeleted: (map['is_deleted'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      remoteId: map['remote_id'] as String?,
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String).toLocal() : null,
      isDirty: (map['is_dirty'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'priority': priority,
      'is_system_role': isSystemRole ? 1 : 0,
      'is_editable': isEditable ? 1 : 0,
      'is_deletable': isDeletable ? 1 : 0,
      'permissions': jsonEncode(permissions),
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'remote_id': remoteId,
      'synced_at': syncedAt?.toUtc().toIso8601String(),
      'is_dirty': isDirty ? 1 : 0,
    };
  }

  factory UserRoleModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return UserRoleModel(
      id: docId,
      name: data['name'] ?? '',
      description: data['description'],
      color: data['color'],
      priority: data['priority'] ?? 100,
      isSystemRole: data['isSystemRole'] ?? false,
      isEditable: data['isEditable'] ?? true,
      isDeletable: data['isDeletable'] ?? true,
      permissions: List<String>.from(data['permissions'] ?? []),
      isDeleted: data['isDeleted'] ?? false,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']).toLocal() : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'priority': priority,
      'isSystemRole': isSystemRole,
      'isEditable': isEditable,
      'isDeletable': isDeletable,
      'permissions': permissions,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}
