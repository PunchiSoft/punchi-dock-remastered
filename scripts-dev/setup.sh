#!/usr/bin/env bash
# Developer Setup, Build & Validation Assistant for Punchi Dock Remastered
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Cleanup handler: remove partial build staging on interruption (Ctrl+C, errors)
_punchi_setup_cleanup() {
    local exit_code=$?
    local package_root="$PROJECT_ROOT/build/package-root"
    if [[ -d "$package_root" && ! -f "$package_root/metadata.json" ]]; then
        echo ""
        echo "Cleaning up incomplete build staging directory: $package_root" >&2
        rm -rf "$package_root"
    fi
    exit "$exit_code"
}
trap _punchi_setup_cleanup EXIT INT TERM

# shellcheck source=lib/setup-logging.sh
source "$SCRIPT_DIR/lib/setup-logging.sh"
# shellcheck source=../scripts-user/lib/setup-localization.sh
source "$PROJECT_ROOT/scripts-user/lib/setup-localization.sh"
# shellcheck source=../scripts-user/lib/qtpaths-resolver.sh
source "$PROJECT_ROOT/scripts-user/lib/qtpaths-resolver.sh"
# shellcheck source=../scripts-user/lib/build-concurrency.sh
source "$PROJECT_ROOT/scripts-user/lib/build-concurrency.sh"

# ---------------------------------------------------------------------------
# Localized developer-assistant messages
# ---------------------------------------------------------------------------
msg() {
    local key="$1"
    shift
    case "$key" in
        help)
            punchi_gettext_line 'Usage: scripts-dev/setup.sh [options | path_to_package.plasmoid]

Master interactive and CLI assistant for packaging, testing and installing
Punchi Dock Remastered. Automatically detects the host distribution
(Fedora, Debian 13, or Arch Linux and supported derivatives).

If run without arguments, it opens the accessible interactive menu.

CLI Options:
  -j, --jobs N        Set parallel build and test jobs count (e.g. -j 1 for safe mode).
  --parallel N        Alias for --jobs.
  --local-test        Build, install on local Plasma Shell and collect logs.
  --clean-install     Remove existing installation, rebuild and install fresh.
  --yes               Pass affirmative answer to the package manager.
  --skip-dnf          Skip DNF installation on Fedora.
  --skip-apt          Skip APT installation on Debian.
  --skip-update       Skip apt-get update on Debian.
  --skip-pacman       Skip pacman installation on Arch Linux.
  --dependencies-only Check and install dependencies without building.
  --uninstall         Remove the plasmoid from the local Plasma installation.
  --dry-run           Show planned commands without modifying the system.
  --lang CODE         Override the detected language (en, es, de, pt_BR).
  -h, --help          Show this help.

Examples:
  ./scripts-dev/setup.sh                            # Interactive menu mode
  ./scripts-dev/setup.sh --local-test               # Quick local test mode
  ./scripts-dev/setup.sh --clean-install            # Force clean reinstall
  ./scripts-dev/setup.sh dist/my-package.plasmoid   # Direct .plasmoid install'
            ;;
        err_root)
            punchi_gettext_line 'Error: Run this script as the Plasma desktop user, NOT with sudo.' >&2
            punchi_gettext_line 'The script will request sudo only when the detected package manager needs to install packages.' >&2
            ;;
        err_no_osrel)
            punchi_gettext_line 'Error: Could not identify the distribution from /etc/os-release.' >&2
            ;;
        err_unsup_deb)
            punchi_gettext_format 'Error: Unsupported Debian version for building: %s.\n' "${1:-unknown}" >&2
            punchi_gettext_line 'Supported build environments: Debian 13 (Trixie), Fedora, or Arch Linux.' >&2
            punchi_gettext_line 'To install a prebuilt .plasmoid use: ./scripts-user/setup-universal.sh' >&2
            ;;
        warn_unsup_dist)
            punchi_gettext_format 'Notice: This distribution (%s) is not an official C++ build environment.\n' "${1:-unknown}" >&2
            punchi_gettext_line 'Supported build environments: Fedora, Debian 13, and Arch Linux.' >&2
            punchi_gettext_line 'To install a prebuilt .plasmoid, use: ./scripts-user/setup-universal.sh' >&2
            ;;
        err_no_profile)
            punchi_gettext_format 'Error: Cannot build natively on this system (%s).\n' "${1:-unknown}" >&2
            punchi_gettext_line 'Use: ./scripts-user/setup-universal.sh <path/to/package.plasmoid> to install.' >&2
            ;;
        err_no_cli_prof)
            punchi_gettext_format 'Error: No build profile exists for the distribution: %s.\n' "${1:-unknown}" >&2
            ;;
        banner)
            echo "=========================================================="
            punchi_gettext_line '   Punchi Dock Remastered - Master Setup Assistant        '
            echo "=========================================================="
            ;;
        detected_host)
            punchi_gettext_format 'Detected host: %s (%s)\n' "${1:-unknown}" "$(uname -m)"
            ;;
        ram_info)
            punchi_gettext_format 'Detected RAM: %s | CPU Cores: %s\n' "${1:-unknown}" "${2:-unknown}"
            ;;
        concurrency_info)
            punchi_gettext_format 'Active build concurrency: %s\n' "${1:-unknown}"
            ;;
        menu_question)   punchi_gettext_line 'What would you like to do?' ;;
        menu_opt1)       punchi_gettext_line '  [1] Build official release package (Release in dist/)' ;;
        menu_opt2)       punchi_gettext_line '  [2] Build, install and test locally (--local-test)' ;;
        menu_opt3)       punchi_gettext_line '  [3] Install an existing .plasmoid package from dist/' ;;
        menu_opt4)       punchi_gettext_line '  [4] Clean install (remove current + rebuild + install)' ;;
        menu_opt5)       punchi_gettext_line '  [5] Check and install build dependencies only' ;;
        menu_opt6)       punchi_gettext_line '  [6] Configure build concurrency (Safe / Balanced / Custom)' ;;
        menu_opt7)       punchi_gettext_line '  [7] Uninstall the plasmoid from this system' ;;
        menu_opt8)       punchi_gettext_line '  [8] Help (show CLI commands reference)' ;;
        menu_opt9)       punchi_gettext_line '  [9] Exit' ;;
        menu_prompt)     punchi_gettext 'Select an option [1-9]: ' ;;
        start_release)   punchi_gettext_line '==> Starting Release build...' ;;
        start_local)     punchi_gettext_line '==> Starting build and local test...' ;;
        start_clean)     punchi_gettext_line '==> Starting clean install (remove + rebuild + install)...' ;;
        start_deps)      punchi_gettext_line '==> Checking and installing build dependencies...' ;;
        start_uninstall) punchi_gettext_line '==> Uninstalling the plasmoid...' ;;
        uninstall_done)  punchi_gettext_line '==> Plasmoid uninstalled successfully.' ;;
        uninstall_none)  punchi_gettext_line 'Notice: No local installation found for the plasmoid.' ;;
        clean_removed)   punchi_gettext_format '==> Removed existing installation: %s\n' "${1:-}" ;;
        start_plasma_restart) punchi_gettext_line '==> Restarting Plasma Shell...' ;;
        restart_done)    punchi_gettext_line '==> Plasma Shell restart requested.' ;;
        prompt_restart)  punchi_gettext 'Would you like to restart Plasma Shell now? [y/N]: ' ;;
        cancelled)       punchi_gettext_line 'Operation cancelled.' ;;
        err_invalid_opt) punchi_gettext_format 'Error: Invalid option: %s\n' "${1:-}" >&2 ;;
        quick_ref)
            echo ""
            punchi_gettext_line 'CLI Quick Reference
==================
  ./scripts-dev/setup.sh                    Interactive menu (this screen)
  ./scripts-dev/setup.sh --local-test       Build, install and test locally
  ./scripts-dev/setup.sh --clean-install    Force remove + full rebuild + install
  ./scripts-dev/setup.sh --dependencies-only  Check/install build dependencies
  ./scripts-dev/setup.sh --uninstall        Remove the plasmoid from Plasma
  ./scripts-dev/setup.sh --dry-run          Preview commands without executing
  ./scripts-dev/setup.sh --yes              Auto-accept package manager prompts
  ./scripts-dev/setup.sh --help             Show full help with all options
  ./scripts-dev/setup.sh <file.plasmoid>    Install a prebuilt package directly'
            echo ""
            punchi_gettext_format 'Logs: docs/logs/%s/setup-%s-latest.log\n' "$DETECTED_PROFILE" "$DETECTED_PROFILE"
            punchi_gettext_line 'Docs: scripts-dev/README.md | scripts-dev/README.es.md'
            echo ""
            ;;
        *)
            printf 'Internal error: unknown developer setup message key: %s\n' "$key" >&2
            return 2
            ;;
    esac
}

prepare_setup_arguments() {
    local -a filtered_arguments=()
    local -a remaining_arguments=()

    punchi_scan_setup_language_option "$@" || return
    punchi_prepare_setup_localization "$PROJECT_ROOT"
    punchi_filter_setup_language_options filtered_arguments "$@" || return

    while (( ${#filtered_arguments[@]} > 0 )); do
        case "${filtered_arguments[0]}" in
            -j|--jobs|--parallel)
                if (( ${#filtered_arguments[@]} < 2 )); then
                    printf 'Error: %s requires a positive integer argument\n' "${filtered_arguments[0]}" >&2
                    return 1
                fi
                punchi_set_concurrency_level "${filtered_arguments[1]}" || {
                    printf 'Error: invalid number of parallel jobs: %s\n' "${filtered_arguments[1]}" >&2
                    return 1
                }
                filtered_arguments=("${filtered_arguments[@]:2}")
                ;;
            -j=*|--jobs=*|--parallel=*)
                local val="${filtered_arguments[0]#*=}"
                punchi_set_concurrency_level "$val" || {
                    printf 'Error: invalid number of parallel jobs: %s\n' "$val" >&2
                    return 1
                }
                filtered_arguments=("${filtered_arguments[@]:1}")
                ;;
            *)
                remaining_arguments+=("${filtered_arguments[0]}")
                filtered_arguments=("${filtered_arguments[@]:1}")
                ;;
        esac
    done

    PUNCHI_DEV_SETUP_ARGUMENTS=("${remaining_arguments[@]}")
}

# ---------------------------------------------------------------------------
# Helper: Resolve plasmoid install directory
# ---------------------------------------------------------------------------
_punchi_resolve_install_dir() {
    local plugin_id="org.kde.plasma.punchi-dock-remastered"
    local data_root=""
    data_root="$(punchi_qt6_writable_data_root "$HOME/.local/share")"
    echo "$data_root/plasma/plasmoids/$plugin_id"
}

# ---------------------------------------------------------------------------
# Helper: Restart Plasma Shell
# ---------------------------------------------------------------------------
_punchi_restart_plasma() {
    msg start_plasma_restart
    local previous_pid=""
    local current_pid=""

    previous_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"

    if command -v systemctl >/dev/null 2>&1 \
        && systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
        systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
        sleep 1
        current_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
        if [[ -n "$previous_pid" && "$current_pid" == "$previous_pid" ]]; then
            if command -v kquitapp6 >/dev/null 2>&1; then
                kquitapp6 plasmashell >/dev/null 2>&1 || true
            else
                killall plasmashell >/dev/null 2>&1 || true
            fi
            sleep 0.5
            systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
        fi
    else
        if command -v kquitapp6 >/dev/null 2>&1; then
            kquitapp6 plasmashell >/dev/null 2>&1 || true
        else
            killall plasmashell >/dev/null 2>&1 || true
        fi
        sleep 1
        if command -v kstart6 >/dev/null 2>&1; then
            kstart6 plasmashell >/dev/null 2>&1 &
        elif command -v kstart >/dev/null 2>&1; then
            kstart plasmashell >/dev/null 2>&1 &
        else
            plasmashell >/dev/null 2>&1 &
        fi
    fi
    msg restart_done
}

# ---------------------------------------------------------------------------
# Helper: Uninstall the plasmoid
# ---------------------------------------------------------------------------
_punchi_uninstall() {
    local plugin_id="org.kde.plasma.punchi-dock-remastered"
    local install_dir=""
    install_dir="$(_punchi_resolve_install_dir)"
    local auto_restart="${1:-0}"

    msg start_uninstall

    if [[ -d "$install_dir" ]]; then
        kpackagetool6 --type Plasma/Applet -r "$plugin_id" 2>/dev/null || {
            echo "kpackagetool6 removal failed; removing directory manually" >&2
            rm -rf "$install_dir"
        }
        if [[ ! -d "$install_dir" ]]; then
            msg uninstall_done
        else
            echo "Error: Installation directory still exists after removal: $install_dir" >&2
            exit 1
        fi
    else
        msg uninstall_none
    fi

    if (( auto_restart == 1 )); then
        _punchi_restart_plasma
    elif (( $# == 0 )) || [[ "${interactive_mode:-0}" == "1" ]]; then
        echo ""
        read -rp "$(msg prompt_restart)" answer
        case "$answer" in
            [yY]|[sS]|[jJ]|[yY][eE][sS]|[sS][íI]|[jJ][aA])
                _punchi_restart_plasma
                ;;
        esac
    fi
}

# ---------------------------------------------------------------------------
# Helper: Clean install (remove existing + rebuild + install)
# ---------------------------------------------------------------------------
_punchi_clean_install() {
    local install_dir=""
    install_dir="$(_punchi_resolve_install_dir)"

    # Step 1: Remove existing installation if present
    if [[ -d "$install_dir" ]]; then
        local plugin_id="org.kde.plasma.punchi-dock-remastered"
        kpackagetool6 --type Plasma/Applet -r "$plugin_id" 2>/dev/null || {
            rm -rf "$install_dir"
        }
        msg clean_removed "$install_dir"
    fi

    # Step 2: Clean the build directory to force a full recompilation
    local build_dir="$PROJECT_ROOT/build"
    if [[ -d "$build_dir" ]]; then
        rm -rf "$build_dir"
        echo "==> Build cache cleared: $build_dir"
    fi
    local xdg_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/punchi-dock-remastered"
    if [[ -d "$xdg_cache_dir" ]]; then
        rm -rf "$xdg_cache_dir"
        echo "==> XDG build cache cleared: $xdg_cache_dir"
    fi

    # The setup catalogs live under build/ and may have been removed above.
    punchi_prepare_setup_localization "$PROJECT_ROOT"

    # Step 3: Rebuild and install via --local-test
    PUNCHI_LOG_DIR="${PUNCHI_LOG_DIR:-$PROJECT_ROOT/docs/logs/$DETECTED_PROFILE}"
    punchi_run_setup_with_log "$DETECTED_PROFILE" "$SETUP_EXEC" --local-test
}

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------
declare -a PUNCHI_DEV_SETUP_ARGUMENTS=()
prepare_setup_arguments "$@" || exit 1
set -- "${PUNCHI_DEV_SETUP_ARGUMENTS[@]}"

if (( EUID == 0 )); then
    msg err_root
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    msg err_no_osrel
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

DETECTED_PROFILE=""
SETUP_EXEC=""

case "${ID:-}" in
    fedora)
        DETECTED_PROFILE="fedora"
        SETUP_EXEC="$SCRIPT_DIR/distro/fedora-setup.sh"
        ;;
    debian)
        DETECTED_PROFILE="debian13"
        SETUP_EXEC="$SCRIPT_DIR/distro/debian13-setup.sh"
        ;;
    ubuntu|kubuntu|mint|pop)
        DETECTED_PROFILE="debian13"
        SETUP_EXEC="$SCRIPT_DIR/distro/debian13-setup.sh"
        ;;
    arch|manjaro|endeavouros|garuda|artix)
        DETECTED_PROFILE="arch"
        SETUP_EXEC="$SCRIPT_DIR/distro/arch-setup.sh"
        ;;
    *)
        if [[ " ${ID_LIKE:-} " == *' arch '* ]]; then
            DETECTED_PROFILE="arch"
            SETUP_EXEC="$SCRIPT_DIR/distro/arch-setup.sh"
        fi
        if [[ "${1:-}" != "-h" && "${1:-}" != "--help" && "${1:-}" != *.plasmoid ]]; then
            if [[ -z "$DETECTED_PROFILE" ]]; then
                msg warn_unsup_dist "${PRETTY_NAME:-unknown}"
            fi
        fi
        ;;
esac

# ---------------------------------------------------------------------------
# 1. Help
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    msg help
    exit 0
fi

# ---------------------------------------------------------------------------
# 2. Direct .plasmoid file (Works on ANY distribution)
# ---------------------------------------------------------------------------
if [[ "${1:-}" == *.plasmoid ]]; then
    exec "$PROJECT_ROOT/scripts-user/setup-universal.sh" "$1"
fi

# ---------------------------------------------------------------------------
# 3. Interactive mode (no arguments)
# ---------------------------------------------------------------------------
if (( $# == 0 )); then
    interactive_mode=1
    ram_mb="$(punchi_detect_total_ram_mb)"
    ram_display="$(punchi_format_ram_display "$ram_mb")"
    cpu_cores="$(punchi_detect_cpu_cores)"

    while true; do
        current_jobs="$(punchi_get_concurrency_level)"
        echo ""
        msg banner
        msg detected_host "${PRETTY_NAME:-$ID}"
        msg ram_info "$ram_display" "$cpu_cores"
        msg concurrency_info "$(punchi_concurrency_profile_label "$current_jobs")"
        echo ""
        msg menu_question
        msg menu_opt1
        msg menu_opt2
        msg menu_opt3
        msg menu_opt4
        msg menu_opt5
        msg menu_opt6
        msg menu_opt7
        msg menu_opt8
        msg menu_opt9
        echo ""
        read -rp "$(msg menu_prompt)" choice

        case "$choice" in
            1)
                if [[ -z "$DETECTED_PROFILE" ]]; then
                    msg err_no_profile "${PRETTY_NAME:-unknown}"
                    exit 1
                fi
                msg start_release
                PUNCHI_LOG_DIR="${PUNCHI_LOG_DIR:-$PROJECT_ROOT/docs/logs/$DETECTED_PROFILE}"
                punchi_run_setup_with_log "$DETECTED_PROFILE" "$SETUP_EXEC"
                break
                ;;
            2)
                if [[ -z "$DETECTED_PROFILE" ]]; then
                    msg err_no_profile "${PRETTY_NAME:-unknown}"
                    exit 1
                fi
                msg start_local
                PUNCHI_LOG_DIR="${PUNCHI_LOG_DIR:-$PROJECT_ROOT/docs/logs/$DETECTED_PROFILE}"
                punchi_run_setup_with_log "$DETECTED_PROFILE" "$SETUP_EXEC" --local-test
                break
                ;;
            3)
                exec "$SCRIPT_DIR/instalar-plasmoide.sh"
                ;;
            4)
                if [[ -z "$DETECTED_PROFILE" ]]; then
                    msg err_no_profile "${PRETTY_NAME:-unknown}"
                    exit 1
                fi
                msg start_clean
                _punchi_clean_install
                break
                ;;
            5)
                if [[ -z "$DETECTED_PROFILE" ]]; then
                    msg err_no_profile "${PRETTY_NAME:-unknown}"
                    exit 1
                fi
                msg start_deps
                PUNCHI_LOG_DIR="${PUNCHI_LOG_DIR:-$PROJECT_ROOT/docs/logs/$DETECTED_PROFILE}"
                punchi_run_setup_with_log "$DETECTED_PROFILE" "$SETUP_EXEC" --dependencies-only
                break
                ;;
            6)
                punchi_configure_build_concurrency_interactive
                ;;
            7)
                _punchi_uninstall
                break
                ;;
            8)
                msg quick_ref
                ;;
            9|[qQ])
                msg cancelled
                exit 0
                ;;
            *)
                msg err_invalid_opt "$choice"
                ;;
        esac
    done
else
    # ---------------------------------------------------------------------------
    # 4. Direct CLI mode with flags
    # ---------------------------------------------------------------------------
    if [[ "${1:-}" == "--restart" ]]; then
        _punchi_restart_plasma
        exit 0
    fi

    if [[ "${1:-}" == "--uninstall" ]]; then
        local do_restart=0
        if [[ "${2:-}" == "--restart" || "${2:-}" == "-r" ]]; then
            do_restart=1
        fi
        _punchi_uninstall "$do_restart"
        exit $?
    fi

    if [[ -z "$DETECTED_PROFILE" ]]; then
        msg err_no_cli_prof "${ID:-unknown}"
        exit 1
    fi

    if [[ "${1:-}" == "--clean-install" ]]; then
        msg start_clean
        _punchi_clean_install
        exit $?
    fi

    PUNCHI_LOG_DIR="${PUNCHI_LOG_DIR:-$PROJECT_ROOT/docs/logs/$DETECTED_PROFILE}"
    punchi_run_setup_with_log "$DETECTED_PROFILE" "$SETUP_EXEC" "$@"
fi
