#!/usr/bin/env bash
# User-facing installer for an existing Punchi Dock .plasmoid package.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
DIST_DIR="$PROJECT_ROOT/dist"

# shellcheck source=lib/setup-localization.sh
source "$LIB_DIR/setup-localization.sh"
# shellcheck source=lib/local-package-install.sh
source "$LIB_DIR/local-package-install.sh"
# shellcheck source=lib/plasma-runtime-diagnostics.sh
source "$LIB_DIR/plasma-runtime-diagnostics.sh"
# shellcheck source=lib/universal-package-selection.sh
source "$LIB_DIR/universal-package-selection.sh"
# shellcheck source=lib/plasma-shell-control.sh
source "$LIB_DIR/plasma-shell-control.sh"
# shellcheck source=lib/qtpaths-resolver.sh
source "$LIB_DIR/qtpaths-resolver.sh"

PLUGIN_ID="org.kde.plasma.punchi-dock-remastered"
DEBUG_LOG="$PROJECT_ROOT/debug.log"
DATA_ROOT=""
INSTALL_DIR=""

show_help() {
    punchi_gettext_line 'Usage: scripts-user/setup-universal.sh [--no-restart] [path/to/package.plasmoid]

Installs or updates Punchi Dock Remastered from an existing .plasmoid package.
Plasma Shell is restarted afterward unless --no-restart is specified.

Options:
  --no-restart   Install without restarting Plasma Shell.
  --lang CODE    Override the detected language (en, es, de, pt_BR).
  -h, --help     Show this help.

Examples:
  scripts-user/setup-universal.sh                                                      # Select the newest universal package in dist/
  scripts-user/setup-universal.sh --no-restart                                         # Install without restarting the desktop
  scripts-user/setup-universal.sh dist/punchi-dock-remastered-0.9.7-universal.plasmoid # Install an explicit package'
}

NO_RESTART=0
TARGET_PACKAGE=""

punchi_scan_setup_language_option "$@" || exit 1
punchi_prepare_setup_localization "$PROJECT_ROOT"

while (( $# > 0 )); do
    case "$1" in
        --no-restart)
            NO_RESTART=1
            shift
            ;;
        --lang)
            shift 2
            ;;
        --lang=*)
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *.plasmoid)
            if [[ -z "$TARGET_PACKAGE" ]]; then
                TARGET_PACKAGE="$1"
            else
                punchi_gettext_line 'Error: only one .plasmoid package can be installed at a time.' >&2
                exit 1
            fi
            shift
            ;;
        *)
            punchi_gettext_format 'Error: unknown option or invalid package path: %s\n' "$1" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

for required_command in kpackagetool6; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        punchi_gettext_format 'Error: required installation command not found: %s\n' "$required_command" >&2
        exit 1
    fi
done

DATA_ROOT="$(punchi_qt6_writable_data_root "$HOME/.local/share")"
INSTALL_DIR="$DATA_ROOT/plasma/plasmoids/$PLUGIN_ID"

# Select the package to install.

TARGET_PACKAGE="$(punchi_select_universal_package "$DIST_DIR" "$TARGET_PACKAGE" || true)"

if [[ -z "$TARGET_PACKAGE" || ! -f "$TARGET_PACKAGE" ]]; then
    punchi_gettext_format "Error: no universal .plasmoid was found in '%s' and no valid package path was provided.\n" "$DIST_DIR" >&2
    punchi_gettext_line 'Usage: scripts-user/setup-universal.sh [--no-restart] <path/to/package.plasmoid>' >&2
    exit 1
fi

echo "=========================================================="
punchi_gettext_line '  Punchi Dock Remastered - Package Installer             '
echo "=========================================================="
punchi_gettext_format 'Selected package: %s\n' "$TARGET_PACKAGE"
punchi_gettext_format 'Installation directory: %s\n' "$INSTALL_DIR"
echo ""

punchi_gettext_line '==> [1/3] Installing or updating the plasmoid...'
punchi_install_local_package "$TARGET_PACKAGE" "$INSTALL_DIR" "$DATA_ROOT" "$PLUGIN_ID"

if [[ ! -f "$INSTALL_DIR/metadata.json" ]]; then
    punchi_gettext_format 'Error: kpackagetool6 did not leave a valid installation in %s\n' "$INSTALL_DIR" >&2
    exit 1
fi

punchi_gettext_format 'Installation completed in: %s\n' "$INSTALL_DIR"
echo ""

if (( NO_RESTART == 0 )); then
    punchi_gettext_line '==> [2/3] Restarting Plasma Shell...'
    restart_started_at="$(date --iso-8601=seconds)"
    punchi_restart_plasma_shell

    echo ""
    punchi_gettext_line '==> [3/3] Collecting startup diagnostics...'
    sleep 5
    if ! kill -0 "$PUNCHI_PLASMA_PID" >/dev/null 2>&1; then
        punchi_gettext_format 'Error: Plasma Shell PID %s stopped during startup.\n' "$PUNCHI_PLASMA_PID" >&2
        exit 1
    fi
    punchi_collect_plasma_runtime_diagnostics \
        "$PUNCHI_PLASMA_PID" "$restart_started_at" "$DEBUG_LOG" "$PLUGIN_ID"

    echo ""
    echo "=========================================================="
    punchi_gettext_line 'Installation or update completed successfully.'
    punchi_gettext_format 'Installed package: %s\n' "${TARGET_PACKAGE#"$PROJECT_ROOT/"}"
    punchi_gettext_format 'Diagnostics saved to: %s\n' "$DEBUG_LOG"
    echo "=========================================================="
else
    echo "=========================================================="
    punchi_gettext_line 'Installation completed without restarting Plasma Shell.'
    punchi_gettext_format 'Installed package: %s\n' "${TARGET_PACKAGE#"$PROJECT_ROOT/"}"
    punchi_gettext_line 'Log out and back in or restart Plasma later to apply the changes.'
    echo "=========================================================="
fi
