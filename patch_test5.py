import sys

file_path = "test/features/clients/client_visibility_test.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

replacement = """'permissions': '[]',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),"""

content = content.replace("'permissions': '[]',", replacement)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
