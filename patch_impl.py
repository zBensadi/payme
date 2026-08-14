import sys

file_path = "lib/data/repositories_impl/client_visibility_repository_impl.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("debugPrint('Client visibility push failed: $e\n$stack');", "debugPrint('Client visibility push failed: $e\\n$stack');")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
