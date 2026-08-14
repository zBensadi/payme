import sys
import re

file_path = "lib/data/repositories_impl/secured/secured_client_visibility_repository.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = "import '../../../core/auth/permissions.dart';\n" + content
content = content.replace("const UnauthorizedFailure", "UnauthorizedFailure")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
