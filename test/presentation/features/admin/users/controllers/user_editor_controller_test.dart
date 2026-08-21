import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/error/failures.dart';
import 'package:payme/core/security/permission_service.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/current_app_user.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/domain/repositories/role_repository.dart';
import 'package:payme/domain/repositories/user_repository.dart';
import 'package:payme/presentation/features/admin/users/controllers/user_editor_controller.dart';
import 'package:payme/presentation/features/auth/controllers/current_user_controller.dart';
import 'package:payme/presentation/providers/permission_service_provider.dart';
import 'package:payme/presentation/providers/repository_providers.dart';
import 'package:payme/services/user_provisioning_service.dart';

class FakeUserRepository implements UserRepository {
  final Map<String, AppUser> users = {};
  
  @override
  Future<Result<AppUser?>> getUserById(String uid) async {
    return Success(users[uid]);
  }

  @override
  Future<Result<List<AppUser>>> getAllUsers() async {
    return Success(users.values.toList());
  }

  @override
  Future<Result<bool>> hasUsersWithRole(String roleId) async => const Success(false);

  @override
  Future<Result<void>> createUser(AppUser user) async {
    users[user.uid] = user;
    return const Success(null);
  }

  @override
  Future<Result<void>> updateUser(AppUser user) async {
    users[user.uid] = user;
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteUser(String id) async {
    users.remove(id);
    return const Success(null);
  }
}

class FakeRoleRepository implements RoleRepository {
  final List<UserRole> roles = [];
  @override
  Future<Result<List<UserRole>>> getAllRoles() async => Success(roles);
  @override
  Future<Result<UserRole?>> getRoleById(String id) async => const Success(null);
  @override
  Future<Result<UserRole>> createRole(UserRole role) async => Success(role);
  @override
  Future<Result<UserRole>> updateRole(UserRole role) async => Success(role);
  @override
  Future<Result<void>> deleteRole(String id) async => const Success(null);
}

class FakeUserProvisioningService implements UserProvisioningService {
  int provisionCalls = 0;
  bool shouldFail = false;

  @override
  Future<Result<void>> provisionUser(AppUser user, String password) async {
    if (shouldFail) return const Failure(AuthFailure('Mock provisioning failure'));
    provisionCalls++;
    return const Success(null);
  }

  @override
  Future<Result<void>> reactivateUser(String uid) async {
    if (shouldFail) return const Failure(AuthFailure('Mock reactivation failure'));
    return const Success(null);
  }
}

class FakePermissionService implements PermissionService {
  @override
  bool hasPermission(CurrentAppUser? user, String permission) => true;
  @override
  bool canManageRole(CurrentAppUser? user, UserRole targetRole) => true;
  @override
  bool canAssignRole(CurrentAppUser? currentUser, UserRole roleToAssign) {
    return roleToAssign.priority < 1000;
  }
  @override
  bool canDeleteUser(CurrentAppUser? currentUser, AppUser targetUser, UserRole targetRole) => true;
  @override
  bool canEditUser(CurrentAppUser? currentUser, AppUser targetUser, UserRole targetRole) => true;
  @override
  bool canManageOwner(CurrentAppUser? currentUser) => true;
}

void main() {
  late FakeUserRepository fakeUserRepo;
  late FakeRoleRepository fakeRoleRepo;
  late FakeUserProvisioningService fakeProvisioningService;
  late FakePermissionService fakePermissionService;
  late ProviderContainer container;

  final ownerUser = AppUser(
    uid: 'owner-uid',
    email: 'owner@example.com',
    businessId: 'biz-1',
    isSuperAdmin: false,
    isOwner: true,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final ownerRole = UserRole(
    id: 'role-owner',
    name: 'Owner',
    isSystemRole: true,
    permissions: [],
    priority: 1000,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final adminRole = UserRole(
    id: 'role-admin',
    name: 'Admin',
    isSystemRole: true,
    permissions: [],
    priority: 800,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final currentAppUser = CurrentAppUser(user: ownerUser, role: ownerRole);

  setUp(() async {
    fakeUserRepo = FakeUserRepository();
    fakeRoleRepo = FakeRoleRepository();
    fakeRoleRepo.roles.addAll([ownerRole, adminRole]);
    fakeProvisioningService = FakeUserProvisioningService();
    fakePermissionService = FakePermissionService();

    container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(fakeUserRepo),
        roleRepositoryProvider.overrideWithValue(fakeRoleRepo),
        userProvisioningServiceProvider.overrideWithValue(fakeProvisioningService),
        permissionServiceProvider.overrideWithValue(fakePermissionService),
        currentUserProvider.overrideWith((ref) async* { yield currentAppUser; }),
      ],
    );
    container.listen(currentUserProvider, (_, _) {});
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() {
    container.dispose();
  });

  test('init(new) sets up blank user and loads assignable roles', () async {
    final controller = container.read(userEditorControllerProvider.notifier);
    controller.init('new');
    await controller.loadUser();

    final state = container.read(userEditorControllerProvider);
    
    expect(state.isLoading, isFalse);
    expect(state.isNewUser, isTrue);
    expect(state.user, isNotNull);
    expect(state.user!.uid, isEmpty);
    expect(state.user!.businessId, 'biz-1');
    expect(state.canEdit, isTrue);
    expect(state.canDelete, isFalse);
    
    // Only Admin role should be assignable (Owner priority = 1000, Admin = 800)
    expect(state.availableRoles.length, 1);
    expect(state.availableRoles.first.id, 'role-admin');
  });

  test('saveNewUser with duplicate email returns false and sets error', () async {
    final controller = container.read(userEditorControllerProvider.notifier);
    controller.init('new');
    await controller.loadUser();

    fakeUserRepo.users['existing'] = AppUser(
      uid: 'existing',
      email: 'test@test.com',
      businessId: 'biz-1',
      isSuperAdmin: false,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await controller.saveNewUser(
      email: 'Test@Test.com',
      displayName: 'Test User',
      password: 'password123',
      roleId: 'role-admin'
    );

    expect(success, isFalse);
    final state = container.read(userEditorControllerProvider);
    expect(state.error, contains('Email already exists locally'));
    expect(fakeProvisioningService.provisionCalls, 0);
  });

  test('saveNewUser successfully provisions user', () async {
    final controller = container.read(userEditorControllerProvider.notifier);
    controller.init('new');
    await controller.loadUser();

    final success = await controller.saveNewUser(
      email: 'new@example.com',
      displayName: 'New User',
      password: 'password123',
      roleId: 'role-admin'
    );

    expect(success, isTrue);
    final state = container.read(userEditorControllerProvider);
    expect(state.error, isNull);
    expect(fakeProvisioningService.provisionCalls, 1);
  });

  test('Existing A -> New clears state (simulated by container invalidate)', () async {
    final controllerA = container.read(userEditorControllerProvider.notifier);
    controllerA.init('existing-A');
    await controllerA.loadUser();

    // In UI, popping the screen destroys the AutoDisposeProvider. We simulate this:
    container.invalidate(userEditorControllerProvider);

    final controllerNew = container.read(userEditorControllerProvider.notifier);
    controllerNew.init('new');
    await controllerNew.loadUser();

    final state = container.read(userEditorControllerProvider);
    expect(state.isNewUser, isTrue);
    expect(state.user!.uid, isEmpty);
  });

  test('Existing A -> Existing B loads B', () async {
    fakeUserRepo.users['A'] = AppUser(uid: 'A', email: 'a@a.com', businessId: 'biz-1', isSuperAdmin: false, isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now());
    fakeUserRepo.users['B'] = AppUser(uid: 'B', email: 'b@b.com', businessId: 'biz-1', isSuperAdmin: false, isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now());

    final controllerA = container.read(userEditorControllerProvider.notifier);
    controllerA.init('A');
    await controllerA.loadUser();
    
    container.invalidate(userEditorControllerProvider);

    final controllerB = container.read(userEditorControllerProvider.notifier);
    controllerB.init('B');
    await controllerB.loadUser();

    final state = container.read(userEditorControllerProvider);
    expect(state.isNewUser, isFalse);
    expect(state.user!.uid, 'B');
  });

  test('Existing user loads correct role', () async {
    fakeUserRepo.users['A'] = AppUser(uid: 'A', email: 'a@a.com', businessId: 'biz-1', isSuperAdmin: false, isActive: true, roleId: 'role-admin', createdAt: DateTime.now(), updatedAt: DateTime.now());

    final controller = container.read(userEditorControllerProvider.notifier);
    controller.init('A');
    await controller.loadUser();

    final state = container.read(userEditorControllerProvider);
    expect(state.currentRole!.id, 'role-admin');
  });

  test('Owner can edit ordinary user', () async {
    fakeUserRepo.users['A'] = AppUser(uid: 'A', email: 'a@a.com', businessId: 'biz-1', isSuperAdmin: false, isActive: true, roleId: 'role-admin', createdAt: DateTime.now(), updatedAt: DateTime.now());

    final controller = container.read(userEditorControllerProvider.notifier);
    controller.init('A');
    await controller.loadUser();

    final state = container.read(userEditorControllerProvider);
    expect(state.canEdit, isTrue);
  });

  test('Display name update succeeds', () async {
    fakeUserRepo.users['A'] = AppUser(uid: 'A', email: 'a@a.com', businessId: 'biz-1', isSuperAdmin: false, isActive: true, roleId: 'role-admin', createdAt: DateTime.now(), updatedAt: DateTime.now());

    final controller = container.read(userEditorControllerProvider.notifier);
    controller.init('A');
    await controller.loadUser();

    final success = await controller.updateUser(displayName: 'Updated Name');
    expect(success, isTrue);
    
    final state = container.read(userEditorControllerProvider);
    expect(state.user!.displayName, 'Updated Name');
    expect(state.isSaving, isFalse);
  });

  test('Update failure resets isSaving', () async {
    fakeUserRepo.users['A'] = AppUser(uid: 'A', email: 'a@a.com', businessId: 'biz-1', isSuperAdmin: false, isActive: true, roleId: 'role-admin', createdAt: DateTime.now(), updatedAt: DateTime.now());

    // Let's just create a quick mock inline:
    final containerFail = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWith((ref) => _FailUpdateUserRepo()),
        roleRepositoryProvider.overrideWithValue(fakeRoleRepo),
        userProvisioningServiceProvider.overrideWithValue(fakeProvisioningService),
        permissionServiceProvider.overrideWithValue(fakePermissionService),
        currentUserProvider.overrideWith((ref) async* { yield currentAppUser; }),
      ],
    );

    final controller = containerFail.read(userEditorControllerProvider.notifier);
    controller.init('A');
    await controller.loadUser();

    final success = await controller.updateUser(displayName: 'Failed Name'); 
    expect(success, isFalse);
    
    final state = containerFail.read(userEditorControllerProvider);
    expect(state.isSaving, isFalse);
    expect(state.error, isNotNull);
  });
}

class _FailUpdateUserRepo extends FakeUserRepository {
  @override
  Future<Result<void>> updateUser(AppUser user) async {
    return const Failure(DatabaseFailure('Mock update failure'));
  }
}




