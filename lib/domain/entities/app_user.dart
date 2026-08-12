class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? businessId;
  final String? roleId;
  final bool isSuperAdmin;
  final bool isOwner;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remoteId;
  final DateTime? syncedAt;
  final bool isDirty;

  bool get requiresBootstrap => businessId == null;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.businessId,
    this.roleId,
    required this.isSuperAdmin,
    this.isOwner = false,
    required this.isActive,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncedAt,
    this.isDirty = false,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? businessId,
    String? roleId,
    bool? isSuperAdmin,
    bool? isOwner,
    bool? isActive,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remoteId,
    DateTime? syncedAt,
    bool? isDirty,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      businessId: businessId ?? this.businessId,
      roleId: roleId ?? this.roleId,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      isOwner: isOwner ?? this.isOwner,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      syncedAt: syncedAt ?? this.syncedAt,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
