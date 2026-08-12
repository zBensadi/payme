import '../entities/user_role.dart';
import '../../core/error/result.dart';

abstract class RoleRepository {
  Future<Result<List<UserRole>>> getAllRoles();
  Future<Result<UserRole?>> getRoleById(String id);
  Future<Result<void>> createRole(UserRole role);
  Future<Result<void>> updateRole(UserRole role);
  Future<Result<void>> deleteRole(String id);
}
