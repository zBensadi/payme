import sys
import json
import codecs

def add_keys_to_arb(file_path, new_keys):
    with codecs.open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    for key, value in new_keys.items():
        data[key] = value

    with codecs.open(file_path, 'w', encoding='utf-8') as f:
        # Use ensure_ascii=False to write actual unicode characters
        json.dump(data, f, ensure_ascii=False, indent=2)

add_keys_to_arb('lib/l10n/app_en.arb', {
    'createRole': 'Create Role',
    'deleteRole': 'Delete Role',
    'deleteRoleConfirmation': 'Are you sure you want to delete this role?'
})

add_keys_to_arb('lib/l10n/app_fr.arb', {
    'createRole': 'Créer un rôle',
    'deleteRole': 'Supprimer le rôle',
    'deleteRoleConfirmation': 'Êtes-vous sûr de vouloir supprimer ce rôle ?'
})

add_keys_to_arb('lib/l10n/app_ar.arb', {
    'createRole': 'إنشاء دور',
    'deleteRole': 'حذف الدور',
    'deleteRoleConfirmation': 'هل أنت متأكد أنك تريد حذف هذا الدور؟'
})
