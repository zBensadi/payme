import '../entities/app_user.dart';
import '../../core/error/result.dart';

abstract class BootstrapRepository {
  Future<Result<AppUser>> bootstrapBusiness({
    required String uid,
    required String email,
    required String? displayName,
    required String businessName,
  });
}
