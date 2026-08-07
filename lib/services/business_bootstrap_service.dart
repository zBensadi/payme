import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/result.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/bootstrap_repository.dart';
import '../data/repositories_impl/firebase_bootstrap_repository.dart';

final bootstrapRepositoryProvider = Provider<BootstrapRepository>((ref) {
  return FirebaseBootstrapRepository();
});

final businessBootstrapServiceProvider = Provider<BusinessBootstrapService>((ref) {
  return BusinessBootstrapService(ref.watch(bootstrapRepositoryProvider));
});

class BusinessBootstrapService {
  final BootstrapRepository _repository;

  BusinessBootstrapService(this._repository);

  Future<Result<AppUser>> bootstrapBusiness({
    required String uid,
    required String email,
    required String? displayName,
    required String businessName,
  }) async {
    return _repository.bootstrapBusiness(
      uid: uid,
      email: email,
      displayName: displayName,
      businessName: businessName,
    );
  }
}
