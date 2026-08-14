import sys

file_path = "test/features/clients/client_visibility_test.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("'priority': 10,", "'priority': 10,\n      'permissions': '[]',")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
