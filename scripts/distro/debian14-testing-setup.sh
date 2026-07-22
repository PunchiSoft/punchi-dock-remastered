#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
PLUGIN_ID="org.kde.plasma.punchi-dock-remastered"
ASSUME_YES=0
SKIP_APT=0
SKIP_RESTART=0
DEPENDENCIES_ONLY=0
LOCAL_TEST=0
DRY_RUN=0

APT_PACKAGES=(
    binutils
    build-essential
    cmake
    extra-cmake-modules
    gettext
    git
    kpackagetool6
    libkf6coreaddons-dev
    libkf6i18n-dev
    libkf6jobwidgets-dev
    libkf6kio-dev
    libkf6service-dev
    libpipewire-0.3-dev
    libplasma-dev
    ninja-build
    pkg-config
    qt6-base-dev
    qt6-base-dev-tools
    qt6-declarative-dev
    qt6-declarative-dev-tools
    qt6-qmltooling-plugins
    unzip
    zip
)

REQUIRED_COMMANDS=(
    cmake
    ctest
    c++
    kpackagetool6
    msgattrib
    msgfmt
    pkg-config
    qtpaths6
    readelf
    strip
    unzip
    zip
)

usage() {
    cat <<'EOF'
Usage: scripts/setup-debian14-testing.sh [options]

Prepare Debian 14/testing for Punchi Dock and create a native package. By
default the script creates the public artifact without installing it.

Options:
  --yes               Pass --yes to apt-get and skip confirmations.
  --skip-apt          Do not run apt-get; only verify and build.
  --dependencies-only Install and verify dependencies without building.
  --local-test        Build, install, restart Plasma Shell, and collect logs.
  --skip-restart      With --local-test, install without restarting Plasma.
  --dry-run           Print planned commands without changing the system.
  -h, --help          Show this help.

Run this script as the desktop user, not with sudo. It will request sudo only
for apt-get.
EOF
}

log() {
    printf '==> %s\n' "$*"
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

run_command() {
    printf '$'
    printf ' %q' "$@"
    printf '\n'
    if (( DRY_RUN == 0 )); then
        "$@"
    fi
}

confirm() {
    local prompt="$1"
    local answer=""

    if (( ASSUME_YES == 1 || DRY_RUN == 1 )); then
        return 0
    fi

    printf '%s [y/N] ' "$prompt"
    read -r answer
    [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "YES" ]]
}

parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            --yes)
                ASSUME_YES=1
                ;;
            --skip-apt)
                SKIP_APT=1
                ;;
            --skip-restart)
                SKIP_RESTART=1
                ;;
            --dependencies-only)
                DEPENDENCIES_ONLY=1
                ;;
            --local-test)
                LOCAL_TEST=1
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                usage >&2
                die "unknown option: $1"
                ;;
        esac
        shift
    done

    if (( DEPENDENCIES_ONLY == 1 && LOCAL_TEST == 1 )); then
        die "--dependencies-only and --local-test cannot be used together"
    fi
    if (( SKIP_RESTART == 1 && LOCAL_TEST == 0 )); then
        die "--skip-restart requires --local-test"
    fi
}

load_os_release() {
    [[ -r /etc/os-release ]] || die "cannot read /etc/os-release"
    # shellcheck disable=SC1091
    source /etc/os-release
}

is_debian14_testing() {
    [[ "${ID:-}" == "debian" ]] || return 1
    [[ "${VERSION_ID:-}" == "14" ]] && return 0
    [[ "${VERSION_CODENAME:-}" == "forky" ]] && return 0
    [[ "${VERSION:-}" == *forky* ]] && return 0
    [[ "${PRETTY_NAME:-}" == *forky* ]] && return 0
    return 1
}

require_desktop_user() {
    if (( EUID == 0 )); then
        die "run this script as the Plasma desktop user, not with sudo"
    fi
}

install_dependencies() {
    local install_command=(sudo apt-get install)
    local missing_packages=()

    if (( SKIP_APT == 1 )); then
        log "Skipping APT dependency installation"
        return 0
    fi

    command -v dpkg-query >/dev/null 2>&1 || die "dpkg-query is required on Debian"
    mapfile -t missing_packages < <(missing_apt_packages)
    if (( ${#missing_packages[@]} == 0 )); then
        log "All Debian 14/testing build packages are already installed"
        return 0
    fi

    log "Missing APT packages: ${missing_packages[*]}"
    command -v sudo >/dev/null 2>&1 || die "sudo is required to install missing APT packages"
    command -v apt-get >/dev/null 2>&1 || die "apt-get is required on Debian"
    command -v apt-cache >/dev/null 2>&1 || die "apt-cache is required on Debian"

    if (( ASSUME_YES == 1 )); then
        install_command+=(--yes)
    fi
    install_command+=("${missing_packages[@]}")

    confirm "This will update APT metadata and install the missing Debian build dependencies. Continue?" \
        || die "dependency installation cancelled"

    run_command sudo apt-get update
    verify_packages_available "${missing_packages[@]}"
    run_command "${install_command[@]}"
}

missing_apt_packages() {
    local package_name=""

    for package_name in "${APT_PACKAGES[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null \
            | grep -qx 'install ok installed'; then
            printf '%s\n' "$package_name"
        fi
    done
}

verify_packages_available() {
    local missing=()
    local package_name=""

    if (( DRY_RUN == 1 )); then
        return 0
    fi

    for package_name in "$@"; do
        if ! apt-cache show --no-all-versions "$package_name" >/dev/null 2>&1; then
            missing+=("$package_name")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        printf 'Missing packages in the configured Debian repositories:\n' >&2
        printf '  - %s\n' "${missing[@]}" >&2
        die "enable the official Debian testing repositories, then run the script again"
    fi
}

verify_commands() {
    local missing=()
    local command_name=""

    if (( DRY_RUN == 1 )); then
        log "Dry run: command verification skipped"
        return 0
    fi

    for command_name in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            missing+=("$command_name")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        printf 'Required commands are still missing after dependency setup:\n' >&2
        printf '  - %s\n' "${missing[@]}" >&2
        die "install the missing Debian packages and retry"
    fi
}

package_version() {
    awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json"
}

restart_plasma_shell() {
    local previous_pid=""
    local current_pid=""

    if (( SKIP_RESTART == 1 )); then
        log "Skipping Plasma Shell restart"
        return 0
    fi

    confirm "This will restart Plasma Shell for the current desktop session. Continue?" \
        || die "Plasma Shell restart cancelled"

    previous_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
    log "Plasma Shell PID before restart: ${previous_pid:-not running}"

    if (( DRY_RUN == 1 )); then
        if command -v systemctl >/dev/null 2>&1 \
            && systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
            run_command systemctl --user restart plasma-plasmashell.service
        elif command -v kquitapp6 >/dev/null 2>&1; then
            run_command kquitapp6 plasmashell
            run_command kstart6 plasmashell
        else
            run_command killall plasmashell
            run_command plasmashell
        fi
        log "Dry run: Plasma Shell restart confirmation skipped"
        return 0
    fi

    if command -v systemctl >/dev/null 2>&1 \
        && systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
        log "Restart method: systemd user service"
        run_command systemctl --user restart plasma-plasmashell.service

        sleep 1
        current_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
        if [[ -n "$previous_pid" && "$current_pid" == "$previous_pid" ]]; then
            log "Systemd kept the existing process; requesting a KDE-controlled stop"
            if command -v kquitapp6 >/dev/null 2>&1; then
                kquitapp6 plasmashell >/dev/null 2>&1 || true
            else
                killall plasmashell >/dev/null 2>&1 || true
            fi

            sleep 0.5
            if kill -0 "$previous_pid" >/dev/null 2>&1; then
                kill "$previous_pid" >/dev/null 2>&1 || true
            fi

            for _stop_attempt in {1..20}; do
                if ! kill -0 "$previous_pid" >/dev/null 2>&1; then
                    break
                fi
                sleep 0.25
            done

            run_command systemctl --user restart plasma-plasmashell.service
        fi
    else
        log "Restart method: KDE application control"
        if command -v kquitapp6 >/dev/null 2>&1; then
            kquitapp6 plasmashell >/dev/null 2>&1 || true
        else
            killall plasmashell >/dev/null 2>&1 || true
        fi

        sleep 1

        if command -v kstart >/dev/null 2>&1; then
            run_command kstart plasmashell
        elif command -v kstart6 >/dev/null 2>&1; then
            run_command kstart6 plasmashell
        else
            printf '$ plasmashell &\n'
            plasmashell >/dev/null 2>&1 &
        fi
    fi

    for _attempt in {1..20}; do
        current_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
        if [[ -n "$current_pid" && "$current_pid" != "$previous_pid" ]]; then
            log "Plasma Shell PID after restart: $current_pid"
            return 0
        fi
        sleep 0.25
    done

    die "Plasma Shell PID did not change after the restart request"
}

install_package() {
    local zip_file="$1"
    local data_root=""
    local install_dir=""

    if (( DRY_RUN == 1 )); then
        run_command kpackagetool6 --type Plasma/Applet -u "$zip_file"
        return 0
    fi

    data_root="$(qtpaths6 --writable-path GenericDataLocation)"
    install_dir="$data_root/plasma/plasmoids/$PLUGIN_ID"

    log "Installing local Debian 14 testing package"
    if ! kpackagetool6 --type Plasma/Applet -u "$zip_file" 2>/dev/null; then
        run_command kpackagetool6 --type Plasma/Applet -i "$zip_file"
    fi

    [[ -f "$install_dir/metadata.json" ]] \
        || die "kpackagetool6 did not leave a valid installation in $install_dir"

    log "Installed package: $zip_file"
    log "Installation directory: $install_dir"
}

collect_diagnostics() {
    local debug_log="$PROJECT_ROOT/debug-debian14-testing.log"

    if (( DRY_RUN == 1 )); then
        return 0
    fi

    sleep 4
    journalctl --user --since "20 seconds ago" \
        | grep -iE "punchi|qml|typeerror|referenceerror|dockmodel" > "$debug_log" || true
    log "Startup diagnostics: $debug_log"
}

main() {
    local version=""
    local arch=""
    local label="debian14testing"
    local artifact_suffix=""
    local zip_file=""

    parse_args "$@"
    require_desktop_user
    load_os_release

    if ! is_debian14_testing; then
        die "this script is exclusive to Debian 14/testing (detected: ${PRETTY_NAME:-unknown})"
    fi

    log "Detected host: ${PRETTY_NAME:-Debian testing}"

    install_dependencies

    verify_commands
    run_command "$SCRIPTS_DIR/check-build-environment.sh"

    if (( DEPENDENCIES_ONLY == 1 )); then
        log "Debian 14/testing dependency setup completed"
        return 0
    fi

    version="$(package_version)"
    [[ -n "$version" ]] || die "cannot read package version from metadata.json"

    arch="$(uname -m)"
    if (( LOCAL_TEST == 1 )); then
        artifact_suffix="-local-test"
    fi
    zip_file="$PROJECT_ROOT/dist/punchi-dock-remastered-$version-$label-$arch$artifact_suffix.plasmoid"

    log "Building native Debian 14/testing package"
    PACKAGE_OUTPUT_FILE="$zip_file" run_command "$SCRIPT_DIR/debian14-testing-package.sh"

    [[ -f "$zip_file" || "$DRY_RUN" == "1" ]] || die "package was not created: $zip_file"

    if (( LOCAL_TEST == 1 )); then
        install_package "$zip_file"
        restart_plasma_shell
        collect_diagnostics
        log "Debian 14/testing local test setup completed"
    else
        log "Debian 14/testing public artifact ready: $zip_file"
    fi

    log "Debian 14/testing setup completed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
