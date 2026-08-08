import '../core/error/result.dart';
import '../domain/entities/user_profile.dart';
import '../domain/repositories/user_profile_repository.dart';

class UserProfileService {
  final UserProfileRepository _repository;

  UserProfileService(this._repository);

  Future<Result<UserProfile?>> getUserProfile({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    return _repository.getUserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
    );
  }
}
