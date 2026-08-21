import '../../../domain/repositories/role_repository.dart';
import '../../../domain/entities/user_role.dart';
import '../../../domain/entities/current_app_user.dart';
import '../../../core/error/result.dart';
import '../../../core/security/permission_service.dart';
import '../../../domain/entities/permissions.dart';
import '../../../core/error/failures.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../core/events/repository_change_publisher.dart';
import '../../../core/events/repository_event.dart';

class SecuredRoleRepository implements RoleRepository, RepositoryChangePublisher {
  final RoleRepository _inner;
  final PermissionService _permissionService;
  final CurrentAppUser? _currentUser;
  final UserRepository _userRepository;

  SecuredRoleRepository(this._inner, this._permissionService, this._currentUser, this._userRepository);

  @override
  Stream<RepositoryEvent> watchEvents() {
    if (_inner is RepositoryChangePublisher) {
      return (_inner as RepositoryChangePublisher).watchEvents();
    }
    return const Stream.empty();
  }

  @override
  void dispose() {}

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
    if (_currentUser != null && _currentUser.role.id == id) {
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
    if (_currentUser != null && !_currentUser.user.isOwner) {
      final unauthorizedPermissions = role.permissions.where((p) => !_currentUser.role.permissions.contains(p));
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
  }

  @override
  Future<Result<void>> updateRole(UserRole role) async {
    final existingResult = await _inner.getRoleById(role.id);
    if (existingResult is! Success<UserRole?> || (existingResult).value == null) {
      return Failure(const DatabaseFailure('Role not found.'));
    }
    final existingRole = (existingResult).value!;

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
    if (_currentUser != null && !_currentUser.user.isOwner) {
      final unauthorizedPermissions = role.permissions.where((p) => !_currentUser.role.permissions.contains(p));
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
  }

  @override
  Future<Result<void>> deleteRole(String id) async {
    final existingResult = await _inner.getRoleById(id);
    if (existingResult is! Success<UserRole?> || (existingResult).value == null) {
      return Failure(const DatabaseFailure('Role not found.'));
    }
    final existingRole = (existingResult).value!;

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
  }
}
