#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/plasma-version.sh
source "$SCRIPT_DIR/lib/plasma-version.sh"

# shellcheck disable=SC1091
source /etc/os-release
PACKAGE_VERSION="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")"
PLATFORM_LABEL="${ID:-linux}${VERSION_ID:-unknown}-$(uname -m)"
if [[ "${ID:-}" == "ubuntu" ]]; then
    PLASMA_VERSION_OUTPUT="$(plasmashell --version 2>&1 || true)"
    PLASMA_VERSION="$(punchi_extract_plasma_version "$PLASMA_VERSION_OUTPUT")"
    if [[ ! "$PLASMA_VERSION" =~ ^6\. ]]; then
        echo "Error: Punchi Dock requires Plasma 6 (version output: ${PLASMA_VERSION_OUTPUT:-empty})." >&2
        exit 1
    fi
    SAFE_PLASMA_VERSION="${PLASMA_VERSION//[^[:alnum:]._-]/_}"
    PLATFORM_LABEL="kubuntu${VERSION_ID:-unknown}-plasma${SAFE_PLASMA_VERSION:-unknown}-$(uname -m)"
fi
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

restart_plasma_shell() {
    local previous_pid=""
    local current_pid=""

    previous_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
    echo "Plasma Shell PID before restart: ${previous_pid:-not running}"

    if command -v systemctl >/dev/null 2>&1 \
        && systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
        echo "Restart method: systemd user service"
        systemctl --user restart plasma-plasmashell.service

        sleep 1
        current_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
        if [[ -n "$previous_pid" && "$current_pid" == "$previous_pid" ]]; then
            echo "Systemd kept the existing process; forcing a KDE-controlled stop"
            if command -v kquitapp6 >/dev/null 2>&1; then
                kquitapp6 plasmashell >/dev/null 2>&1 || true
            else
                killall plasmashell >/dev/null 2>&1 || true
            fi

            sleep 0.5
            if kill -0 "$previous_pid" >/dev/null 2>&1; then
                echo "The previous process is still alive; sending SIGTERM to PID $previous_pid"
                kill "$previous_pid" >/dev/null 2>&1 || true
            fi

            for _stop_attempt in {1..20}; do
                if ! kill -0 "$previous_pid" >/dev/null 2>&1; then
                    break
                fi
                sleep 0.25
            done

            systemctl --user restart plasma-plasmashell.service
        fi
    else
        echo "Restart method: KDE application control"
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
    fi

    for _attempt in {1..20}; do
        current_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
        if [[ -n "$current_pid" && "$current_pid" != "$previous_pid" ]]; then
            echo "Plasma Shell PID after restart: $current_pid"
            echo "Plasma Shell restart confirmed"
            return 0
        fi
        sleep 0.25
    done

    echo "Error: Plasma Shell PID did not change after the restart request." >&2
    return 1
}

PUNCHI_LOCAL_TEST=1 PACKAGE_OUTPUT_FILE="$ZIP_FILE" "$SCRIPT_DIR/empaquetar-plasmoid.sh"

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

if [[ ! -f "$INSTALL_DIR/metadata.json" ]]; then
    echo "Error: kpackagetool6 did not leave a valid installation in $INSTALL_DIR" >&2
    exit 1
fi

echo "Installed package: $ZIP_FILE"
echo "Installation directory: $INSTALL_DIR"

echo "==> [2/3] Restarting Plasma Shell"
restart_plasma_shell

echo "==> [3/3] Collecting local startup diagnostics"
sleep 4
journalctl --user --since "10 seconds ago" | grep -iE "punchi|qml|typeerror|referenceerror|dockmodel" > "$DEBUG_LOG" || true

echo "Local test installation and Plasma restart completed. Diagnostics: $DEBUG_LOG"
