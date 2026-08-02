import 'dart:math';

class IdGenerator {
  static final Random _random = Random.secure();

  /// Generates a UUIDv4-like string without requiring external dependencies.
  static String generateUniqueId() {
    final bytes = List<int>.generate(16, (i) => _random.nextInt(256));

    // Set UUID v4 versions
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final chars = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();

    return '${chars.sublist(0, 4).join()}-'
           '${chars.sublist(4, 6).join()}-'
           '${chars.sublist(6, 8).join()}-'
           '${chars.sublist(8, 10).join()}-'
           '${chars.sublist(10, 16).join()}';
  }
}
