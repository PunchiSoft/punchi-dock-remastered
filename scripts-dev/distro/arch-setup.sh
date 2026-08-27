#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
ASSUME_YES=0
SKIP_PACMAN=0
DEPENDENCIES_ONLY=0
LOCAL_TEST=0
DRY_RUN=0

# Arch packages include development files in the main package rather than in
# separate -devel packages. Keep this list limited to official repositories.
PACMAN_PACKAGES=(
    base-devel
    binutils
    cmake
    extra-cmake-modules
    gettext
    git
    kconfig
    kcoreaddons
    kglobalaccel
    ki18n
    kio
    kjobwidgets
    kpackage
    kservice
    kwindowsystem
    libpipewire
    libplasma
    ninja
    pkgconf
    plasma-workspace
    qt6-base
    qt6-declarative
    qt6-shadertools
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
    readelf
    strip
    unzip
    zip
)

# shellcheck source=../../scripts-user/lib/setup-localization.sh
source "$PROJECT_ROOT/scripts-user/lib/setup-localization.sh"
# shellcheck source=../../scripts-user/lib/qtpaths-resolver.sh
source "$PROJECT_ROOT/scripts-user/lib/qtpaths-resolver.sh"

usage() {
    punchi_gettext_line 'Usage: scripts-dev/distro/arch-setup.sh [options]

Prepare Arch Linux or a supported Arch-family distribution for Punchi Dock and
create a native package. By default the script creates the artifact without
installing it.

Options:
  --yes               Pass --noconfirm to pacman.
  --skip-pacman       Do not run pacman; only verify and build.
  --dependencies-only Install and verify dependencies without building.
  --local-test        Build, install, restart Plasma Shell, and collect logs.
  --dry-run           Print planned commands without changing the system.
  -h, --help          Show this help.

Run this script as the desktop user, not with sudo. It requests sudo only when
pacman must install missing packages. Package installation performs a complete
system upgrade because partial upgrades are unsupported on Arch Linux.'
}

log_line() {
    printf '==> '
    punchi_gettext_line "$1"
}

log_format() {
    printf '==> '
    punchi_gettext_format "$@"
}

die_line() {
    printf '%s' "$(punchi_gettext 'Error: ')" >&2
    punchi_gettext_line "$1" >&2
    exit 1
}

die_format() {
    printf '%s' "$(punchi_gettext 'Error: ')" >&2
    punchi_gettext_format "$@" >&2
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

parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            --yes)
                ASSUME_YES=1
                ;;
            --skip-pacman)
                SKIP_PACMAN=1
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
                die_format 'unknown option: %s\n' "$1"
                ;;
        esac
        shift
    done

    if (( DEPENDENCIES_ONLY == 1 && LOCAL_TEST == 1 )); then
        die_line '--dependencies-only and --local-test cannot be used together'
    fi
}

load_os_release() {
    [[ -r /etc/os-release ]] || die_line 'cannot read /etc/os-release'
    # shellcheck disable=SC1091
    source /etc/os-release
}

is_arch_family() {
    case "${ID:-}" in
        arch|manjaro|endeavouros|garuda|artix)
            return 0
            ;;
    esac

    [[ " ${ID_LIKE:-} " == *' arch '* ]]
}

validate_host() {
    (( EUID != 0 )) || die_line 'run this script as the Plasma desktop user, not with sudo'
    is_arch_family || die_format 'this setup script requires Arch Linux or an Arch-family distribution (detected: %s)\n' "${ID:-unknown}"
    command -v pacman >/dev/null 2>&1 || die_line 'pacman is required on Arch-family distributions'
}

missing_pacman_packages() {
    local package_name=""

    for package_name in "${PACMAN_PACKAGES[@]}"; do
        pacman -Qq "$package_name" >/dev/null 2>&1 || printf '%s\n' "$package_name"
    done
}

install_dependencies() {
    local missing_packages=()
    local install_command=(sudo pacman -Syu --needed)

    if (( SKIP_PACMAN == 1 )); then
        log_line 'Skipping pacman dependency installation'
        return 0
    fi

    mapfile -t missing_packages < <(missing_pacman_packages)
    if (( ${#missing_packages[@]} == 0 )); then
        log_line 'All Arch build packages are already installed'
        return 0
    fi

    log_format 'Missing pacman packages: %s\n' "${missing_packages[*]}"
    command -v sudo >/dev/null 2>&1 || die_line 'sudo is required to install missing pacman packages'
    command -v pacman >/dev/null 2>&1 || die_line 'pacman is required on Arch-family distributions'
    (( ASSUME_YES == 0 )) || install_command+=(--noconfirm)
    install_command+=("${missing_packages[@]}")
    run_command "${install_command[@]}"
}

verify_commands() {
    local missing=()
    local command_name=""

    if (( DRY_RUN == 1 )); then
        log_line 'Dry run: post-install command verification skipped'
        return 0
    fi

    for command_name in "${REQUIRED_COMMANDS[@]}"; do
        command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
    done
    punchi_find_qtpaths6 >/dev/null 2>&1 || missing+=(qtpaths6)

    if (( ${#missing[@]} > 0 )); then
        punchi_gettext_line 'Required commands are missing:' >&2
        printf '  - %s\n' "${missing[@]}" >&2
        die_line 'install the missing Arch packages and retry'
    fi

    run_command "$SCRIPTS_DIR/check-build-environment.sh"
}

arch_platform_label() {
    local platform_release="${ID:-arch}${VERSION_ID:+${VERSION_ID}}"
    platform_release="${platform_release//[^a-zA-Z0-9._-]/_}"
    printf '%s-%s\n' "$platform_release" "$(uname -m)"
}

build_plasmoid() {
    local package_version=""
    local platform_label=""
    local artifact_suffix=""
    local artifact_file=""
    local build_command="$SCRIPT_DIR/arch-package.sh"

    package_version="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")"
    [[ -n "$package_version" ]] || die_line 'the package version could not be read from metadata.json'

    platform_label="$(arch_platform_label)"
    if (( LOCAL_TEST == 1 )); then
        artifact_suffix="-local-test"
        build_command="$SCRIPTS_DIR/lib/install-local-test.sh"
    fi
    artifact_file="$PROJECT_ROOT/dist/punchi-dock-remastered-${package_version}-${platform_label}${artifact_suffix}.plasmoid"

    export PLATFORM_LABEL="$platform_label"
    run_command "$build_command"
    (( DRY_RUN == 1 )) || [[ -f "$artifact_file" ]] \
        || die_format 'the build finished without creating the expected artifact: %s\n' "$artifact_file"
    log_format 'Arch artifact ready: %s\n' "$artifact_file"
}

main() {
    punchi_prepare_setup_localization "$PROJECT_ROOT"
    parse_args "$@"
    load_os_release
    validate_host

    log_format 'Detected host: %s\n' "${PRETTY_NAME:-Arch Linux}"
    install_dependencies
    verify_commands

    if (( DEPENDENCIES_ONLY == 0 )); then
        build_plasmoid
    fi

    log_line 'Arch setup completed'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
