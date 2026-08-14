import '../../../domain/repositories/user_repository.dart';
import '../../../domain/repositories/role_repository.dart';
import '../../../domain/entities/user_role.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/current_app_user.dart';
import '../../../core/error/result.dart';
import '../../../core/security/permission_service.dart';
import '../../../domain/entities/permissions.dart';
import '../../../core/error/failures.dart';
import '../../../core/events/repository_change_publisher.dart';
import '../../../core/events/repository_event.dart';

class SecuredUserRepository implements UserRepository, RepositoryChangePublisher {
  final UserRepository _inner;
  final RoleRepository _roleRepository;
  final PermissionService _permissionService;
  final CurrentAppUser? _currentUser;

  SecuredUserRepository(this._inner, this._roleRepository, this._permissionService, this._currentUser);

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
    return const AuthFailure('Unauthorized access to user data.');
  }

  @override
  Future<Result<List<AppUser>>> getAllUsers() async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.usersView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getAllUsers();
  }

  @override
  Future<Result<AppUser?>> getUserById(String id) async {
    // Only users with users.view can retrieve arbitrary users
    // Exception: the user can always retrieve themselves
    if (_currentUser != null && _currentUser!.user.uid == id) {
      return await _inner.getUserById(id);
    }

    if (!_permissionService.hasPermission(_currentUser, Permissions.usersView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getUserById(id);
  }

  @override
  Future<Result<bool>> hasUsersWithRole(String roleId) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.usersView)) {
      return Failure(_unauthorized());
    }
    return await _inner.hasUsersWithRole(roleId);
  }

  @override
  Future<Result<void>> createUser(AppUser user) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.usersCreate)) {
      return Failure(_unauthorized());
    }

    // Role assignment logic:
    if (user.roleId != null) {
      final roleResult = await _roleRepository.getRoleById(user.roleId!);
      if (roleResult is! Success || (roleResult as Success).value == null) {
        return Failure(const DatabaseFailure('Invalid role assigned.'));
      }
      final role = (roleResult as Success).value!;
      
      if (!_permissionService.canAssignRole(_currentUser, role)) {
        return Failure(const AuthFailure('Cannot assign a role with priority equal or higher than your own.'));
      }
    }

    // Ensure they don't spoof system properties
    final securedUser = user.copyWith(
      isOwner: false, // Cannot create an owner
    );

    return await _inner.createUser(securedUser);
  }

  @override
  Future<Result<void>> updateUser(AppUser user) async {
    final existingResult = await _inner.getUserById(user.uid);
    if (existingResult is! Success<AppUser?> || (existingResult as Success<AppUser?>).value == null) {
      return Failure(const DatabaseFailure('User not found.'));
    }
    final existingUser = (existingResult as Success<AppUser?>).value!;

    // Cannot modify the owner unless you are the owner (enforced by permission service, but let's check correctly)
    final targetRoleResult = existingUser.roleId != null 
        ? await _roleRepository.getRoleById(existingUser.roleId!) 
        : const Success(null);
        
    final targetRole = targetRoleResult is Success<UserRole?> ? targetRoleResult.value : null;

    if (targetRole == null && !existingUser.requiresBootstrap) {
      // Something is very wrong with the existing user data
      return Failure(const DatabaseFailure('Target user has no valid role.'));
    }

    if (!_permissionService.canEditUser(_currentUser, existingUser, targetRole!)) {
      return Failure(_unauthorized());
    }

    // If changing role
    if (user.roleId != existingUser.roleId && user.roleId != null) {
      final newRoleResult = await _roleRepository.getRoleById(user.roleId!);
      if (newRoleResult is! Success<UserRole?> || (newRoleResult as Success<UserRole?>).value == null) {
        return Failure(const DatabaseFailure('Invalid role assigned.'));
      }
      final newRole = (newRoleResult as Success<UserRole?>).value!;
      
      if (!_permissionService.canAssignRole(_currentUser, newRole)) {
        return Failure(const AuthFailure('Cannot assign a role with priority equal or higher than your own.'));
      }
    }

    final securedUser = user.copyWith(
      isOwner: existingUser.isOwner, // Never allow changing owner status via UI
    );

    return await _inner.updateUser(securedUser);
  }

  @override
  Future<Result<void>> deleteUser(String id) async {
    final existingResult = await _inner.getUserById(id);
    if (existingResult is! Success<AppUser?> || (existingResult as Success<AppUser?>).value == null) {
      return Failure(const DatabaseFailure('User not found.'));
    }
    final existingUser = (existingResult as Success<AppUser?>).value!;

    final targetRoleResult = existingUser.roleId != null 
        ? await _roleRepository.getRoleById(existingUser.roleId!) 
        : const Success(null);
    final targetRole = targetRoleResult is Success<UserRole?> ? targetRoleResult.value : null;

    if (targetRole == null && !existingUser.requiresBootstrap) {
       return Failure(const DatabaseFailure('Target user has no valid role.'));
    }

    if (!_permissionService.canDeleteUser(_currentUser, existingUser, targetRole!)) {
      return Failure(_unauthorized());
    }

    return await _inner.deleteUser(id);
  }
}
