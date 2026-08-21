import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/presentation/providers/repository_providers.dart';
import 'package:payme/presentation/features/clients/widgets/client_form.dart';
import 'package:payme/presentation/features/clients/controllers/client_form_controller.dart';
import 'package:payme/l10n/app_localizations.dart';
import 'package:payme/data/repositories_impl/user_repository_impl.dart';
import 'package:payme/domain/repositories/client_repository.dart';
import 'package:payme/domain/repositories/client_visibility_repository.dart';
import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/core/sync/sync_priority.dart';

class FakeUserRepository implements UserRepositoryImpl {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<List<AppUser>>> getAllUsers({bool forceRefresh = false}) async {
    return Success([
      AppUser(uid: 'uid-1', email: 'owner@example.com', displayName: '', isSuperAdmin: false, isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      AppUser(uid: 'uid-2', email: 'owner@example.com', displayName: 'Owner Name', isSuperAdmin: false, isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      AppUser(uid: 'uid-3', email: '', displayName: '', isSuperAdmin: false, isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    ]);
  }
}

class FakeClientRepository implements ClientRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<bool>> checkDuplicate(String name, String? phone, {String? excludeId}) async {
    return const Success(false);
  }
}

class FakeClientVisibilityRepository implements ClientVisibilityRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  SyncDomain get syncDomain => SyncDomain.clientVisibility;

  @override
  SyncPriority get syncPriority => SyncPriority.level4ClientVisibility;

  @override
  Future<Result<void>> addVisibility(dynamic visibility) async => const Success(null);
}

void main() {
  testWidgets('ClientForm user resolution renders correct chip names', (tester) async {
    final fakeUserRepo = FakeUserRepository();
    final fakeClientRepo = FakeClientRepository();
    final fakeVisibilityRepo = FakeClientVisibilityRepository();

    final container = ProviderContainer(
      overrides: [
        internalUserRepositoryProvider.overrideWithValue(fakeUserRepo),
        clientRepositoryProvider.overrideWithValue(fakeClientRepo),
        clientVisibilityRepositoryProvider.overrideWithValue(fakeVisibilityRepo),
      ],
    );

    await container.read(clientFormControllerProvider.notifier).build();
    container.read(clientFormControllerProvider.notifier).setVisibilityType('specific_users');
    container.read(clientFormControllerProvider.notifier).setSelectedUsers(['uid-1', 'uid-2', 'uid-3']);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ClientForm(
              initialClient: null,
              onSave: (_) {},
            ),
          ),
        ),
      ),
    );
    
    await tester.pumpAndSettle();

    expect(find.text('owner@example.com'), findsOneWidget); // For uid-1
    expect(find.text('Owner Name'), findsOneWidget); // For uid-2
    expect(find.text('uid-3'), findsOneWidget); // For uid-3
  });
}
