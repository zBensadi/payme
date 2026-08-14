import sys
import re

file_path = "lib/presentation/providers/repository_providers.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

import_statement = "import '../../data/repositories_impl/secured/secured_client_visibility_repository.dart';"
if import_statement not in content:
    content = content.replace(
        "import '../../data/repositories_impl/secured/secured_client_repository.dart';",
        "import '../../data/repositories_impl/secured/secured_client_repository.dart';\n" + import_statement
    )

provider_replacement = """final clientVisibilityRepositoryProvider = Provider<ClientVisibilityRepository>((ref) {
  final inner = ref.watch(internalClientVisibilityRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  return SecuredClientVisibilityRepository(inner, permissionService, currentUser);
});"""

content = re.sub(r'final clientVisibilityRepositoryProvider = Provider<ClientVisibilityRepository>\(\(ref\) \{.*?\return inner;\n\}\);', provider_replacement, content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
