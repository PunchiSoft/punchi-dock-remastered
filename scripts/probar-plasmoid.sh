#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source /etc/os-release
PACKAGE_VERSION="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")"
PLATFORM_LABEL="${ID:-linux}${VERSION_ID:-unknown}-$(uname -m)"
ZIP_FILE="$PROJECT_ROOT/dist/punchi-dock-remastered-${PACKAGE_VERSION}-${PLATFORM_LABEL}-local-test.plasmoid"
DEBUG_LOG="$PROJECT_ROOT/debug.log"
PLUGIN_ID="org.kde.plasma.punchi-dock-remastered"
DATA_ROOT="$(qtpaths6 --writable-path GenericDataLocation)"
INSTALL_DIR="$DATA_ROOT/plasma/plasmoids/$PLUGIN_ID"
BROKEN_INSTALL_BACKUP=""

restore_broken_install() {
    if [[ -n "$BROKEN_INSTALL_BACKUP" && -d "$BROKEN_INSTALL_BACKUP" && ! -e "$INSTALL_DIR" ]]; then
        mv "$BROKEN_INSTALL_BACKUP" "$INSTALL_DIR"
    fi
}

PACKAGE_OUTPUT_FILE="$ZIP_FILE" "$SCRIPT_DIR/empaquetar-plasmoid.sh"

echo "==> [1/3] Installing the local test package"
if [[ -d "$INSTALL_DIR" && ! -f "$INSTALL_DIR/metadata.json" ]]; then
    BROKEN_INSTALL_BACKUP="$DATA_ROOT/${PLUGIN_ID}.broken.$$"
    echo "Repairing incomplete local installation: $INSTALL_DIR"
    mv "$INSTALL_DIR" "$BROKEN_INSTALL_BACKUP"
fi

if [[ -n "$BROKEN_INSTALL_BACKUP" ]]; then
    if ! kpackagetool6 --type Plasma/Applet -i "$ZIP_FILE"; then
        restore_broken_install
        exit 1
    fi
    cmake -E remove_directory "$BROKEN_INSTALL_BACKUP"
    BROKEN_INSTALL_BACKUP=""
elif ! kpackagetool6 --type Plasma/Applet -u "$ZIP_FILE" 2>/dev/null; then
    kpackagetool6 --type Plasma/Applet -i "$ZIP_FILE"
fi

echo "==> [2/3] Restarting Plasma Shell"
if command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell >/dev/null 2>&1 || true
else
    killall plasmashell >/dev/null 2>&1 || true
fi

sleep 1

if command -v kstart >/dev/null 2>&1; then
    kstart plasmashell >/dev/null 2>&1
elif command -v kstart6 >/dev/null 2>&1; then
    kstart6 plasmashell >/dev/null 2>&1
else
    plasmashell >/dev/null 2>&1 &
fi

echo "==> [3/3] Collecting local startup diagnostics"
sleep 4
journalctl --user --since "10 seconds ago" | grep -iE "punchi|qml|typeerror|referenceerror|dockmodel" > "$DEBUG_LOG" || true

echo "Local test installation completed. Diagnostics: $DEBUG_LOG"
