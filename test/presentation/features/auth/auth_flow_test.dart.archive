import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/core/security/password_hasher.dart';
import 'package:payme/data/datasources/local/admin_credential_local_datasource.dart';
import 'package:payme/services/auth_service.dart';
import 'package:payme/app.dart';
import 'package:payme/core/database/database_provider.dart';
import 'package:payme/core/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

class FakeAdminCredentialLocalDataSource implements AdminCredentialLocalDataSource {
  Map<String, dynamic>? credential;
  bool dataExists = false;

  @override
  Future<Map<String, dynamic>?> getCredential() async => credential;

  @override
  Future<bool> hasBusinessData() async => dataExists;

  @override
  Future<void> saveCredential({
    required String passwordHash,
    required String passwordSalt,
    required String recoveryKeyHash,
    required String recoveryKeySalt,
  }) async {
    credential = {
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'recovery_key_hash': recoveryKeyHash,
      'recovery_key_salt': recoveryKeySalt,
    };
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDatabaseService extends DatabaseService {
  FakeDatabaseService() : super(_FakeDatabase());
}

class _FakeDatabase implements Database {
  @override
  bool get isOpen => false;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App redirects to Setup when no credentials and no data exist', (WidgetTester tester) async {
    final fakeDataSource = FakeAdminCredentialLocalDataSource();
    final authService = AuthService(fakeDataSource, PasswordHasher());
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(FakeDatabaseService()),
          adminCredentialDataSourceProvider.overrideWithValue(fakeDataSource),
          authServiceProvider.overrideWithValue(authService),
        ],
        child: const PayMeApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Setup Password'), findsWidgets);
    expect(find.text('Create Password'), findsOneWidget);
  });

  testWidgets('App redirects to FatalError when no credentials but data exists', (WidgetTester tester) async {
    final fakeDataSource = FakeAdminCredentialLocalDataSource();
    fakeDataSource.dataExists = true; // Simulating corruption
    final authService = AuthService(fakeDataSource, PasswordHasher());
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(FakeDatabaseService()),
          adminCredentialDataSourceProvider.overrideWithValue(fakeDataSource),
          authServiceProvider.overrideWithValue(authService),
        ],
        child: const PayMeApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Authentication Corrupted'), findsOneWidget);
    expect(find.text('Setup Password'), findsNothing);
  });
}
