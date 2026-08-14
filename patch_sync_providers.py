import sys

file_path = "lib/presentation/providers/sync_providers.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

replacement = """  final roleRepo = ref.watch(internalRoleRepositoryProvider);
  final clientVisibilityRepo = ref.watch(internalClientVisibilityRepositoryProvider);

  debugPrint('[STARTUP][${DateTime.now().toIso8601String()}][syncServiceProvider] BEFORE SyncService() constructor');
  final service = SyncService(
    repositories: [
      accountingYearRepo,
      clientRepo,
      invoiceRepo,
      paymentRepo,
      settingsRepo,
      userRepo,
      roleRepo,
      clientVisibilityRepo,
    ],"""

import re
content = re.sub(r'  final roleRepo = ref.watch\(internalRoleRepositoryProvider\);\n\n  debugPrint\(\'\[STARTUP\]\[\$\{DateTime.now\(\).toIso8601String\(\)\}\]\[syncServiceProvider\] BEFORE SyncService\(\) constructor\'\);\n  final service = SyncService\(\n    repositories: \[\n      accountingYearRepo,\n      clientRepo,\n      invoiceRepo,\n      paymentRepo,\n      settingsRepo,\n      userRepo,\n      roleRepo,\n    \],', replacement, content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
