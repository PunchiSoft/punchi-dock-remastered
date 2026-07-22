#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
ASSUME_YES=0
SKIP_DNF=0
DEPENDENCIES_ONLY=0
LOCAL_TEST=0
DRY_RUN=0

DNF_PACKAGES=(
    binutils
    cmake
    extra-cmake-modules
    gcc-c++
    gettext
    git
    kf6-kcoreaddons-devel
    kf6-ki18n-devel
    kf6-kio-devel
    kf6-kjobwidgets-devel
    kf6-kpackage
    kf6-kservice-devel
    libplasma-devel
    ninja-build
    pipewire-devel
    pkgconf-pkg-config
    qt6-qtbase-devel
    qt6-qtdeclarative-devel
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
Usage: scripts/setup-fedora.sh [options]

Prepare Fedora for Punchi Dock and create a native package. By default the
script creates the public artifact without installing it.

Options:
  --yes               Pass --assumeyes to DNF.
  --skip-dnf          Do not run DNF; only verify and build.
  --dependencies-only Install and verify dependencies without building.
  --local-test        Build, install, restart Plasma Shell, and collect logs.
  --dry-run           Print planned commands without changing the system.
  -h, --help          Show this help.

Run this script as the desktop user, not with sudo. It requests sudo only when
DNF must install missing packages.
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
            --skip-dnf)
                SKIP_DNF=1
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
    (( EUID != 0 )) || die "run this script as the Plasma desktop user, not with sudo"
    [[ "${ID:-}" == "fedora" ]] || die "this setup script requires Fedora (detected: ${ID:-unknown})"
    command -v rpm >/dev/null 2>&1 || die "rpm is required on Fedora"
}

missing_dnf_packages() {
    local package_name=""

    for package_name in "${DNF_PACKAGES[@]}"; do
        rpm -q "$package_name" >/dev/null 2>&1 || printf '%s\n' "$package_name"
    done
}

install_dependencies() {
    local missing_packages=()
    local install_command=(sudo dnf install)

    if (( SKIP_DNF == 1 )); then
        log "Skipping DNF dependency installation"
        return 0
    fi

    mapfile -t missing_packages < <(missing_dnf_packages)
    if (( ${#missing_packages[@]} == 0 )); then
        log "All Fedora build packages are already installed"
        return 0
    fi

    log "Missing DNF packages: ${missing_packages[*]}"
    command -v sudo >/dev/null 2>&1 || die "sudo is required to install missing DNF packages"
    command -v dnf >/dev/null 2>&1 || die "dnf is required on Fedora"
    (( ASSUME_YES == 0 )) || install_command+=(--assumeyes)
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
        printf 'Required commands are missing:\n' >&2
        printf '  - %s\n' "${missing[@]}" >&2
        die "install the missing Fedora packages and retry"
    fi

    run_command "$SCRIPTS_DIR/check-build-environment.sh"
}

build_plasmoid() {
    local package_version=""
    local platform_label=""
    local artifact_suffix=""
    local artifact_file=""
    local build_command="$SCRIPT_DIR/fedora-package.sh"

    package_version="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")"
    [[ -n "$package_version" ]] || die "the package version could not be read from metadata.json"

    platform_label="fedora${VERSION_ID:-unknown}-$(uname -m)"
    if (( LOCAL_TEST == 1 )); then
        artifact_suffix="-local-test"
        build_command="$SCRIPTS_DIR/lib/install-local-test.sh"
    fi
    artifact_file="$PROJECT_ROOT/dist/punchi-dock-remastered-${package_version}-${platform_label}${artifact_suffix}.plasmoid"

    run_command "$build_command"
    (( DRY_RUN == 1 )) || [[ -f "$artifact_file" ]] \
        || die "the build finished without creating the expected artifact: $artifact_file"
    log "Fedora artifact ready: $artifact_file"
}

main() {
    parse_args "$@"
    load_os_release
    validate_host

    log "Detected host: ${PRETTY_NAME:-Fedora}"
    install_dependencies
    verify_commands

    if (( DEPENDENCIES_ONLY == 0 )); then
        build_plasmoid
    fi

    log "Fedora setup completed"
}

main "$@"
