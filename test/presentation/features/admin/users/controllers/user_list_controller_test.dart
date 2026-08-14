import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/presentation/features/admin/users/controllers/user_list_controller.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/domain/repositories/user_repository.dart';
import 'package:payme/domain/repositories/role_repository.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/presentation/providers/repository_providers.dart';

class FakeUserRepository implements UserRepository {
  @override
  Future<Result<List<AppUser>>> getAllUsers({bool forceRefresh = false}) async {
    return Success([
      AppUser(
        uid: '1',
        email: 'active@test.com',
        businessId: 'biz1', isSuperAdmin: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      AppUser(
        uid: '2',
        email: 'inactive@test.com',
        businessId: 'biz1', isSuperAdmin: false,
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      AppUser(
        uid: '3',
        email: 'deleted@test.com',
        businessId: 'biz1', isSuperAdmin: false,
        isActive: false,
        isDeleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRoleRepository implements RoleRepository {
  @override
  Future<Result<List<UserRole>>> getAllRoles({bool forceRefresh = false}) async {
    return const Success([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('UserListController includes inactive users by default and excludes soft-deleted', () async {
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(FakeUserRepository()),
        roleRepositoryProvider.overrideWithValue(FakeRoleRepository()),
      ],
    );

    final controller = container.read(userListControllerProvider.notifier);
    
    // Wait for the microtask loadData to finish
    await Future.delayed(const Duration(milliseconds: 100));

    final state = container.read(userListControllerProvider);
    
    expect(state.isLoading, isFalse);
    expect(state.showInactive, isTrue); // Should be true by default
    
    // filteredUsers should contain active (uid 1) and inactive (uid 2), but not deleted (uid 3)
    expect(state.filteredUsers.length, equals(2));
    expect(state.filteredUsers.any((u) => u.uid == '1'), isTrue);
    expect(state.filteredUsers.any((u) => u.uid == '2'), isTrue);
    expect(state.filteredUsers.any((u) => u.uid == '3'), isFalse);
  });
}

