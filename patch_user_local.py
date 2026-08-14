import sys

file_path = "lib/data/datasources/local/user_local_datasource.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Add hasUsersWithRole after getById
insert_pos = content.find("Future<void> create(AppUserModel user) async {")
if insert_pos != -1:
    new_method = """  Future<bool> hasUsersWithRole(String roleId) async {
    final result = await _db.query(
      'users',
      where: 'role_id = ?',
      whereArgs: [roleId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  """
    content = content[:insert_pos] + new_method + content[insert_pos:]
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
else:
    print("Could not find insert pos")
