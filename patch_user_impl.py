import sys

file_path = "lib/data/repositories_impl/user_repository_impl.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

insert_pos = content.find("  @override\n  Future<Result<void>> createUser(AppUser user) async {")
if insert_pos != -1:
    new_method = """  @override
  Future<Result<bool>> hasUsersWithRole(String roleId) async {
    try {
      final hasUsers = await _localDataSource.hasUsersWithRole(roleId);
      return Success(hasUsers);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to check users by role: $e'));
    }
  }

"""
    content = content[:insert_pos] + new_method + content[insert_pos:]
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
else:
    print("Could not find insert pos in UserRepositoryImpl")
