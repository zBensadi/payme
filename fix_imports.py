import os

with open(r'c:\proj\payme\lib\presentation\providers\repository_providers.dart', 'r', encoding='utf-8') as f:
    content = f.read()

bad_imports = "import 'dart:ui';\nimport 'package:flutter_gen/gen_l10n/app_localizations.dart';\nimport 'locale_controller.dart';\nimport '../../core/pdf/app_pdf_localizations.dart';\n"
content = content.replace(bad_imports, "")
content = bad_imports + content

with open(r'c:\proj\payme\lib\presentation\providers\repository_providers.dart', 'w', encoding='utf-8') as f:
    f.write(content)
