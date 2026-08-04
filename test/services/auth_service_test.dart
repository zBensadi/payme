import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/security/password_hasher.dart';
import 'package:payme/data/datasources/local/admin_credential_local_datasource.dart';
import 'package:payme/services/auth_service.dart';

// Fake data source to avoid build_runner/mockito overhead
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

void main() {
  late FakeAdminCredentialLocalDataSource fakeDataSource;
  late PasswordHasher hasher;
  late AuthService authService;

  setUp(() {
    fakeDataSource = FakeAdminCredentialLocalDataSource();
    hasher = PasswordHasher();
    authService = AuthService(fakeDataSource, hasher);
  });

  test('checkStatus returns setupRequired when no credentials and no data', () async {
    fakeDataSource.credential = null;
    fakeDataSource.dataExists = false;
    final status = await authService.checkStatus();
    expect(status, equals(AuthStatus.setupRequired));
  });

  test('checkStatus returns fatalError when no credentials but data exists', () async {
    fakeDataSource.credential = null;
    fakeDataSource.dataExists = true;
    final status = await authService.checkStatus();
    expect(status, equals(AuthStatus.fatalError));
  });

  test('checkStatus returns loginRequired when credentials exist', () async {
    fakeDataSource.credential = {'fake': 'data'};
    final status = await authService.checkStatus();
    expect(status, equals(AuthStatus.loginRequired));
  });

  test('setupPassword creates credentials and returns recovery key', () async {
    final result = await authService.setupPassword('mySecretPass');
    
    expect(result, isA<Success>());
    final recoveryKey = (result as Success<String>).value;
    expect(recoveryKey, isNotEmpty);
    
    expect(fakeDataSource.credential, isNotNull);
    expect(fakeDataSource.credential!['password_hash'], isNotEmpty);
  });

  test('login succeeds with correct password', () async {
    await authService.setupPassword('mySecretPass');
    
    final result = await authService.login('mySecretPass');
    expect(result, isA<Success>());
  });

  test('login fails with incorrect password', () async {
    await authService.setupPassword('mySecretPass');
    
    final result = await authService.login('wrongPass');
    expect(result, isA<Failure>());
  });

  test('resetPasswordWithRecoveryKey resets password and returns new key', () async {
    final setupResult = await authService.setupPassword('mySecretPass');
    final firstRecoveryKey = (setupResult as Success<String>).value;
    
    final resetResult = await authService.resetPasswordWithRecoveryKey(firstRecoveryKey, 'newPass');
    expect(resetResult, isA<Success>());
    
    final newRecoveryKey = (resetResult as Success<String>).value;
    expect(newRecoveryKey, isNot(equals(firstRecoveryKey)));
    
    // Login with new password should succeed
    final loginResult = await authService.login('newPass');
    expect(loginResult, isA<Success>());
  });
}
