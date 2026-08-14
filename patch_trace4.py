import sys

file_path = "scratch/trace.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("await clientDataSource.createClient(newClient);", "await clientDataSource.create(newClient);")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

