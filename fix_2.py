import os

# Fix repository_providers
file_path = r'c:\proj\payme\lib\presentation\providers\repository_providers.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('final localeCode = ref.watch(localeControllerProvider)?.languageCode ?? \'en\';', 'final String localeCode = ref.watch(localeControllerProvider)?.languageCode ?? \'en\';')
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

# Fix pdf_generation_service string interpolations
file_path = r'c:\proj\payme\lib\services\pdf_generation_service.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("'${settings.phone!}'", "settings.phone!")
content = content.replace("'${settings.email!}'", "settings.email!")
content = content.replace("'${client.phone!}'", "client.phone!")
content = content.replace("'${client.email!}'", "client.email!")
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

# Fix app_router underscores
file_path = r'c:\proj\payme\lib\presentation\routing\app_router.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('(_, __) => notifyListeners(),', '(_, _) => notifyListeners(),')
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
