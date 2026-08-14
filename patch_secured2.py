import sys

file_path = "lib/data/repositories_impl/secured/secured_client_visibility_repository.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

import_statement = "import '../../../core/auth/permissions.dart';"
if import_statement not in content:
    content = content.replace(
        "import '../../../domain/repositories/client_visibility_repository.dart';",
        "import '../../../domain/repositories/client_visibility_repository.dart';\n" + import_statement
    )

content = content.replace("Stream<void> get onDidChange => _inner.onDidChange;", "")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
