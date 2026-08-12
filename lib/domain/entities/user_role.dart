class UserRole {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final int priority;
  final bool isSystemRole;
  final bool isEditable;
  final bool isDeletable;
  final List<String> permissions;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remoteId;
  final DateTime? syncedAt;
  final bool isDirty;

  const UserRole({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.priority = 100,
    required this.isSystemRole,
    this.isEditable = true,
    this.isDeletable = true,
    required this.permissions,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncedAt,
    this.isDirty = false,
  });

  UserRole copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    int? priority,
    bool? isSystemRole,
    bool? isEditable,
    bool? isDeletable,
    List<String>? permissions,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remoteId,
    DateTime? syncedAt,
    bool? isDirty,
  }) {
    return UserRole(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      isEditable: isEditable ?? this.isEditable,
      isDeletable: isDeletable ?? this.isDeletable,
      permissions: permissions ?? this.permissions,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      syncedAt: syncedAt ?? this.syncedAt,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
