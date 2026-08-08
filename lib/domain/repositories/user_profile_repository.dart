import '../../core/error/result.dart';
import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  /// Fetches the user profile, including business context and role if applicable.
  Future<Result<UserProfile?>> getUserProfile({
    required String uid,
    required String email,
    String? displayName,
  });
}
