import sys

file_path = "lib/data/repositories_impl/secured/secured_client_visibility_repository.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("import '../../../core/auth/permissions.dart';", "import '../../../domain/entities/permissions.dart';\nimport '../../../core/error/failures.dart';")
content = content.replace("return UnauthorizedFailure", "return const UnauthorizedFailure")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
