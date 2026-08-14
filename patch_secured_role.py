import sys

file_path = "lib/data/repositories_impl/secured/secured_role_repository.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Add UserRepository to constructor
content = content.replace(
    "import '../../../core/error/failures.dart';",
    "import '../../../core/error/failures.dart';\nimport '../../../domain/repositories/user_repository.dart';"
)

content = content.replace(
    "  final CurrentAppUser? _currentUser;\n\n  SecuredRoleRepository(this._inner, this._permissionService, this._currentUser);",
    "  final CurrentAppUser? _currentUser;\n  final UserRepository _userRepository;\n\n  SecuredRoleRepository(this._inner, this._permissionService, this._currentUser, this._userRepository);"
)

# 2. Modify createRole
old_create = """  @override
  Future<Result<void>> createRole(UserRole role) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.rolesManage)) {
      return Failure(_unauthorized());
    }

    // You cannot create a role with priority equal or higher than your own
    if (!_permissionService.canAssignRole(_currentUser, role)) {
      return Failure(const DatabaseFailure('Cannot create a role with priority equal or higher than your own.'));
    }

    // Force system properties off
    final securedRole = role.copyWith(
      isSystemRole: false,
    );

    return await _inner.createRole(securedRole);
  }"""

new_create = """  @override
  Future<Result<void>> createRole(UserRole role) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.rolesManage)) {
      return Failure(_unauthorized());
    }

    // Duplicate name validation
    final rolesResult = await _inner.getAllRoles();
    if (rolesResult is Success<List<UserRole>>) {
      final nameExists = rolesResult.value.any((r) => r.name.trim().toLowerCase() == role.name.trim().toLowerCase());
      if (nameExists) {
        return Failure(const DatabaseFailure('A role with this name already exists.'));
      }
    }

    // Priority validation
    if (!_permissionService.canAssignRole(_currentUser, role)) {
      return Failure(const DatabaseFailure('Cannot create a role with priority equal or higher than your own.'));
    }

    // Privilege validation
    if (_currentUser != null && !_currentUser!.user.isOwner) {
      final unauthorizedPermissions = role.permissions.where((p) => !_currentUser!.role.permissions.contains(p));
      if (unauthorizedPermissions.isNotEmpty) {
        return Failure(const DatabaseFailure('Cannot assign permissions that you do not possess.'));
      }
    }

    // Force system properties for custom roles
    final securedRole = role.copyWith(
      isSystemRole: false,
      isEditable: true,
      isDeletable: true,
    );

    return await _inner.createRole(securedRole);
  }"""

content = content.replace(old_create, new_create)

# 3. Modify updateRole
old_update = """  @override
  Future<Result<void>> updateRole(UserRole role) async {
    final existingResult = await _inner.getRoleById(role.id);
    if (existingResult is! Success<UserRole?> || (existingResult as Success<UserRole?>).value == null) {
      return Failure(const DatabaseFailure('Role not found.'));
    }
    final existingRole = (existingResult as Success<UserRole?>).value!;

    if (!_permissionService.canManageRole(_currentUser, existingRole)) {
      return Failure(_unauthorized());
    }

    if (!existingRole.isEditable) {
      return Failure(const DatabaseFailure('This role is a system role and its structure cannot be modified.'));
    }

    // You cannot elevate the role priority to be equal or higher than your own
    if (!_permissionService.canAssignRole(_currentUser, role)) {
      return Failure(const DatabaseFailure('Cannot elevate role priority to be equal or higher than your own.'));
    }

    final securedRole = role.copyWith(
      isSystemRole: existingRole.isSystemRole,
      isEditable: existingRole.isEditable,
      isDeletable: existingRole.isDeletable,
    );

    return await _inner.updateRole(securedRole);
  }"""

new_update = """  @override
  Future<Result<void>> updateRole(UserRole role) async {
    final existingResult = await _inner.getRoleById(role.id);
    if (existingResult is! Success<UserRole?> || (existingResult as Success<UserRole?>).value == null) {
      return Failure(const DatabaseFailure('Role not found.'));
    }
    final existingRole = (existingResult as Success<UserRole?>).value!;

    if (!_permissionService.canManageRole(_currentUser, existingRole)) {
      return Failure(_unauthorized());
    }

    if (!existingRole.isEditable) {
      return Failure(const DatabaseFailure('This role is a system role and its structure cannot be modified.'));
    }
    
    // Duplicate name validation
    final rolesResult = await _inner.getAllRoles();
    if (rolesResult is Success<List<UserRole>>) {
      final nameExists = rolesResult.value.any((r) => r.id != role.id && r.name.trim().toLowerCase() == role.name.trim().toLowerCase());
      if (nameExists) {
        return Failure(const DatabaseFailure('A role with this name already exists.'));
      }
    }

    // You cannot elevate the role priority to be equal or higher than your own
    if (!_permissionService.canAssignRole(_currentUser, role)) {
      return Failure(const DatabaseFailure('Cannot elevate role priority to be equal or higher than your own.'));
    }
    
    // Privilege validation
    if (_currentUser != null && !_currentUser!.user.isOwner) {
      final unauthorizedPermissions = role.permissions.where((p) => !_currentUser!.role.permissions.contains(p));
      if (unauthorizedPermissions.isNotEmpty) {
        return Failure(const DatabaseFailure('Cannot assign permissions that you do not possess.'));
      }
    }

    final securedRole = role.copyWith(
      isSystemRole: existingRole.isSystemRole,
      isEditable: existingRole.isEditable,
      isDeletable: existingRole.isDeletable,
    );

    return await _inner.updateRole(securedRole);
  }"""

content = content.replace(old_update, new_update)

# 4. Modify deleteRole
old_delete = """  @override
  Future<Result<void>> deleteRole(String id) async {
    final existingResult = await _inner.getRoleById(id);
    if (existingResult is! Success<UserRole?> || (existingResult as Success<UserRole?>).value == null) {
      return Failure(const DatabaseFailure('Role not found.'));
    }
    final existingRole = (existingResult as Success<UserRole?>).value!;

    if (!_permissionService.canManageRole(_currentUser, existingRole)) {
      return Failure(_unauthorized());
    }

    if (!existingRole.isDeletable) {
      return Failure(const DatabaseFailure('This role cannot be deleted.'));
    }

    return await _inner.deleteRole(id);
  }"""
  
new_delete = """  @override
  Future<Result<void>> deleteRole(String id) async {
    final existingResult = await _inner.getRoleById(id);
    if (existingResult is! Success<UserRole?> || (existingResult as Success<UserRole?>).value == null) {
      return Failure(const DatabaseFailure('Role not found.'));
    }
    final existingRole = (existingResult as Success<UserRole?>).value!;

    if (!_permissionService.canManageRole(_currentUser, existingRole)) {
      return Failure(_unauthorized());
    }

    if (!existingRole.isDeletable) {
      return Failure(const DatabaseFailure('This role cannot be deleted.'));
    }
    
    final hasUsersResult = await _userRepository.hasUsersWithRole(id);
    if (hasUsersResult is Success<bool> && hasUsersResult.value) {
      return Failure(const DatabaseFailure('Cannot delete this role because users are currently assigned to it.'));
    }

    return await _inner.deleteRole(id);
  }"""
  
content = content.replace(old_delete, new_delete)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
