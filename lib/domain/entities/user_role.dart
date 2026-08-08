class UserRole {
  final String roleId;
  final String name;
  final bool isSystemRole;
  final Map<String, dynamic> defaultPermissions;

  const UserRole({
    required this.roleId,
    required this.name,
    required this.isSystemRole,
    required this.defaultPermissions,
  });
}
