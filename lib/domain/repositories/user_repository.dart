import '../entities/app_user.dart';
import '../../core/error/result.dart';

abstract class UserRepository {
  Future<Result<List<AppUser>>> getAllUsers();
  Future<Result<AppUser?>> getUserById(String id);
  Future<Result<void>> createUser(AppUser user);
  Future<Result<void>> updateUser(AppUser user);
  Future<Result<void>> deleteUser(String id);
}
