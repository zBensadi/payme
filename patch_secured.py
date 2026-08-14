import sys

file_path = "lib/data/repositories_impl/secured/secured_client_visibility_repository.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("Failure _unauthorized() {", "AppFailure _unauthorized() {")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
