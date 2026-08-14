import sys

file_path = "scratch/trace.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("void main() async {\n  sqfliteFfiInit();", "void main() async {\n  TestWidgetsFlutterBinding.ensureInitialized();\n  sqfliteFfiInit();")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

