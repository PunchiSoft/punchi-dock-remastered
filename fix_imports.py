import os
import re

directory = "contents/ui/config/"

replacements = {
    'import "code/iconPickerController.js" as IconPickerController': 'import "code/iconPickerController.js" as IconPickerJS',
    'IconPickerController.': 'IconPickerJS.',
    'import "code/configItems.js" as ConfigItems\n': 'import "code/configItems.js" as ConfigItemsJS\n',
    'ConfigItems.': 'ConfigItemsJS.',
    'import "code/configScripts.js" as ConfigScripts': 'import "code/configScripts.js" as ConfigScriptsJS',
    'ConfigScripts.': 'ConfigScriptsJS.',
    'import "code/configUi.js" as ConfigUi': 'import "code/configUi.js" as ConfigUiJS',
    'ConfigUi.': 'ConfigUiJS.',
    'import "code/items.js" as Items\n': 'import "code/items.js" as ItemsJS\n',
    'Items.': 'ItemsJS.',
    'import "code/i18n.js" as I18n': 'import "code/i18n.js" as I18nJS',
    'I18n.': 'I18nJS.',
    'import "code/configItemsController.js" as ConfigItemsController': 'import "code/configItemsController.js" as ConfigItemsControllerJS',
    'ConfigItemsController.': 'ConfigItemsControllerJS.'
}

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith(".qml"):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
            
            new_content = content
            for old, new in replacements.items():
                # We do a simple string replace.
                # For `ConfigItems.`, we need to make sure we don't accidentally replace `ConfigItemsMainView`
                if old == 'ConfigItems.':
                    new_content = new_content.replace('ConfigItems.', 'ConfigItemsJS.')
                else:
                    new_content = new_content.replace(old, new)
            
            if new_content != content:
                with open(filepath, 'w') as f:
                    f.write(new_content)
                print(f"Fixed {filepath}")

