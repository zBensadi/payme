import sys

file_path = "lib/domain/repositories/user_repository.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

new_content = content.replace(
    "Future<Result<List<AppUser>>> getAllUsers();",
    "Future<Result<List<AppUser>>> getAllUsers();\n  Future<Result<bool>> hasUsersWithRole(String roleId);"
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content)
