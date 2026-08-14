import sys

file_path = "test/data/repositories/client_visibility_repository_impl_test.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

missing_methods = """
  @override
  void requestFullSync() {}

  @override
  Stream<SyncDomain> get syncRequested => const Stream.empty();
"""

content = content.replace("  @override\n  void dispose() {}", missing_methods + "  @override\n  void dispose() {}")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

