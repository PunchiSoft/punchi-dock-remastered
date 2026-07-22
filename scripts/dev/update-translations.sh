#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
TRANSLATION_DOMAIN="plasma_applet_org.kde.plasma.punchi-dock-remastered"
PO_DIR="$PROJECT_ROOT/po"
POT_FILE="$PO_DIR/$TRANSLATION_DOMAIN.pot"

for required_command in xgettext msgcat msgmerge msgfmt; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        echo "Required command not found: $required_command" >&2
        exit 1
    fi
done

mkdir -p "$PO_DIR"
podir="$PO_DIR" "$PROJECT_ROOT/Messages.sh"

shopt -s nullglob
catalogs=("$PO_DIR"/*.po)
for catalog in "${catalogs[@]}"; do
    msgmerge --update --backup=none --previous "$catalog" "$POT_FILE"
    msgfmt --check --check-format --output-file=/dev/null "$catalog"
    echo "Translation catalog updated: $catalog"
done

if (( ${#catalogs[@]} == 0 )); then
    echo "No PO catalogs exist yet. Create one with msginit using: $POT_FILE"
fi
