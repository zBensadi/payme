import sys
import re

file_path = "lib/core/database/migration_runner.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

replacement = """      if (currentVersion == 11) {
        _logger.info('Running migration: v12_normalize_system_roles.sql');
        final scriptContent = await loadMigrationScript('v12_normalize_system_roles.sql');
        await applyMigration(db, scriptContent, 12);
        currentVersion = 12;
      }
      if (currentVersion == 12) {
        _logger.info('Running migration: v13_client_visibility_tombstones.sql');
        final scriptContent = await loadMigrationScript('v13_client_visibility_tombstones.sql');
        await applyMigration(db, scriptContent, 13);
        currentVersion = 13;
      }"""

content = content.replace("""      if (currentVersion == 11) {
        _logger.info('Running migration: v12_normalize_system_roles.sql');
        final scriptContent = await loadMigrationScript('v12_normalize_system_roles.sql');
        await applyMigration(db, scriptContent, 12);
        currentVersion = 12;
      }""", replacement)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
