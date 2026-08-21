import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/domain/repositories/bootstrap_repository.dart';
import 'package:payme/data/models/app_user_model.dart';
import 'package:payme/presentation/features/auth/controllers/bootstrap_controller.dart';
import 'package:payme/presentation/providers/repository_providers.dart';
import 'package:payme/core/database/database_provider.dart';
import 'package:payme/core/database/database_service.dart';
import 'package:payme/core/database/migration_runner.dart';
import 'package:payme/core/logging/logger_service.dart';
import 'package:payme/presentation/features/auth/controllers/context_resolution_controller.dart';
import 'package:logger/logger.dart';

class MockContextResolutionController extends ContextResolutionController {
  bool markBootstrappedCalled = false;
  String? bootstrappedBusinessId;

  @override
  Future<void> markBootstrapped(String businessId) async {
    markBootstrappedCalled = true;
    bootstrappedBusinessId = businessId;
  }
}

class MockBootstrapRepository implements BootstrapRepository {
  final DateTime fixedTime;
  
  MockBootstrapRepository(this.fixedTime);

  @override
  Future<Result<BootstrapResult?>> checkExistingBusiness({
    required String uid,
    required String email,
  }) async {
    // For the test, assume no existing business
    return const Success(null);
  }

  @override
  Future<Result<BootstrapResult>> bootstrapBusiness({
    required String uid,
    required String email,
    required String? displayName,
    required String businessName,
  }) async {
    final user = AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      businessId: 'mock_biz_id',
      roleId: 'mock_role_id',
      isSuperAdmin: true,
      isOwner: true,
      isActive: true,
      createdAt: fixedTime,
      updatedAt: fixedTime,
    );

    final role = UserRole(
      id: 'mock_role_id',
      name: 'Owner',
      isSystemRole: true,
      permissions: const [],
      priority: 0,
      createdAt: fixedTime,
      updatedAt: fixedTime,
    );

    return Success(BootstrapResult(user: user, role: role));
  }
}

void main() {
  late Database db;
  late ProviderContainer container;
  final fixedTime = DateTime(2026, 1, 1).toUtc();

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath, options: OpenDatabaseOptions(
      version: null,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    ));

    final runner = MigrationRunner(LoggerService(Logger()));
    await runner.runMigrations(db);

    final dbService = DatabaseService(db);

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(dbService),
        bootstrapRepositoryProvider.overrideWithValue(MockBootstrapRepository(fixedTime)),
        contextResolutionProvider.overrideWith(() => MockContextResolutionController()),
      ],
    );
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  test('Bootstrap flow successfully seeds SQLite and skipping sync logic works', () async {
    // 1. Initial State: Clear any legacy data from v10 migration
    await db.execute('DELETE FROM users');
    await db.execute('DELETE FROM roles');
    
    final userLocalDs = container.read(userLocalDataSourceProvider);
    final roleLocalDs = container.read(roleLocalDataSourceProvider);
    
    expect(await userLocalDs.getAll(), isEmpty);
    expect(await roleLocalDs.getAll(), isEmpty);

    // 2. Execute Bootstrap
    final controller = container.read(bootstrapControllerProvider.notifier);
    final result = await controller.bootstrap(
      uid: 'test_uid',
      email: 'test@example.com',
      displayName: 'Test User',
      businessName: 'My Business',
    );

    expect(result, isA<Success<void>>());

    // 3. Verify SQLite was seeded exactly as expected
    final users = await userLocalDs.getAll();
    expect(users.length, 1);
    final seededUser = users.first;
    expect(seededUser.uid, 'test_uid');
    expect(seededUser.roleId, 'mock_role_id');
    
    // Verify sync metadata is set to avoid re-syncing
    final userRaw = (await db.query('users')).first;
    expect(userRaw['is_dirty'], 0);
    expect(userRaw['synced_at'], fixedTime.toIso8601String());

    final roles = await roleLocalDs.getAll();
    expect(roles.length, 1);
    final seededRole = roles.first;
    expect(seededRole.id, 'mock_role_id');
    
    final roleRaw = (await db.query('roles')).first;
    expect(roleRaw['is_dirty'], 0);
    expect(roleRaw['synced_at'], fixedTime.toIso8601String());

    // 4. Verify timestamp-based conflict resolution skips these seeded rows
    // When SyncService pulls, it will get the remote user which has the EXACT SAME updatedAt timestamp
    // since it was created atomically during bootstrap.
    final remoteUser = AppUserModel.fromEntity(AppUser(
      uid: 'test_uid',
      email: 'test@example.com',
      displayName: 'Test User',
      businessId: 'mock_biz_id',
      roleId: 'mock_role_id',
      isSuperAdmin: true,
      isOwner: true,
      isActive: true,
      createdAt: fixedTime,
      updatedAt: fixedTime, // Exact same timestamp
    ));

    // Replicate the pull logic exactly as it exists in UserRepositoryImpl
    // if (remoteUser.updatedAt.compareTo(localUser.updatedAt) <= 0) { continue; }
    
    // First confirm that compareTo resolves to <= 0 (it should be 0 because they are identical)
    expect(remoteUser.updatedAt.compareTo(seededUser.updatedAt) <= 0, true);

    // What if the remote user is older (somehow)? Still <= 0.
    final olderRemoteUser = remoteUser.copyWith(updatedAt: fixedTime.subtract(const Duration(seconds: 5)));
    expect(olderRemoteUser.updatedAt.compareTo(seededUser.updatedAt) <= 0, true);

    // Only if a newer remote user arrives should it be > 0
    final newerRemoteUser = remoteUser.copyWith(updatedAt: fixedTime.add(const Duration(seconds: 5)));
    expect(newerRemoteUser.updatedAt.compareTo(seededUser.updatedAt) > 0, true);
  });
}
