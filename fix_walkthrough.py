import sys

file_path = "C:/Users/bft/.gemini/antigravity/brain/282ab1f6-443b-4206-aea6-3683a1c992e6/walkthrough.md"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("uses \nole-owner ID", "uses `role-owner` ID")
content = content.replace("- \nole-super-admin is not present", "- `role-super-admin` is not present")
content = content.replace("- \nole-super-admin migration", "- `role-super-admin` migration")
content = content.replace("uses \role-owner ID", "uses `role-owner` ID")
content = content.replace("- \role-super-admin is not present", "- `role-super-admin` is not present")
content = content.replace("- \role-super-admin migration", "- `role-super-admin` migration")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
