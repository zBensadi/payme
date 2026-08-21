import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/events/repository_event.dart';
import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/data/repositories_impl/user_repository_impl.dart';
import 'package:payme/data/repositories_impl/role_repository_impl.dart';
import 'package:payme/services/firebase_authentication_service.dart';
import 'package:payme/presentation/features/auth/controllers/firebase_auth_controller.dart';
import 'package:payme/presentation/features/auth/controllers/current_user_controller.dart';
import 'package:payme/presentation/features/auth/controllers/context_resolution_controller.dart';
import 'package:payme/presentation/providers/repository_providers.dart';

class FakeFirebaseAuthenticationService implements FirebaseAuthenticationService {
  final _controller = StreamController<AppUser?>();

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  void emitUser(AppUser? user) {
    _controller.add(user);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserRepository implements UserRepositoryImpl {
  final _eventController = StreamController<RepositoryEvent>.broadcast();
  AppUser? userToReturn;

  @override
  Stream<RepositoryEvent> watchEvents() => _eventController.stream;

  void emitEvent() {
    _eventController.add(RepositoryEvent(
      type: RepositoryEventType.remoteSynchronization,
      domain: SyncDomain.users,
      timestamp: DateTime.now().toUtc(),
    ));
  }

  @override
  Future<Result<AppUser?>> getUserById(String uid) async {
    return Success(userToReturn);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRoleRepository implements RoleRepositoryImpl {
  final _eventController = StreamController<RepositoryEvent>.broadcast();
  UserRole? roleToReturn;

  @override
  Stream<RepositoryEvent> watchEvents() => _eventController.stream;

  void emitEvent() {
    _eventController.add(RepositoryEvent(
      type: RepositoryEventType.remoteSynchronization,
      domain: SyncDomain.roles,
      timestamp: DateTime.now().toUtc(),
    ));
  }

  @override
  Future<Result<UserRole?>> getRoleById(String id) async {
    return Success(roleToReturn);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class FakeContextResolutionController extends Notifier<ContextResolutionData> implements ContextResolutionController {
  final AppUser? initialUser;
  FakeContextResolutionController(this.initialUser);

  @override
  ContextResolutionData build() {
    return ContextResolutionData(state: ContextResolutionState.approved, user: initialUser);
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('current_user_controller rebuilds on role repository events without new auth state changes', () async {
    final fakeAuthService = FakeFirebaseAuthenticationService();
    final fakeUserRepository = FakeUserRepository();
    final fakeRoleRepository = FakeRoleRepository();

    final initialDate = DateTime.now().toUtc();
    
    final appUser = AppUser(
      uid: 'uid1',
      email: 'test@test.com',
      businessId: 'b1',
      roleId: 'role1',
      isSuperAdmin: false,
      isActive: true,
      createdAt: initialDate,
      updatedAt: initialDate,
    );

    final container = ProviderContainer(
      overrides: [
        firebaseAuthServiceProvider.overrideWithValue(fakeAuthService),
        internalUserRepositoryProvider.overrideWithValue(fakeUserRepository),
        internalRoleRepositoryProvider.overrideWithValue(fakeRoleRepository),
        contextResolutionProvider.overrideWith(() => FakeContextResolutionController(appUser)),
      ],
    );
    addTearDown(container.dispose);

    final initialRole = UserRole(
      id: 'role1',
      name: 'Admin',
      isSystemRole: false,
      permissions: ['accounting_years.view', 'accounting_years.manage'],
      priority: 999,
      createdAt: initialDate,
      updatedAt: initialDate,
    );

    fakeUserRepository.userToReturn = appUser;
    fakeRoleRepository.roleToReturn = initialRole;

    // Listen to the provider to start the stream
    final sub = container.listen(currentUserProvider, (_, _) {});

    // Emit initial auth state
    fakeAuthService.emitUser(appUser);
    
    // Wait for provider to resolve
    await Future.delayed(const Duration(milliseconds: 100));
    
    final initialCurrentUser = container.read(currentUserProvider).value;
    expect(initialCurrentUser, isNotNull);
    expect(initialCurrentUser!.role.permissions.contains('accounting_years.manage'), isTrue);

    // 2. Simulate role update via sync (different updatedAt, removed permission)
    final updatedRole = initialRole.copyWith(
      permissions: ['accounting_years.view'],
      updatedAt: initialDate.add(const Duration(minutes: 1)),
    );
    fakeRoleRepository.roleToReturn = updatedRole;

    // Trigger role sync event WITHOUT triggering authStateChanges!
    fakeRoleRepository.emitEvent();

    // wait for provider to process
    await Future.delayed(const Duration(milliseconds: 100));

    final updatedCurrentUser = container.read(currentUserProvider).value;
    expect(updatedCurrentUser, isNotNull);
    
    // The current user role should now reflect the missing permission!
    expect(updatedCurrentUser!.role.permissions.contains('accounting_years.manage'), isFalse);
    expect(updatedCurrentUser.role.permissions.contains('accounting_years.view'), isTrue);

    sub.close();
  });
}
