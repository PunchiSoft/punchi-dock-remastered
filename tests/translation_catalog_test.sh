#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRANSLATION_DOMAIN="plasma_applet_org.kde.plasma.punchi-dock-remastered"
POT_FILE="$PROJECT_ROOT/po/$TRANSLATION_DOMAIN.pot"

if [[ ! -f "$POT_FILE" ]]; then
    echo "Required translation template is missing: $POT_FILE" >&2
    exit 1
fi

shopt -s nullglob
catalogs=("$PROJECT_ROOT/po"/*.po)
if (( ${#catalogs[@]} == 0 )); then
    echo "No translation catalogs were found in $PROJECT_ROOT/po" >&2
    exit 1
fi

for catalog in "${catalogs[@]}"; do
    msgfmt --check --check-format --output-file=/dev/null "$catalog"
    msgcmp --use-fuzzy "$catalog" "$POT_FILE"

    untranslated_count="$(msgattrib --untranslated --no-obsolete "$catalog" | grep -c '^msgid ' || true)"
    if (( untranslated_count > 1 )); then
        echo "The catalog contains untranslated messages: $catalog" >&2
        exit 1
    fi

    fuzzy_count="$(msgattrib --only-fuzzy --no-obsolete "$catalog" | grep -c '^msgid ' || true)"
    if (( fuzzy_count > 1 )); then
        echo "The catalog contains fuzzy messages: $catalog" >&2
        exit 1
    fi
done

if msggrep --msgid --extended-regexp \
    --regexp='(Aplicación|Configuración|Papelera|Vaciar|Añadir|Eliminar|Español)' \
    "$POT_FILE" | grep -q '^msgid'; then
    echo "A Spanish source message was found. Runtime source text must remain in English." >&2
    exit 1
fi
