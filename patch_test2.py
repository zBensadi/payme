import sys

file_path = "test/features/clients/client_visibility_test.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Fix Database argument
content = content.replace("clientDataSource = ClientLocalDataSource(dbService);", "clientDataSource = ClientLocalDataSource(db);")

# Move the test group inside main()
parts = content.split("}\n\n\n  group('Client Visibility Sync Blocker Regression Tests', () {")
if len(parts) == 2:
    fixed_content = parts[0] + "\n\n  group('Client Visibility Sync Blocker Regression Tests', () {" + parts[1][:-1] + "}\n"
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(fixed_content)

