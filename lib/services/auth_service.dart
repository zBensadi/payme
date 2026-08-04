import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/error/failures.dart';
import '../core/error/result.dart';
import '../core/security/password_hasher.dart';
import '../data/datasources/local/admin_credential_local_datasource.dart';

final authServiceProvider = Provider((ref) {
  final dataSource = ref.watch(adminCredentialDataSourceProvider);
  return AuthService(dataSource, PasswordHasher());
});

enum AuthStatus {
  setupRequired,
  loginRequired,
  fatalError,
}

class AuthService {
  final AdminCredentialLocalDataSource _dataSource;
  final PasswordHasher _hasher;

  AuthService(this._dataSource, this._hasher);

  /// Checks the current database state to determine setup/login flow.
  Future<AuthStatus> checkStatus() async {
    final cred = await _dataSource.getCredential();
    if (cred != null) {
      return AuthStatus.loginRequired;
    }
    
    // No credentials exist. Check for business data to detect corruption.
    final hasData = await _dataSource.hasBusinessData();
    if (hasData) {
      return AuthStatus.fatalError;
    }
    
    return AuthStatus.setupRequired;
  }

  /// Sets up the password for the first time.
  /// Returns a Result containing the plain text Recovery Key to be shown to the user once.
  Future<Result<String>> setupPassword(String password) async {
    final status = await checkStatus();
    if (status != AuthStatus.setupRequired) {
      return const Failure(AuthFailure('Password setup is not allowed in the current state.'));
    }

    try {
      final passwordSalt = _hasher.generateSalt();
      final passwordHash = await _hasher.hashPassword(password, passwordSalt);

      final recoveryKey = _hasher.generateRecoveryKey();
      final recoveryKeySalt = _hasher.generateSalt();
      final recoveryKeyHash = await _hasher.hashPassword(recoveryKey, recoveryKeySalt);

      await _dataSource.saveCredential(
        passwordHash: passwordHash,
        passwordSalt: passwordSalt,
        recoveryKeyHash: recoveryKeyHash,
        recoveryKeySalt: recoveryKeySalt,
      );

      return Success(recoveryKey);
    } catch (e) {
      return Failure(AuthFailure('Failed to setup password.'));
    }
  }

  /// Verifies the provided password against the stored credential.
  Future<Result<void>> login(String password) async {
    final cred = await _dataSource.getCredential();
    if (cred == null) {
      return const Failure(AuthFailure('No credentials found.'));
    }

    try {
      final storedHash = cred['password_hash'] as String;
      final storedSalt = cred['password_salt'] as String;

      final isValid = await _hasher.verifyPassword(password, storedHash, storedSalt);
      if (isValid) {
        return const Success(null);
      } else {
        return const Failure(AuthFailure('Incorrect password.'));
      }
    } catch (e) {
      return Failure(AuthFailure('Failed to verify password.'));
    }
  }

  /// Verifies the recovery key and resets the password, returning a NEW recovery key.
  Future<Result<String>> resetPasswordWithRecoveryKey(String recoveryKey, String newPassword) async {
    final cred = await _dataSource.getCredential();
    if (cred == null) {
      return const Failure(AuthFailure('No credentials found.'));
    }

    try {
      final storedKeyHash = cred['recovery_key_hash'] as String;
      final storedKeySalt = cred['recovery_key_salt'] as String;

      final isValid = await _hasher.verifyPassword(recoveryKey, storedKeyHash, storedKeySalt);
      if (!isValid) {
        return const Failure(AuthFailure('Invalid recovery key.'));
      }

      final passwordSalt = _hasher.generateSalt();
      final passwordHash = await _hasher.hashPassword(newPassword, passwordSalt);

      final newRecoveryKey = _hasher.generateRecoveryKey();
      final recoveryKeySalt = _hasher.generateSalt();
      final recoveryKeyHash = await _hasher.hashPassword(newRecoveryKey, recoveryKeySalt);

      await _dataSource.saveCredential(
        passwordHash: passwordHash,
        passwordSalt: passwordSalt,
        recoveryKeyHash: recoveryKeyHash,
        recoveryKeySalt: recoveryKeySalt,
      );

      return Success(newRecoveryKey);
    } catch (e) {
      return Failure(AuthFailure('Failed to reset password.'));
    }
  }

  /// Changes the password assuming the user knows the current password.
  /// Generates a new recovery key.
  Future<Result<String>> changePassword(String oldPassword, String newPassword) async {
    final cred = await _dataSource.getCredential();
    if (cred == null) {
      return const Failure(AuthFailure('No credentials found.'));
    }

    try {
      final storedHash = cred['password_hash'] as String;
      final storedSalt = cred['password_salt'] as String;

      final isValid = await _hasher.verifyPassword(oldPassword, storedHash, storedSalt);
      if (!isValid) {
        return const Failure(AuthFailure('Incorrect current password.'));
      }

      final passwordSalt = _hasher.generateSalt();
      final passwordHash = await _hasher.hashPassword(newPassword, passwordSalt);

      final newRecoveryKey = _hasher.generateRecoveryKey();
      final recoveryKeySalt = _hasher.generateSalt();
      final recoveryKeyHash = await _hasher.hashPassword(newRecoveryKey, recoveryKeySalt);

      await _dataSource.saveCredential(
        passwordHash: passwordHash,
        passwordSalt: passwordSalt,
        recoveryKeyHash: recoveryKeyHash,
        recoveryKeySalt: recoveryKeySalt,
      );

      return Success(newRecoveryKey);
    } catch (e) {
      return Failure(AuthFailure('Failed to change password.'));
    }
  }
}
