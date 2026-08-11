import re

file_path = r'c:\proj\payme\lib\services\pdf_generation_service.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import if not exists
if 'arabic_reshaper.dart' not in content:
    content = content.replace("import 'package:pdf/widgets.dart' as pw;", "import 'package:pdf/widgets.dart' as pw;\nimport 'package:arabic_reshaper/arabic_reshaper.dart';")

# Add the wrapper method at the end of the class
if '_buildText' not in content:
    wrapper_code = """
  pw.Widget _buildText(String text, {pw.TextStyle? style, pw.TextAlign? textAlign, pw.TextDirection? textDirection}) {
    return pw.Text(
      ArabicReshaper.instance.reshape(text),
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
    );
  }
}
"""
    content = content.rstrip()
    if content.endswith('}'):
        content = content[:-1] + wrapper_code

# Replace pw.Text( with _buildText(
# We need to make sure we don't match pw.TextDirection or pw.TextStyle
content = re.sub(r'pw\.Text\(', '_buildText(', content)

# But wait, inside _buildText itself, we just replaced it!
# Let's fix that one back.
content = content.replace('return _buildText(\n      ArabicReshaper', 'return pw.Text(\n      ArabicReshaper')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Replacement complete.")
