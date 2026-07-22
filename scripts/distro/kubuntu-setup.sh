#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
ASSUME_YES=0
SKIP_UPDATE=0
SKIP_APT=0
DEPENDENCIES_ONLY=0
LOCAL_TEST=0
DRY_RUN=0

# shellcheck source=../lib/plasma-version.sh
source "$SCRIPTS_DIR/lib/plasma-version.sh"

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
Usage: scripts/setup-kubuntu.sh [options]

Prepare a clean Kubuntu Plasma 6 host, install the official build
dependencies, and build Punchi Dock natively.

Options:
  --yes               Pass --yes to apt-get.
  --skip-update       Skip apt-get update when package metadata is current.
  --skip-apt          Do not run apt-get; only verify and build.
  --dependencies-only Install and verify dependencies without building.
  --local-test        Build, install, restart Plasma Shell, and collect logs.
  --dry-run           Print planned commands without changing the system.
  -h, --help          Show this help.

Run this script as the desktop user, not with sudo. It requests sudo only for
apt-get.
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

parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            --yes)
                ASSUME_YES=1
                ;;
            --skip-update)
                SKIP_UPDATE=1
                ;;
            --skip-apt)
                SKIP_APT=1
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
}

load_os_release() {
    [[ -r /etc/os-release ]] || die "cannot read /etc/os-release"
    # shellcheck disable=SC1091
    source /etc/os-release
}

validate_host() {
    local plasma_version_output=""

    (( EUID != 0 )) || die "run this script as the Plasma desktop user, not with sudo"
    [[ "${ID:-}" == "ubuntu" ]] \
        || die "this setup script requires Kubuntu or Ubuntu with Plasma (detected: ${ID:-unknown})"
    command -v apt-get >/dev/null 2>&1 || die "apt-get is required on the Kubuntu host"
    command -v apt-cache >/dev/null 2>&1 || die "apt-cache is required on the Kubuntu host"
    command -v dpkg-query >/dev/null 2>&1 || die "dpkg-query is required on the Kubuntu host"
    command -v plasmashell >/dev/null 2>&1 || die "plasmashell was not found"

    plasma_version_output="$(plasmashell --version 2>&1 || true)"
    PLASMA_VERSION="$(punchi_extract_plasma_version "$plasma_version_output")"
    [[ "$PLASMA_VERSION" =~ ^6\. ]] \
        || die "Punchi Dock requires Plasma 6 (version output: ${plasma_version_output:-empty})"
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

    (( DRY_RUN == 0 )) || return 0

    for package_name in "$@"; do
        if ! apt-cache show --no-all-versions "$package_name" >/dev/null 2>&1; then
            missing+=("$package_name")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        printf 'Packages unavailable in the configured APT repositories:\n' >&2
        printf '  - %s\n' "${missing[@]}" >&2
        die "enable the official Ubuntu Universe repository, refresh APT, and retry"
    fi
}

install_dependencies() {
    local install_command=(sudo apt-get install)
    local missing_packages=()

    if (( SKIP_APT == 1 )); then
        log "Skipping APT dependency installation"
        return 0
    fi

    mapfile -t missing_packages < <(missing_apt_packages)
    if (( ${#missing_packages[@]} == 0 )); then
        log "All Kubuntu build packages are already installed"
        return 0
    fi

    log "Missing APT packages: ${missing_packages[*]}"
    command -v sudo >/dev/null 2>&1 || die "sudo is required to install missing APT packages"

    if (( SKIP_UPDATE == 0 )); then
        run_command sudo apt-get update
    fi

    verify_packages_available "${missing_packages[@]}"

    (( ASSUME_YES == 0 )) || install_command+=(--yes)
    install_command+=("${missing_packages[@]}")
    run_command "${install_command[@]}"
}

verify_commands() {
    local missing=()
    local command_name=""

    if (( DRY_RUN == 1 )); then
        log "Dry run: post-install command verification skipped"
        return 0
    fi

    for command_name in "${REQUIRED_COMMANDS[@]}"; do
        command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
    done

    if (( ${#missing[@]} > 0 )); then
        printf 'Required commands are still missing after dependency setup:\n' >&2
        printf '  - %s\n' "${missing[@]}" >&2
        die "install the missing Kubuntu packages and retry"
    fi

    run_command "$SCRIPTS_DIR/check-build-environment.sh"
}

build_plasmoid() {
    local package_version=""
    local package_arch=""
    local safe_plasma_version=""
    local platform_label=""
    local cache_root=""
    local baseline_file=""
    local artifact_suffix=""
    local artifact_file=""
    local build_command=""

    package_version="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")"
    [[ -n "$package_version" ]] || die "the package version could not be read from metadata.json"

    package_arch="$(uname -m)"
    safe_plasma_version="${PLASMA_VERSION//[^[:alnum:]._-]/_}"
    platform_label="kubuntu${VERSION_ID:-unknown}-plasma${safe_plasma_version}-${package_arch}"
    cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/punchi-dock-remastered"
    baseline_file="$cache_root/$platform_label/qmllint-baseline.env"

    if (( LOCAL_TEST == 1 )); then
        artifact_suffix="-local-test"
        build_command="$SCRIPTS_DIR/lib/install-local-test.sh"
    else
        build_command="$SCRIPT_DIR/kubuntu-package.sh"
    fi
    artifact_file="$PROJECT_ROOT/dist/punchi-dock-remastered-${package_version}-${platform_label}${artifact_suffix}.plasmoid"

    if [[ ! -f "$baseline_file" ]]; then
        log "Recording the first Kubuntu qmllint baseline: $baseline_file"
        export QMLLINT_RECORD_BASELINE=1
    fi

    run_command "$build_command"
    (( DRY_RUN == 1 )) || [[ -f "$artifact_file" ]] \
        || die "the build finished without creating the expected artifact: $artifact_file"
    log "Kubuntu artifact ready: $artifact_file"
}

main() {
    parse_args "$@"
    load_os_release
    validate_host

    log "Detected host: ${PRETTY_NAME:-Kubuntu}, Plasma $PLASMA_VERSION"
    log "Required APT packages: ${APT_PACKAGES[*]}"
    install_dependencies
    verify_commands

    if (( DEPENDENCIES_ONLY == 0 )); then
        build_plasmoid
    fi

    log "Kubuntu build environment preparation completed"
}

main "$@"
