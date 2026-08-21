import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/core/database/database_provider.dart';
import 'package:payme/core/database/database_service.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/services/firebase_authentication_service.dart';
import 'package:payme/presentation/features/auth/controllers/context_resolution_controller.dart';
import 'package:payme/presentation/features/auth/controllers/firebase_auth_controller.dart';
import 'package:payme/presentation/features/auth/controllers/bootstrap_controller.dart';
import 'package:payme/domain/repositories/bootstrap_repository.dart';
import 'package:payme/core/error/result.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

// Mocks
class MockDatabaseService implements DatabaseService {
  int dirtyCount = 0;
  bool hasData = false;
  AppMeta? appMeta;
  bool wipeAndCloseCalled = false;
  bool adminCredentialDeleted = false;

  @override
  Future<int> getTotalDirtyCount() async => dirtyCount;

  @override
  Future<bool> hasAnyDomainData() async => hasData;

  @override
  Future<AppMeta?> getAppMeta() async => appMeta;

  @override
  Future<void> updateAppMeta({String? businessId, String? uid}) async {
    appMeta = AppMeta(schemaVersion: 15, currentBusinessId: businessId, currentUid: uid);
  }

  @override
  Future<void> wipeAndClose() async {
    wipeAndCloseCalled = true;
  }

  @override
  Database get db => MockDb(this) as Database;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDb implements Database {
  final MockDatabaseService parent;
  MockDb(this.parent);
  
  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    if (table == 'admin_credential') parent.adminCredentialDeleted = true;
    return 1;
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthService implements FirebaseAuthenticationService {
  final _controller = StreamController<AppUser?>();
  AppUser? currentUserToEmit;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  AppUser? get currentUser => currentUserToEmit;

  void emit(AppUser? user) {
    currentUserToEmit = user;
    _controller.add(user);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBootstrapRepo implements BootstrapRepository {
  @override
  Future<Result<BootstrapResult?>> checkExistingBusiness({required String uid, required String email}) async {
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Subclass to bypass FirebaseAuth.instance.currentUser checking inside the controller
class TestableContextResolutionController extends ContextResolutionController {
  final String? mockAuthBusinessId;
  TestableContextResolutionController(this.mockAuthBusinessId);

  @override
  Future<String?> fetchAuthBusinessId(String uid) async {
    return mockAuthBusinessId;
  }
}

void main() {
  late MockDatabaseService mockDb;
  late MockBootstrapRepo mockBootstrap;
  
  setUp(() {
    mockDb = MockDatabaseService();
    mockBootstrap = MockBootstrapRepo();
  });

  ProviderContainer createContainer(String? mockAuthBusinessId) {
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        bootstrapRepositoryProvider.overrideWithValue(mockBootstrap),
        contextResolutionProvider.overrideWith(
          () => TestableContextResolutionController(mockAuthBusinessId),
        ),
        // Dummy mock for auth service since we don't trigger via authStateChanges in these direct tests
        firebaseAuthServiceProvider.overrideWithValue(MockAuthService()),
      ],
    );
  }

  // We expose a helper to call the protected _resolveContext method
  // However, _resolveContext is private. We can test it by manually modifying state if it was public,
  // OR we can trigger it by simulating the authService change!
  // Wait, ContextResolutionController listens to firebaseAuthServiceProvider.
  // Let's use the MockAuthService to emit the user!
  
  Future<ContextResolutionState> runResolution(ProviderContainer container, AppUser user) async {
    final mockAuth = container.read(firebaseAuthServiceProvider) as MockAuthService;
    // Listen to the provider so it initializes
    container.listen(contextResolutionProvider, (_, _) {});
    
    // Emit user
    mockAuth.emit(user);
    
    // Wait for resolution
    await Future.delayed(const Duration(milliseconds: 100));
    return container.read(contextResolutionProvider).state;
  }

  AppUser createTestUser(String uid) {
    return AppUser(
      uid: uid,
      email: 'test@test.com',
      isSuperAdmin: false,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('ContextResolution Security Regression Tests', () {
    
    test('TEST 1: Existing Business A database, New Firebase user B (no businessId claim) -> contextSwitchPending', () async {
      mockDb.hasData = true;
      mockDb.dirtyCount = 5;
      await mockDb.updateAppMeta(businessId: 'A_ID', uid: 'UID_A');
      
      final container = createContainer(null); // No authBusinessId
      final userB = createTestUser('UID_B');
      
      final state = await runResolution(container, userB);
      
      expect(state, ContextResolutionState.contextSwitchPending);
      expect(mockDb.appMeta?.currentBusinessId, 'A_ID'); // AppMeta should NOT be mutated!
    });

    test('TEST 2: Empty/new local database, New Firebase user B (no businessId claim) -> bootstrapping', () async {
      mockDb.hasData = false;
      mockDb.dirtyCount = 0;
      await mockDb.updateAppMeta(businessId: null, uid: null); // Fresh DB
      
      final container = createContainer(null); // No authBusinessId
      final userB = createTestUser('UID_B');
      
      final state = await runResolution(container, userB);
      
      expect(state, ContextResolutionState.bootstrapping);
      expect(mockDb.appMeta?.currentBusinessId, isNull);
      expect(mockDb.appMeta?.currentUid, 'UID_B');
    });

    test('TEST 4: Bootstrap succeeds -> markBootstrapped establishes context', () async {
      mockDb.hasData = false;
      await mockDb.updateAppMeta(businessId: null, uid: 'UID_B');
      
      final container = createContainer(null);
      final userB = createTestUser('UID_B');
      await runResolution(container, userB); // Enters bootstrapping
      
      // Simulate bootstrap success
      final controller = container.read(contextResolutionProvider.notifier);
      await controller.markBootstrapped('B_ID');
      
      final finalState = container.read(contextResolutionProvider);
      expect(finalState.state, ContextResolutionState.approved);
      expect(mockDb.appMeta?.currentBusinessId, 'B_ID');
      expect(mockDb.appMeta?.currentUid, 'UID_B');
    });

    test('TEST 5: Same business + different Firebase UID -> Retain data, clear admin_credential', () async {
      mockDb.hasData = true;
      await mockDb.updateAppMeta(businessId: 'B_ID', uid: 'UID_OLD');
      
      final container = createContainer('B_ID'); // Has businessId
      final userNew = createTestUser('UID_NEW');
      
      final state = await runResolution(container, userNew);
      
      expect(state, ContextResolutionState.approved);
      expect(mockDb.adminCredentialDeleted, isTrue);
      expect(mockDb.appMeta?.currentUid, 'UID_NEW');
    });

    test('TEST 6: Existing user + valid businessId claim + different business -> contextSwitchPending', () async {
      mockDb.hasData = true;
      mockDb.dirtyCount = 1;
      await mockDb.updateAppMeta(businessId: 'A_ID', uid: 'UID_A');
      
      final container = createContainer('B_ID'); // Different business
      final userB = createTestUser('UID_B');
      
      final state = await runResolution(container, userB);
      
      expect(state, ContextResolutionState.contextSwitchPending);
      expect(mockDb.appMeta?.currentBusinessId, 'A_ID'); // AppMeta preserved
    });

  });
}
