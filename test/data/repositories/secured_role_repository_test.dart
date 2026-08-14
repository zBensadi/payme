import 'package:flutter_test/flutter_test.dart';

import 'package:payme/domain/repositories/role_repository.dart';
import 'package:payme/domain/repositories/user_repository.dart';
import 'package:payme/data/repositories_impl/secured/secured_role_repository.dart';
import 'package:payme/core/security/permission_service.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/domain/entities/current_app_user.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/core/error/result.dart';

class MockRoleRepository implements RoleRepository {
  Future<Result<List<UserRole>>> Function()? getAllRolesMock;
  Future<Result<void>> Function(UserRole)? createRoleMock;
  Future<Result<UserRole?>> Function(String)? getRoleByIdMock;
  Future<Result<void>> Function(String)? deleteRoleMock;

  @override
  Future<Result<List<UserRole>>> getAllRoles() async => getAllRolesMock?.call() ?? const Success([]);
  @override
  Future<Result<void>> createRole(UserRole role) async => createRoleMock?.call(role) ?? const Success(null);
  @override
  Future<Result<UserRole?>> getRoleById(String id) async => getRoleByIdMock?.call(id) ?? const Success(null);
  @override
  Future<Result<void>> deleteRole(String id) async => deleteRoleMock?.call(id) ?? const Success(null);
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class MockUserRepository implements UserRepository {
  Future<Result<bool>> Function(String)? hasUsersWithRoleMock;

  @override
  Future<Result<bool>> hasUsersWithRole(String roleId) async => hasUsersWithRoleMock?.call(roleId) ?? const Success(false);
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class MockPermissionService implements PermissionService {
  bool Function(CurrentAppUser?, String)? hasPermissionMock;
  bool Function(CurrentAppUser?, UserRole)? canAssignRoleMock;
  bool Function(CurrentAppUser?, UserRole)? canManageRoleMock;

  @override
  bool hasPermission(CurrentAppUser? currentUser, String permission) => hasPermissionMock?.call(currentUser, permission) ?? false;
  @override
  bool canAssignRole(CurrentAppUser? currentUser, UserRole roleToAssign) => canAssignRoleMock?.call(currentUser, roleToAssign) ?? false;
  @override
  bool canManageRole(CurrentAppUser? currentUser, UserRole targetRole) => canManageRoleMock?.call(currentUser, targetRole) ?? false;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockRoleRepository mockRoleRepo;
  late MockUserRepository mockUserRepo;
  late MockPermissionService mockPermissionService;
  late SecuredRoleRepository securedRoleRepo;
  late CurrentAppUser mockCurrentUser;

  setUp(() {
    mockRoleRepo = MockRoleRepository();
    mockUserRepo = MockUserRepository();
    mockPermissionService = MockPermissionService();

    mockCurrentUser = CurrentAppUser(
      user: AppUser(
        uid: 'user1',
        email: 'test@test.com',
        businessId: 'b1',
        roleId: 'role1',
        isSuperAdmin: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      role: UserRole(
        id: 'role1',
        name: 'Admin',
        priority: 700,
        isSystemRole: false,
        permissions: ['roles.manage'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    securedRoleRepo = SecuredRoleRepository(
      mockRoleRepo,
      mockPermissionService,
      mockCurrentUser,
      mockUserRepo,
    );
    

  });

  group('createRole', () {
    test('should prevent creating a role with a duplicate name', () async {
      mockPermissionService.hasPermissionMock = (u, p) => p == 'roles.manage';
      
      final existingRole = UserRole(
        id: 'role2',
        name: 'Manager ', // Trailing space
        isSystemRole: false,
        permissions: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockRoleRepo.getAllRolesMock = () async => Success([existingRole]);

      final newRole = UserRole(
        id: 'role3',
        name: 'MANAGER', // Different case
        priority: 100,
        isSystemRole: false,
        permissions: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await securedRoleRepo.createRole(newRole);

      expect(result is Failure, true);
      expect((result as Failure).failure.message, contains('already exists'));
    });

    test('should enforce target priority < current user priority', () async {
      mockPermissionService.hasPermissionMock = (u, p) => p == 'roles.manage';
      mockRoleRepo.getAllRolesMock = () async => const Success([]);
      
      final newRole = UserRole(
        id: 'role3',
        name: 'NewRole',
        priority: 700, // Equal to current user priority (700)
        isSystemRole: false,
        permissions: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockPermissionService.canAssignRoleMock = (u, r) => false;

      final result = await securedRoleRepo.createRole(newRole);

      expect(result is Failure, true);
      expect((result as Failure).failure.message, contains('priority equal or higher'));
    });

    test('should block assigning permissions the current user does not have', () async {
      mockPermissionService.hasPermissionMock = (u, p) => p == 'roles.manage';
      mockRoleRepo.getAllRolesMock = () async => const Success([]);
      
      final newRole = UserRole(
        id: 'role3',
        name: 'NewRole',
        priority: 100,
        isSystemRole: false,
        permissions: ['roles.manage', 'billing.manage'], // user doesn't have billing.manage
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockPermissionService.canAssignRoleMock = (u, r) => true;

      final result = await securedRoleRepo.createRole(newRole);

      expect(result is Failure, true);
      expect((result as Failure).failure.message, contains('Cannot assign permissions that you do not possess'));
    });
  });

  group('createRole with real PermissionService (Integration)', () {
    test('Owner 1000 cannot create target 1000', () async {
      final realPermissionService = PermissionService();
      
      final ownerUser = AppUser(
        uid: 'owner1', email: 'owner@test.com', isSuperAdmin: false, isOwner: true, isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now()
      );
      final ownerRole = UserRole(
        id: 'r1', name: 'Owner', priority: 1000, isSystemRole: true, permissions: [], createdAt: DateTime.now(), updatedAt: DateTime.now()
      );
      final currentOwnerAppUser = CurrentAppUser(user: ownerUser, role: ownerRole);

      final repo = SecuredRoleRepository(mockRoleRepo, realPermissionService, currentOwnerAppUser, mockUserRepo);
      mockRoleRepo.getAllRolesMock = () async => const Success([]);

      final newRole = UserRole(
        id: 'new_role', name: 'NewRole', priority: 1000, isSystemRole: false, permissions: [], createdAt: DateTime.now(), updatedAt: DateTime.now()
      );

      final result = await repo.createRole(newRole);

      expect(result is Failure, true);
      expect((result as Failure).failure.message, contains('priority equal or higher'));
    });

    test('Owner 1000 cannot create target 1100', () async {
      final realPermissionService = PermissionService();
      
      final ownerUser = AppUser(
        uid: 'owner1', email: 'owner@test.com', isSuperAdmin: false, isOwner: true, isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now()
      );
      final ownerRole = UserRole(
        id: 'r1', name: 'Owner', priority: 1000, isSystemRole: true, permissions: [], createdAt: DateTime.now(), updatedAt: DateTime.now()
      );
      final currentOwnerAppUser = CurrentAppUser(user: ownerUser, role: ownerRole);

      final repo = SecuredRoleRepository(mockRoleRepo, realPermissionService, currentOwnerAppUser, mockUserRepo);
      mockRoleRepo.getAllRolesMock = () async => const Success([]);

      final newRole = UserRole(
        id: 'new_role', name: 'NewRole', priority: 1100, isSystemRole: false, permissions: [], createdAt: DateTime.now(), updatedAt: DateTime.now()
      );

      final result = await repo.createRole(newRole);

      expect(result is Failure, true);
      expect((result as Failure).failure.message, contains('priority equal or higher'));
    });

    test('Owner 1000 CAN create target 999', () async {
      final realPermissionService = PermissionService();
      
      final ownerUser = AppUser(
        uid: 'owner1', email: 'owner@test.com', isSuperAdmin: false, isOwner: true, isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now()
      );
      final ownerRole = UserRole(
        id: 'r1', name: 'Owner', priority: 1000, isSystemRole: true, permissions: [], createdAt: DateTime.now(), updatedAt: DateTime.now()
      );
      final currentOwnerAppUser = CurrentAppUser(user: ownerUser, role: ownerRole);

      final repo = SecuredRoleRepository(mockRoleRepo, realPermissionService, currentOwnerAppUser, mockUserRepo);
      mockRoleRepo.getAllRolesMock = () async => const Success([]);
      mockRoleRepo.createRoleMock = (r) async => const Success(null);

      final newRole = UserRole(
        id: 'new_role', name: 'NewRole', priority: 999, isSystemRole: false, permissions: [], createdAt: DateTime.now(), updatedAt: DateTime.now()
      );

      final result = await repo.createRole(newRole);

      expect(result is Success, true);
    });
  });

  group('deleteRole', () {
    test('should block deletion if users are assigned', () async {
      final targetRole = UserRole(
        id: 'role2',
        name: 'Worker',
        isSystemRole: false,
        isEditable: true,
        isDeletable: true,
        permissions: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockRoleRepo.getRoleByIdMock = (id) async => id == 'role2' ? Success(targetRole) : const Success(null);
      mockPermissionService.canManageRoleMock = (u, r) => true;
      
      // Simulate users assigned
      mockUserRepo.hasUsersWithRoleMock = (id) async => const Success(true);

      final result = await securedRoleRepo.deleteRole('role2');

      expect(result is Failure, true);
      expect((result as Failure).failure.message, contains('users are currently assigned'));
      // verified via logic flow
    });

    test('should allow deletion if no users are assigned', () async {
      final targetRole = UserRole(
        id: 'role2',
        name: 'Worker',
        isSystemRole: false,
        isEditable: true,
        isDeletable: true,
        permissions: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockRoleRepo.getRoleByIdMock = (id) async => id == 'role2' ? Success(targetRole) : const Success(null);
      mockPermissionService.canManageRoleMock = (u, r) => true;
      
      // Simulate no users assigned
      mockUserRepo.hasUsersWithRoleMock = (id) async => const Success(false);
      mockRoleRepo.deleteRoleMock = (id) async => const Success(null);

      final result = await securedRoleRepo.deleteRole('role2');

      expect(result is Success, true);
      // verified via return
    });
  });
}
