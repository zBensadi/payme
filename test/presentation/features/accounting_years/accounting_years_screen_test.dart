import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/security/permission_service.dart';
import 'package:payme/domain/entities/accounting_year.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/current_app_user.dart';
import 'package:payme/domain/entities/permissions.dart';
import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/domain/repositories/accounting_year_repository.dart';
import 'package:payme/presentation/features/accounting_years/screens/accounting_years_screen.dart';
import 'package:payme/presentation/features/auth/controllers/current_user_controller.dart';
import 'package:payme/presentation/providers/permission_service_provider.dart';
import 'package:payme/presentation/providers/repository_providers.dart';
import 'package:payme/core/sync/sync_trigger.dart';
import 'package:payme/core/sync/sync_service.dart';
import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/core/sync/sync_status.dart';
import 'package:payme/presentation/providers/sync_trigger_provider.dart';
import 'package:payme/presentation/providers/sync_providers.dart';

class FakeAccountingYearRepository implements AccountingYearRepository {
  List<AccountingYear> years = [];

  @override
  Future<Result<List<AccountingYear>>> getAll() async {
    return Success(years.toList());
  }

  @override
  Future<Result<AccountingYear?>> getActive() async {
    try {
      return Success(years.firstWhere((y) => y.isActive));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<AccountingYear>> create(String name) async {
    final year = AccountingYear(
      id: name,
      name: name,
      isActive: years.isEmpty,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    years.add(year);
    return Success(year);
  }

  @override
  Future<Result<void>> rename(String id, String newName) async {
    final index = years.indexWhere((y) => y.id == id);
    if (index >= 0) {
      years[index] = years[index].copyWith(name: newName);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> setActive(String id) async {
    years = years.map((y) {
      return y.copyWith(isActive: y.id == id);
    }).toList();
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    years.removeWhere((y) => y.id == id);
    return const Success(null);
  }
}

CurrentAppUser createUser(List<String> permissions) {
  final now = DateTime.now();
  return CurrentAppUser(
    user: AppUser(
      uid: 'uid',
      email: 'test@test.com',
      businessId: 'b1',
      isSuperAdmin: false,
      isActive: true,
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

void main() {
  testWidgets('AccountingYearsScreen displays empty state when no years', (WidgetTester tester) async {
    final fakeRepo = FakeAccountingYearRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountingYearRepositoryProvider.overrideWithValue(fakeRepo),
          currentUserProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountingYearsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('No accounting years found'), findsOneWidget);
  });

  testWidgets('AccountingYearsScreen displays FAB and Edit actions if manage permission exists', (WidgetTester tester) async {
    final fakeRepo = FakeAccountingYearRepository();
    await fakeRepo.create('2025');
    await fakeRepo.create('2026');

    final user = createUser([Permissions.accountingYearsView, Permissions.accountingYearsManage]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountingYearRepositoryProvider.overrideWithValue(fakeRepo),
          permissionServiceProvider.overrideWithValue(PermissionService()),
          currentUserProvider.overrideWith((ref) => Stream.value(user)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountingYearsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2025'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    
    // FAB is present
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Edit actions (PopupMenuButton) is present for both items
    expect(find.byType(PopupMenuButton<String>), findsNWidgets(2));
  });

  testWidgets('AccountingYearsScreen hides FAB and Edit actions if manage permission is missing', (WidgetTester tester) async {
    final fakeRepo = FakeAccountingYearRepository();
    await fakeRepo.create('2025');
    await fakeRepo.create('2026');

    final user = createUser([Permissions.accountingYearsView]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountingYearRepositoryProvider.overrideWithValue(fakeRepo),
          permissionServiceProvider.overrideWithValue(PermissionService()),
          currentUserProvider.overrideWith((ref) => Stream.value(user)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountingYearsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2025'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    
    // FAB is hidden
    expect(find.byType(FloatingActionButton), findsNothing);

    // Edit actions (PopupMenuButton) are hidden
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });

  testWidgets('AccountingYearsScreen delete with confirmation succeeds', (WidgetTester tester) async {
    final fakeRepo = FakeAccountingYearRepository();
    await fakeRepo.create('2025');
    await fakeRepo.create('2026'); // 2026 is active

    final user = createUser([Permissions.accountingYearsView, Permissions.accountingYearsManage]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountingYearRepositoryProvider.overrideWithValue(fakeRepo),
          permissionServiceProvider.overrideWithValue(PermissionService()),
          currentUserProvider.overrideWith((ref) => Stream.value(user)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountingYearsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('2025'), findsOneWidget);

    // Open popup menu for '2026' (it's the non-active one)
    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();

    // Tap delete
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirmation dialog should appear
    expect(find.text('Are you sure you want to delete this accounting year?'), findsOneWidget);

    // Tap Delete button in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    // 2026 should be deleted
    expect(fakeRepo.years.any((y) => y.name == '2026'), isFalse);
  });

  testWidgets('AccountingYearsScreen delete confirmation cancelled', (WidgetTester tester) async {
    final fakeRepo = FakeAccountingYearRepository();
    await fakeRepo.create('2025');
    await fakeRepo.create('2026');

    final user = createUser([Permissions.accountingYearsView, Permissions.accountingYearsManage]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountingYearRepositoryProvider.overrideWithValue(fakeRepo),
          permissionServiceProvider.overrideWithValue(PermissionService()),
          currentUserProvider.overrideWith((ref) => Stream.value(user)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountingYearsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    // Open popup menu for '2026' (the non-active one)
    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();

    // Tap delete
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Cancel dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 2026 should still exist
    expect(fakeRepo.years.any((y) => y.name == '2026'), isTrue);
  });

  testWidgets('AccountingYearsScreen pull-to-refresh triggers sync', (WidgetTester tester) async {
    final fakeRepo = FakeAccountingYearRepository();
    await fakeRepo.create('2025');

    final user = createUser([Permissions.accountingYearsView, Permissions.accountingYearsManage]);

    bool syncRequested = false;

    final syncService = _FakeSyncService();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountingYearRepositoryProvider.overrideWithValue(fakeRepo),
          permissionServiceProvider.overrideWithValue(PermissionService()),
          currentUserProvider.overrideWith((ref) => Stream.value(user)),
          syncTriggerProvider.overrideWithValue(
            _FakeSyncTrigger(() {
              syncRequested = true;
              Future.microtask(() {
                syncService.emitStatus(SyncStatus.syncing);
                Future.microtask(() => syncService.emitStatus(SyncStatus.idle));
              });
            })
          ),
          syncServiceProvider.overrideWithValue(syncService),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountingYearsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('2025'), findsOneWidget);

    // Invoke RefreshIndicator.onRefresh directly to bypass gesture physics
    final RefreshIndicator refreshIndicator = tester.widget(find.byType(RefreshIndicator));
    refreshIndicator.onRefresh(); // Don't await because FakeSyncService might cause a hang
    await tester.pump();

    expect(syncRequested, isTrue);
  });
}

class _FakeSyncTrigger implements SyncTrigger {
  final VoidCallback onSync;
  _FakeSyncTrigger(this.onSync);

  @override
  Stream<SyncDomain> get syncRequested => const Stream.empty();

  @override
  void requestSync(SyncDomain domain) {}

  @override
  void requestFullSync() {
    onSync();
  }

  @override
  void dispose() {}
}

class _FakeSyncService implements SyncService {
  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _currentStatus = SyncStatus.idle;

  @override
  SyncStatus get currentStatus => _currentStatus;

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  void emitStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  @override
  bool hasCompletedInitialSync = false;

  @override
  void start() {}

  @override
  void stop() {}
  
  @override
  void triggerFullSync() {}

  @override
  Future<void> synchronizeDomains(Set<SyncDomain> domains) async {}

  @override
  void setBusinessId(String? businessId) {}
  
  @override
  Future<void> pause() async {}
  
  @override
  void resume() {}

  @override
  void dispose() {
    _statusController.close();
  }
}
