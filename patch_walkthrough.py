import sys

file_path = "C:/Users/bft/.gemini/antigravity/brain/282ab1f6-443b-4206-aea6-3683a1c992e6/walkthrough.md"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace the Validation Results section
old_section = content[content.find("## Validation Results") : content.find("## Next Steps")]

new_section = """## Validation Results

### 1. Successfully manually verified:
- Canonical Owner role creation
- Owner priority = 1000
- Owner permission display (checked and visually locked)
- Owner immutability constraints
- No visible duplicate system roles in the fresh/current business
- Firestore canonical Owner role uses `role-owner` ID
- Firestore Owner priority is 1000
- Application startup and navigation stability

### 2. Verified by code review / SQLite tests:
- v12 SQLite migration behavior (tests run and passed)
- Firestore migration implementation structure (code audit completed)

### 3. NOT manually reproducible in current environment:
- Legacy dynamic Owner migration
- `role-super-admin` migration
- Multiple legacy Owner roles migration
- Missing routing pointer migration
- Partial Firestore migration retry logic
- Custom role named "Owner" migration

*Note:* These scenarios are covered by code review and automated test placeholders pending emulator-based integration testing. Additionally, no non-system/custom role currently exists in the manual test business. Therefore, editable-role modification behavior (e.g. mutating custom roles) remains intentionally deferred and untested until Role Creation/Role Assignment is fully implemented in subsequent phases.

"""

content = content.replace(old_section, new_section)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
