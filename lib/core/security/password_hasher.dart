import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class PasswordHasher {
  static const int _iterations = 100000;
  static const int _hashLength = 32;

  final Pbkdf2 _pbkdf2;

  PasswordHasher() : _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: _hashLength * 8,
  );

  /// Generates a random salt of [length] bytes, returned as a base64 string.
  String generateSalt({int length = 16}) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hashes a [password] using PBKDF2 with the given base64 encoded [salt].
  Future<String> hashPassword(String password, String salt) async {
    final secretKey = SecretKey(utf8.encode(password));
    final saltBytes = base64Decode(salt);

    final derivedKey = await _pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: saltBytes,
    );

    final hashBytes = await derivedKey.extractBytes();
    return base64Encode(hashBytes);
  }

  /// Verifies if the [password] matches the base64 encoded [hash] using the given [salt].
  Future<bool> verifyPassword(String password, String hash, String salt) async {
    final computedHash = await hashPassword(password, salt);
    return computedHash == hash;
  }

  /// Generates a random alphanumeric recovery key in the format XXXX-XXXX-XXXX-XXXX-XXXX-XXXX
  String generateRecoveryKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    
    String generateSegment(int length) {
      return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
    }

    return List.generate(6, (_) => generateSegment(4)).join('-');
  }
}
