import sys

file_path = "lib/presentation/features/admin/roles/screens/role_list_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("context.goNamed('role-editor', pathParameters: {'id': 'new'});", "context.go('/roles/new');")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
