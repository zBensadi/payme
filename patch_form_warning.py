import sys

file_path = "lib/presentation/features/clients/widgets/client_form.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("import '../../../../domain/entities/current_app_user.dart';\n", "")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

