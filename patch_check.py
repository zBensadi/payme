import sys

file_path = "lib/data/repositories_impl/firebase_bootstrap_repository.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

old_block = """        if (businessId != null && roleId != null) {
          final effectiveRoleId = await _migrateLegacyOwnerRoleIfNeeded(businessId, roleId) ?? roleId;"""

new_block = """        if (businessId != null && roleId != null) {
          String effectiveRoleId;
          try {
            effectiveRoleId = await _migrateLegacyOwnerRoleIfNeeded(businessId, roleId);
          } catch (e) {
            debugPrint('[BSREPO][MIGRATION] Migration failed for $businessId: $e');
            return Failure(DatabaseFailure('Legacy role migration failed. Please try again.'));
          }"""
          
content = content.replace(old_block, new_block)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
