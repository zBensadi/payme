import 'package:flutter/foundation.dart';
import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.email,
    super.displayName,
    super.businessId,
    super.roleId,
    required super.isSuperAdmin,
    super.isOwner,
    required super.isActive,
    super.isDeleted,
    required super.createdAt,
    required super.updatedAt,
    super.remoteId,
    super.syncedAt,
    super.isDirty,
  });

  factory AppUserModel.fromEntity(AppUser entity) {
    return AppUserModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      businessId: entity.businessId,
      roleId: entity.roleId,
      isSuperAdmin: entity.isSuperAdmin,
      isOwner: entity.isOwner,
      isActive: entity.isActive,
      isDeleted: entity.isDeleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      remoteId: entity.remoteId,
      syncedAt: entity.syncedAt,
      isDirty: entity.isDirty,
    );
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    final model = AppUserModel(
      uid: map['id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String?,
      businessId: map['business_id'] as String?,
      roleId: map['role_id'] as String?,
      isSuperAdmin: false, // isSuperAdmin is determined dynamically or omitted for local DB
      isOwner: (map['is_owner'] ?? 0) == 1,
      isActive: (map['is_active'] ?? 1) == 1,
      isDeleted: (map['is_deleted'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      remoteId: map['remote_id'] as String?,
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String).toLocal() : null,
      isDirty: (map['is_dirty'] ?? 0) == 1,
    );
    debugPrint('[TRACE-businessId] AppUserModel.fromMap() -> businessId=${model.businessId}');
    return model;
  }

  Map<String, dynamic> toMap() {
    final map = {
      'id': uid,
      'email': email,
      'display_name': displayName,
      'business_id': businessId,
      'role_id': roleId,
      'is_owner': isOwner ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'remote_id': remoteId,
      'synced_at': syncedAt?.toUtc().toIso8601String(),
      'is_dirty': isDirty ? 1 : 0,
    };
    debugPrint('[TRACE-businessId] AppUserModel.toMap() -> map[\'business_id\']=${map['business_id']}');
    return map;
  }

  factory AppUserModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return AppUserModel(
      uid: docId,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      roleId: data['roleId'],
      isSuperAdmin: false,
      isOwner: data['isOwner'] ?? false,
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']).toLocal() : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'roleId': roleId,
      'isOwner': isOwner,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}
