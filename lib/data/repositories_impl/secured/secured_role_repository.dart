import '../../../domain/repositories/role_repository.dart';
import '../../../domain/entities/user_role.dart';
import '../../../domain/entities/current_app_user.dart';
import '../../../core/error/result.dart';
import '../../../core/security/permission_service.dart';
import '../../../domain/entities/permissions.dart';
import '../../../core/error/failures.dart';

class SecuredRoleRepository implements RoleRepository {
  final RoleRepository _inner;
  final PermissionService _permissionService;
  final CurrentAppUser? _currentUser;

  SecuredRoleRepository(this._inner, this._permissionService, this._currentUser);

  AppFailure _unauthorized() {
    return const AuthFailure('Unauthorized access to role data.');
  }

  @override
  Future<Result<List<UserRole>>> getAllRoles() async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.rolesView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getAllRoles();
  }

  @override
  Future<Result<UserRole?>> getRoleById(String id) async {
    // Current user's own role is always viewable
    if (_currentUser != null && _currentUser!.role.id == id) {
      return await _inner.getRoleById(id);
    }

    if (!_permissionService.hasPermission(_currentUser, Permissions.rolesView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getRoleById(id);
  }

  @override
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
  }

  @override
  Future<Result<void>> updateRole(UserRole role) async {
    final existingResult = await _inner.getRoleById(role.id);
    if (existingResult is! Success<UserRole?> || (existingResult as Success<UserRole?>).value == null) {
      return Failure(const DatabaseFailure('Role not found.'));
    }
    final existingRole = (existingResult as Success<UserRole?>).value!;

    if (!_permissionService.canManageRole(_currentUser, existingRole)) {
      return Failure(_unauthorized());
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
  }

  @override
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
  }
}
