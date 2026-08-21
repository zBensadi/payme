import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/result.dart';
import 'repository_providers.dart';

final userLookupProvider = FutureProvider.family<String, String>((ref, uid) async {
  final userRepo = ref.read(internalUserRepositoryProvider);
  final result = await userRepo.getUserById(uid);
  
  if (result is Success) {
    final user = (result as Success).value;
    if (user != null) {
      return user.displayName?.isNotEmpty == true ? user.displayName! : user.email;
    }
  }
  
  return 'Unknown User';
});
