#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSLATION_DOMAIN="plasma_applet_org.kde.plasma.punchi-dock-remastered"
OUTPUT_DIR="${podir:-$PROJECT_ROOT/po}"
XGETTEXT_BIN="${XGETTEXT:-xgettext}"

if ! command -v "$XGETTEXT_BIN" >/dev/null 2>&1; then
    echo "Required command not found: $XGETTEXT_BIN" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$PROJECT_ROOT"

mapfile -d '' qml_sources < <(
    find contents -type f \( -name '*.qml' -o -name '*.js' \) -print0 | sort -z
)
mapfile -d '' cpp_sources < <(
    find src -type f \( -name '*.cpp' -o -name '*.h' \) -print0 | sort -z
)

common_options=(
    --from-code=UTF-8
    --package-name="Punchi Dock Remastered"
    --package-version="0.8.9"
    --msgid-bugs-address="https://github.com/PunchiSoft/punchi-dock-remastered/issues"
    --copyright-holder="Punchi Dock Contributors"
    --add-comments=TRANSLATORS
    --keyword=i18n:1
    --keyword=i18nc:1c,2
    --keyword=i18np:1,2
    --keyword=i18ncp:1c,2,3
    --keyword=i18nd:2
    --keyword=i18ndc:2c,3
    --keyword=i18ndp:2,3
    --keyword=i18ndcp:2c,3,4
    --keyword=xi18n:1
    --keyword=xi18nc:1c,2
    --keyword=xi18np:1,2
    --keyword=xi18ncp:1c,2,3
    --keyword=xi18nd:2
    --keyword=xi18ndc:2c,3
    --keyword=xi18ndp:2,3
    --keyword=xi18ndcp:2c,3,4
)

"$XGETTEXT_BIN" \
    "${common_options[@]}" \
    --language=JavaScript \
    --output="$TEMP_DIR/qml.pot" \
    "${qml_sources[@]}"

"$XGETTEXT_BIN" \
    "${common_options[@]}" \
    --language=C++ \
    --output="$TEMP_DIR/cpp.pot" \
    "${cpp_sources[@]}"

extracted_templates=("$TEMP_DIR/qml.pot")
if [[ -f "$TEMP_DIR/cpp.pot" ]]; then
    extracted_templates+=("$TEMP_DIR/cpp.pot")
fi

msgcat \
    --use-first \
    --sort-output \
    --output="$OUTPUT_DIR/$TRANSLATION_DOMAIN.pot" \
    "${extracted_templates[@]}"

echo "Translation template updated: $OUTPUT_DIR/$TRANSLATION_DOMAIN.pot"
