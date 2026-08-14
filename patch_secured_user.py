import sys

file_path = "lib/data/repositories_impl/secured/secured_user_repository.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

insert_pos = content.find("  @override\n  Future<Result<void>> createUser(AppUser user) async {")
if insert_pos != -1:
    new_method = """  @override
  Future<Result<bool>> hasUsersWithRole(String roleId) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.usersView)) {
      return Failure(_unauthorized());
    }
    return await _inner.hasUsersWithRole(roleId);
  }

"""
    content = content[:insert_pos] + new_method + content[insert_pos:]
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
else:
    print("Could not find insert pos in SecuredUserRepository")
