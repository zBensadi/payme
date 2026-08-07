class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? businessId;
  final String? roleId;
  final bool isSuperAdmin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.businessId,
    this.roleId,
    required this.isSuperAdmin,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? businessId,
    String? roleId,
    bool? isSuperAdmin,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      businessId: businessId ?? this.businessId,
      roleId: roleId ?? this.roleId,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
