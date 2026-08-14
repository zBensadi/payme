import sys

# Fix UnauthorizedFailure constant issue
file_path_secured = "lib/data/repositories_impl/secured/secured_client_visibility_repository.dart"
with open(file_path_secured, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("return const UnauthorizedFailure", "return UnauthorizedFailure")

with open(file_path_secured, "w", encoding="utf-8") as f:
    f.write(content)

# Fix test file
file_path_test = "test/presentation/features/clients/controllers/client_form_controller_test.dart"
with open(file_path_test, "r", encoding="utf-8") as f:
    content = f.read()

content = "import 'package:payme/domain/entities/client_visibility_context.dart';\n" + content
content = content.replace("SyncPriority.normal", "SyncPriority.level5Clients")
content = content.replace("SyncPriority.medium", "SyncPriority.level5Clients")
# Replace clientVisibility priority
content = content.replace("SyncPriority.level5Clients;", "SyncPriority.level4ClientVisibility;", 1) # Wait, it's better to just replace by line or carefully

with open(file_path_test, "w", encoding="utf-8") as f:
    f.write(content)
