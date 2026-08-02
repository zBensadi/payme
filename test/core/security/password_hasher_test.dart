import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/security/password_hasher.dart';

void main() {
  late PasswordHasher hasher;

  setUp(() {
    hasher = PasswordHasher();
  });

  test('generateSalt produces unique salts of correct length', () {
    final salt1 = hasher.generateSalt();
    final salt2 = hasher.generateSalt();
    
    expect(salt1, isNotEmpty);
    expect(salt2, isNotEmpty);
    expect(salt1, isNot(equals(salt2)));
  });

  test('hashPassword produces consistent hashes for same password and salt', () async {
    final salt = hasher.generateSalt();
    const password = 'mySecretPassword';

    final hash1 = await hasher.hashPassword(password, salt);
    final hash2 = await hasher.hashPassword(password, salt);

    expect(hash1, equals(hash2));
  });

  test('hashPassword produces different hashes for different salts', () async {
    final salt1 = hasher.generateSalt();
    final salt2 = hasher.generateSalt();
    const password = 'mySecretPassword';

    final hash1 = await hasher.hashPassword(password, salt1);
    final hash2 = await hasher.hashPassword(password, salt2);

    expect(hash1, isNot(equals(hash2)));
  });

  test('verifyPassword returns true for correct password', () async {
    final salt = hasher.generateSalt();
    const password = 'mySecretPassword';
    final hash = await hasher.hashPassword(password, salt);

    final isValid = await hasher.verifyPassword(password, hash, salt);
    expect(isValid, isTrue);
  });

  test('verifyPassword returns false for incorrect password', () async {
    final salt = hasher.generateSalt();
    const password = 'mySecretPassword';
    final hash = await hasher.hashPassword(password, salt);

    final isValid = await hasher.verifyPassword('wrongPassword', hash, salt);
    expect(isValid, isFalse);
  });

  test('generateRecoveryKey produces formatted keys', () {
    final key1 = hasher.generateRecoveryKey();
    final key2 = hasher.generateRecoveryKey();

    expect(key1.length, 29); // 6 segments of 4 = 24 chars + 5 hyphens = 29
    expect(key1.split('-').length, 6);
    expect(key1, isNot(equals(key2)));
  });
}
