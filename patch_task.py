import sys

file_path = "C:/Users/bft/.gemini/antigravity/brain/282ab1f6-443b-4206-aea6-3683a1c992e6/task.md"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("- [ ] Update `walkthrough.md` and `task.md`.", "- [x] Update `walkthrough.md` and `task.md`.")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
