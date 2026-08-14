import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/error/failures.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/security/permission_service.dart';
import 'package:payme/data/repositories_impl/secured/secured_accounting_year_repository.dart';
import 'package:payme/domain/entities/accounting_year.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/current_app_user.dart';
import 'package:payme/domain/entities/permissions.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/domain/repositories/accounting_year_repository.dart';

class FakeAccountingYearRepository implements AccountingYearRepository {
  @override
  Future<Result<AccountingYear>> create(String name) async {
    return Success(AccountingYear(id: '1', name: name, isActive: false, createdAt: DateTime.now(), updatedAt: DateTime.now()));
  }

  @override
  Future<Result<void>> delete(String id) async => const Success(null);

  @override
  Future<Result<AccountingYear?>> getActive() async => const Success(null);

  @override
  Future<Result<List<AccountingYear>>> getAll() async => const Success([]);

  @override
  Future<Result<void>> rename(String id, String newName) async => const Success(null);

  @override
  Future<Result<void>> setActive(String id) async => const Success(null);
}

void main() {
  late FakeAccountingYearRepository fakeRepo;
  late PermissionService permissionService;

  setUp(() {
    fakeRepo = FakeAccountingYearRepository();
    permissionService = PermissionService();
  });

  CurrentAppUser createUser(List<String> permissions, {bool isOwner = false}) {
    final now = DateTime.now();
    return CurrentAppUser(
      user: AppUser(
        uid: 'uid',
        email: 'test@test.com',
        businessId: 'b1',
        isSuperAdmin: false,
        isActive: true,
        isOwner: isOwner,
        createdAt: now,
        updatedAt: now,
      ),
      role: UserRole(
        id: 'role1',
        name: 'Test Role',
        isSystemRole: false,
        permissions: permissions,
        priority: 10,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('SecuredAccountingYearRepository Security Matrix Tests', () {
    test('User has view + manage -> all operations succeed', () async {
      final user = createUser([Permissions.accountingYearsView, Permissions.accountingYearsManage]);
      final securedRepo = SecuredAccountingYearRepository(fakeRepo, permissionService, user);

      expect((await securedRepo.getAll()) is Success, isTrue);
      expect((await securedRepo.getActive()) is Success, isTrue);
      expect((await securedRepo.create('Test')) is Success, isTrue);
      expect((await securedRepo.rename('1', 'Test')) is Success, isTrue);
      expect((await securedRepo.setActive('1')) is Success, isTrue);
      expect((await securedRepo.delete('1')) is Success, isTrue);
    });

    test('User lacks view -> reads fail with AuthFailure', () async {
      final user = createUser([Permissions.accountingYearsManage]);
      final securedRepo = SecuredAccountingYearRepository(fakeRepo, permissionService, user);

      final result1 = await securedRepo.getAll();
      expect(result1 is Failure, isTrue);
      expect((result1 as Failure).failure is AuthFailure, isTrue);

      final result2 = await securedRepo.getActive();
      expect(result2 is Failure, isTrue);
      expect((result2 as Failure).failure is AuthFailure, isTrue);
    });

    test('User has view but lacks manage -> reads succeed, mutations fail with AuthFailure', () async {
      final user = createUser([Permissions.accountingYearsView]);
      final securedRepo = SecuredAccountingYearRepository(fakeRepo, permissionService, user);

      // Reads succeed
      expect((await securedRepo.getAll()) is Success, isTrue);
      expect((await securedRepo.getActive()) is Success, isTrue);

      // Mutations fail
      final result1 = await securedRepo.create('Test');
      expect(result1 is Failure, isTrue);
      expect((result1 as Failure).failure is AuthFailure, isTrue);

      final result2 = await securedRepo.rename('1', 'Test2');
      expect(result2 is Failure, isTrue);
      expect((result2 as Failure).failure is AuthFailure, isTrue);

      final result3 = await securedRepo.setActive('1');
      expect(result3 is Failure, isTrue);
      expect((result3 as Failure).failure is AuthFailure, isTrue);

      final result4 = await securedRepo.delete('1');
      expect(result4 is Failure, isTrue);
      expect((result4 as Failure).failure is AuthFailure, isTrue);
    });

    test('User lacks both -> all operations fail', () async {
      final user = createUser([]);
      final securedRepo = SecuredAccountingYearRepository(fakeRepo, permissionService, user);

      expect((await securedRepo.getAll()) is Failure, isTrue);
      expect((await securedRepo.create('Test')) is Failure, isTrue);
    });

    test('Owner -> all operations succeed regardless of role permissions', () async {
      final user = createUser([], isOwner: true);
      final securedRepo = SecuredAccountingYearRepository(fakeRepo, permissionService, user);

      expect((await securedRepo.getAll()) is Success, isTrue);
      expect((await securedRepo.create('Test')) is Success, isTrue);
    });
  });
}
