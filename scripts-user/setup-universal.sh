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
# shellcheck source=lib/universal-package-validation.sh
source "$LIB_DIR/universal-package-validation.sh"
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
  --yes          Skip the package confirmation prompt.
  --lang CODE    Override the detected language (en, es, de, pt_BR).
  -h, --help     Show this help.

Examples:
  scripts-user/setup-universal.sh                                                      # Select the newest universal package in dist/
  scripts-user/setup-universal.sh --no-restart                                         # Install without restarting the desktop
  scripts-user/setup-universal.sh dist/punchi-dock-remastered-0.9.7-universal.plasmoid # Install an explicit package'
}

NO_RESTART=0
AUTO_YES=0
TARGET_PACKAGE=""

punchi_scan_setup_language_option "$@" || exit 1
punchi_prepare_setup_localization "$PROJECT_ROOT"

while (( $# > 0 )); do
    case "$1" in
        --no-restart)
            NO_RESTART=1
            shift
            ;;
        --yes)
            AUTO_YES=1
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

for required_command in kpackagetool6 unzip; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        punchi_gettext_format 'Error: required installation command not found: %s\n' "$required_command" >&2
        exit 1
    fi
done

DATA_ROOT="$(punchi_qt6_writable_data_root "$HOME/.local/share")"
INSTALL_DIR="$DATA_ROOT/plasma/plasmoids/$PLUGIN_ID"

# Select the package to install.

requested_package="$TARGET_PACKAGE"
automatic_selection=0
[[ -z "$requested_package" ]] && automatic_selection=1
confirmed_older=0

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

# Validate the package before touching the installation. An explicit path is
# still validated, but an older version only warns: the user already chose
# that exact package. An automatic selection asks before installing.
project_version=""
if [[ -f "$PROJECT_ROOT/metadata.json" ]]; then
    project_version="$(punchi_read_project_version "$PROJECT_ROOT/metadata.json" || true)"
fi
expected_version="$project_version"

package_version=""
validation_status=0
package_version="$(punchi_validate_universal_package \
    "$TARGET_PACKAGE" "$PLUGIN_ID" "$expected_version")" || validation_status=$?
if (( validation_status == 1 )); then
    punchi_gettext_format \
        'Error: the selected package is not a valid Punchi Dock package: %s\n' \
        "$TARGET_PACKAGE" >&2
    exit 1
fi
if (( validation_status == 2 )); then
    punchi_gettext_format \
        'Warning: the selected package version %s is older than the source version %s.\n' \
        "$package_version" "$expected_version"
    if (( automatic_selection == 1 && AUTO_YES == 0 )); then
        if [[ -t 0 ]]; then
            read -r -p "$(punchi_gettext 'Install this older package anyway? [y/N]: ')" answer
            case "${answer:-n}" in
                y|Y|yes|YES|s|S|sim|SIM|si|SI|sí|SÍ|j|J|ja|JA) ;;
                *) exit 0 ;;
            esac
            confirmed_older=1
        else
            punchi_gettext_line \
                'Error: refusing to install an older package without confirmation; use --yes to override.' >&2
            exit 1
        fi
    fi
fi

checksum_status=0
punchi_verify_package_checksum \
    "$TARGET_PACKAGE" "$DIST_DIR" "$package_version" || checksum_status=$?
case "$checksum_status" in
    0)
        punchi_gettext_format 'Checksum verified: %s\n' "$(basename "$TARGET_PACKAGE")"
        ;;
    1)
        punchi_gettext_format \
            'Error: the package checksum does not match: %s\n' \
            "$TARGET_PACKAGE" >&2
        exit 1
        ;;
    *)
        punchi_gettext_line 'Notice: no checksum file was found for this package.'
        ;;
esac

if (( automatic_selection == 1 && AUTO_YES == 0 && confirmed_older == 0 )) \
        && [[ -t 0 ]]; then
    read -r -p "$(punchi_gettext 'Install this package? [Y/n]: ')" answer
    case "${answer:-y}" in
        y|Y|yes|YES|s|S|sim|SIM|si|SI|sí|SÍ|j|J|ja|JA) ;;
        *) exit 0 ;;
    esac
fi

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
