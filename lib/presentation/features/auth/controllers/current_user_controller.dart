import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../data/repositories_impl/firebase_user_profile_repository.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../../services/user_profile_service.dart';
import 'firebase_auth_controller.dart';

final userProfileRepositoryProvider = Provider((ref) {
  return FirebaseUserProfileRepository();
});

final userProfileServiceProvider = Provider((ref) {
  return UserProfileService(ref.watch(userProfileRepositoryProvider));
});

final currentUserProvider = StreamProvider<UserProfile?>((ref) async* {
  final authService = ref.watch(firebaseAuthServiceProvider);
  final profileService = ref.watch(userProfileServiceProvider);

  await for (final user in authService.authStateChanges()) {
    if (user == null) {
      yield null;
    } else {
      final result = await profileService.getUserProfile(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );

      if (result is Success<UserProfile?>) {
        yield result.value;
      } else {
        throw (result as Failure).failure;
      }
    }
  }
});
