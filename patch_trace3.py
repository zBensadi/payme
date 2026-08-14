import sys

file_path = "scratch/trace.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Fix Database -> DatabaseService mismatch
content = content.replace("final clientDataSource = ClientLocalDataSource(dbService);", "final clientDataSource = ClientLocalDataSource(db);")

# Fix ClientModel creation
content = content.replace(
    "businessId: businessId,",
    ""
)

# Fix getAllVisible
content = content.replace(
    "final visibleClients = await clientDataSource.getAllVisible(businessId, userId);",
    "final visibleClients = await clientDataSource.getAllVisible(visibleToUserId: userId);"
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

