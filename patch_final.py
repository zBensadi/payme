import sys
import re

# 1. Fix client_visibility_repository_impl.dart
file_path_1 = "lib/data/repositories_impl/client_visibility_repository_impl.dart"
with open(file_path_1, "rb") as f:
    content_bytes = f.read()

# Replace null bytes
content_bytes = content_bytes.replace(b'\x00', b'')
content_str = content_bytes.decode('utf-8', errors='ignore')

if not content_str.strip().endswith('}'):
    content_str = content_str + "\n}\n"

with open(file_path_1, "w", encoding="utf-8") as f:
    f.write(content_str)


# 2. Fix secured_client_visibility_repository.dart
file_path_2 = "lib/data/repositories_impl/secured/secured_client_visibility_repository.dart"
with open(file_path_2, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("import '../../../core/security/permissions.dart';", "")

with open(file_path_2, "w", encoding="utf-8") as f:
    f.write(content)

