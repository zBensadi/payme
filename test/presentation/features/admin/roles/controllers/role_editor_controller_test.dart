import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/error/failures.dart';
import 'package:payme/presentation/providers/repository_providers.dart';
import 'package:payme/presentation/providers/permission_service_provider.dart';
import 'package:payme/presentation/features/auth/controllers/current_user_controller.dart';
import 'package:payme/presentation/features/admin/roles/controllers/role_editor_controller.dart';
import 'package:payme/domain/repositories/role_repository.dart';
import 'package:payme/core/security/permission_service.dart';
import 'package:payme/presentation/features/admin/roles/controllers/role_list_controller.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/current_app_user.dart';

class FakeRoleRepository implements RoleRepository {
  final Map<String, UserRole> roles = {};
  bool failDelete = false;
  int createCalls = 0;
  int updateCalls = 0;

  @override
  Future<Result<UserRole?>> getRoleById(String id) async {
    if (roles.containsKey(id)) {
      return Success(roles[id]);
    }
    return const Success(null);
  }



  @override
  Future<Result<List<UserRole>>> getAllRoles() async {
    return Success(roles.values.toList());
  }

  @override
  Future<Result<UserRole>> createRole(UserRole role) async {
    createCalls++;
    roles[role.id] = role;
    return Success(role);
  }

  @override
  Future<Result<UserRole>> updateRole(UserRole role) async {
    updateCalls++;
    roles[role.id] = role;
    return Success(role);
  }

  @override
  Future<Result<void>> deleteRole(String id) async {
    if (failDelete) {
      return const Failure(DatabaseFailure('Delete failed'));
    }
    roles.remove(id);
    return const Success(null);
  }
}

class FakePermissionService implements PermissionService {
  @override
  bool hasPermission(CurrentAppUser? user, String permission) => true;

  @override
  bool canManageRole(CurrentAppUser? user, UserRole targetRole) => true;

  @override
  bool canAssignRole(CurrentAppUser? currentUser, UserRole roleToAssign) => true;

  @override
  bool canDeleteUser(CurrentAppUser? currentUser, AppUser targetUser, UserRole targetRole) => true;

  @override
  bool canEditUser(CurrentAppUser? currentUser, AppUser targetUser, UserRole targetRole) => true;

  @override
  bool canManageOwner(CurrentAppUser? currentUser) => true;
}

class MockRoleListController extends RoleListController {
  @override
  RoleListState build() => const RoleListState(roles: [], isLoading: false);
  @override
  Future<void> loadRoles() async {}
}

void main() {
  late FakeRoleRepository fakeRoleRepo;
  late FakePermissionService fakePermissionService;
  late ProviderContainer container;
  late UserRole testUserRole;
  late AppUser testUser;

  setUp(() {
    fakeRoleRepo = FakeRoleRepository();
    fakePermissionService = FakePermissionService();

    testUserRole = UserRole(
      id: 'role-owner',
      name: 'Owner',
      priority: 1000,
      isSystemRole: true,
      isEditable: false,
      isDeletable: false,
      permissions: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testUser = AppUser(
      uid: 'user-owner',
      email: 'owner@example.com',
      isSuperAdmin: false,
      isOwner: true,
      isActive: true,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    container = ProviderContainer(
      overrides: [
        roleRepositoryProvider.overrideWithValue(fakeRoleRepo),
        permissionServiceProvider.overrideWithValue(fakePermissionService),
        currentUserProvider.overrideWith((ref) async* { yield CurrentAppUser(user: testUser, role: testUserRole); }),
        roleListControllerProvider.overrideWith(MockRoleListController.new),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('RoleEditorController Priority Enforcement', () {
    setUp(() async {
      container.listen(currentUserProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
    });
    

    test('1. Owner 1000 -> 999 accepted (Create)', () async {
      final controller = container.read(roleEditorControllerProvider.notifier);
      
      controller.init('new');
      await controller.loadRole();
      
      final state = container.read(roleEditorControllerProvider);
      expect(state.maxAllowedPriorityValue, 999);
      
      final newRole = state.role!.copyWith(name: 'Valid Role', priority: 999);
      
      final success = await controller.saveRole(newRole);
      expect(success, true);
      expect(fakeRoleRepo.createCalls, 1);
    });

    test('2. Owner 1000 -> 1000 rejected (Create)', () async {
      final controller = container.read(roleEditorControllerProvider.notifier);
      
      controller.init('new');
      await controller.loadRole();
      
      final state = container.read(roleEditorControllerProvider);
      final newRole = state.role!.copyWith(name: 'Invalid Role', priority: 1000);
      
      final success = await controller.saveRole(newRole);
      expect(success, false);
      expect(fakeRoleRepo.createCalls, 0);
      
      final updatedState = container.read(roleEditorControllerProvider);
      expect(updatedState.error, 'Priority value cannot be higher than 999.');
    });

    test('3. Owner 1000 -> 1100 rejected (Create)', () async {
      final controller = container.read(roleEditorControllerProvider.notifier);
      
      controller.init('new');
      await controller.loadRole();
      
      final state = container.read(roleEditorControllerProvider);
      final newRole = state.role!.copyWith(name: 'Invalid Role', priority: 1100);
      
      final success = await controller.saveRole(newRole);
      expect(success, false);
      expect(fakeRoleRepo.createCalls, 0);
      
      final updatedState = container.read(roleEditorControllerProvider);
      expect(updatedState.error, 'Priority value cannot be higher than 999.');
    });

    test('4. Validation error is surfaced correctly', () async {
      final controller = container.read(roleEditorControllerProvider.notifier);
      
      controller.init('new');
      await controller.loadRole();
      
      final state = container.read(roleEditorControllerProvider);
      final newRole = state.role!.copyWith(name: 'Invalid Role', priority: 1500);
      
      await controller.saveRole(newRole);
      
      final updatedState = container.read(roleEditorControllerProvider);
      expect(updatedState.error, 'Priority value cannot be higher than 999.');
    });

    test('5. Create and update both use the same priority boundary', () async {
      // Setup an existing role to update
      final existingRole = UserRole(
        id: 'role-A', 
        name: 'Role A', 
        priority: 50, 
        isSystemRole: false, 
        isEditable: true, 
        isDeletable: true, 
        permissions: [], 
        createdAt: DateTime.now(), 
        updatedAt: DateTime.now(),
      );
      fakeRoleRepo.roles['role-A'] = existingRole;

      final controller = container.read(roleEditorControllerProvider.notifier);
      
      // Test Update -> 999 (Allowed)
      controller.init('role-A');
      await controller.loadRole();
      
      var state = container.read(roleEditorControllerProvider);
      expect(state.maxAllowedPriorityValue, 999); // boundary is the same
      
      var updateRole = state.role!.copyWith(priority: 999);
      var success = await controller.saveRole(updateRole);
      expect(success, true);
      expect(fakeRoleRepo.updateCalls, 1);

      // Test Update -> 1000 (Rejected)
      updateRole = state.role!.copyWith(priority: 1000);
      success = await controller.saveRole(updateRole);
      expect(success, false);
      expect(fakeRoleRepo.updateCalls, 1); // no new call
      
      state = container.read(roleEditorControllerProvider);
      expect(state.error, 'Priority value cannot be higher than 999.');
    });
  });
}
