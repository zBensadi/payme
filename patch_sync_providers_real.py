import sys

file_path = "lib/presentation/providers/sync_providers.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

replacement = """final synchronizableRepositoriesProvider = Provider<List<SynchronizableRepository>>((ref) {
  return [
    ref.watch(internalSettingsRepositoryProvider) as SynchronizableRepository,
    ref.watch(internalClientRepositoryProvider) as SynchronizableRepository,
    ref.watch(accountingYearRepositoryProvider) as SynchronizableRepository,
    ref.watch(internalInvoiceRepositoryProvider) as SynchronizableRepository,
    ref.watch(internalPaymentRepositoryProvider) as SynchronizableRepository,
    ref.watch(internalRoleRepositoryProvider) as SynchronizableRepository,
    ref.watch(internalUserRepositoryProvider) as SynchronizableRepository,
    ref.watch(internalClientVisibilityRepositoryProvider) as SynchronizableRepository,
  ];
});"""

import re
content = re.sub(r'final synchronizableRepositoriesProvider = Provider<List<SynchronizableRepository>>\(\(ref\) \{.*?\}\);', replacement, content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
