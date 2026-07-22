#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"

# shellcheck source=../lib/qmllint-baseline.sh
source "$SCRIPTS_DIR/lib/qmllint-baseline.sh"

usage() {
    cat <<'EOF'
Usage: scripts/distro/debian14-testing-package.sh [options]

Build a native Punchi Dock .plasmoid package on Debian 14/testing (forky).

Options:
  --strict-baseline  Fail if the local Debian 14/testing qmllint baseline does
                     not exist, instead of recording it on the first run.
  -h, --help         Show this help.

This script does not install packages, request sudo, install the plasmoid, or
restart Plasma Shell. Use scripts/setup-debian14-testing.sh for the full local
setup/install/restart flow.
EOF
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

parse_args() {
    STRICT_BASELINE=0

    while (( $# > 0 )); do
        case "$1" in
            --strict-baseline)
                STRICT_BASELINE=1
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

resolve_qmllint_bin() {
    local candidate=""
    local candidates=(
        "${QMLLINT_BIN:-}"
        /usr/lib/qt6/bin/qmllint
        qmllint6
        qmllint
    )

    for candidate in "${candidates[@]}"; do
        [[ -n "$candidate" ]] || continue
        if [[ "$candidate" == */* ]]; then
            [[ -x "$candidate" ]] || continue
            printf '%s\n' "$candidate"
            return 0
        fi
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done

    die "Qt 6 qmllint was not found"
}

package_version() {
    awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json"
}

main() {
    local version=""
    local arch=""
    local label=""
    local cache_root=""
    local baseline_file=""
    local build_dir=""
    local zip_file=""
    local qmllint_bin=""

    parse_args "$@"
    load_os_release

    if ! is_debian14_testing; then
        die "this script is exclusive to Debian 14/testing (detected: ${PRETTY_NAME:-unknown})"
    fi

    require_command cmake
    require_command ctest
    require_command c++
    require_command msgattrib
    require_command msgfmt
    require_command readelf
    require_command strip
    require_command unzip
    require_command zip

    version="$(package_version)"
    [[ -n "$version" ]] || die "cannot read package version from metadata.json"

    arch="${PACKAGE_ARCH:-$(uname -m)}"
    label="debian14testing-$arch"
    cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/punchi-dock-remastered/$label"
    baseline_file="${QMLLINT_BASELINE_FILE:-$(punchi_qmllint_baseline_path "$cache_root" "$version")}"
    build_dir="${BUILD_DIR:-$cache_root/build}"
    zip_file="${PACKAGE_OUTPUT_FILE:-$PROJECT_ROOT/dist/punchi-dock-remastered-$version-$label.plasmoid}"
    qmllint_bin="$(resolve_qmllint_bin)"

    mkdir -p "$cache_root" "$PROJECT_ROOT/dist"

    if [[ ! -f "$baseline_file" ]]; then
        if (( STRICT_BASELINE == 1 )); then
            die "missing Debian 14/testing qmllint baseline: $baseline_file"
        fi
        printf '==> Recording first Debian 14/testing qmllint baseline: %s\n' "$baseline_file"
        export QMLLINT_RECORD_BASELINE=1
    else
        printf '==> Using Debian 14/testing qmllint baseline: %s\n' "$baseline_file"
    fi

    printf '==> Host: %s\n' "${PRETTY_NAME:-Debian testing}"
    printf '==> Build directory: %s\n' "$build_dir"
    printf '==> Output package: %s\n' "$zip_file"

    PUNCHI_PACKAGE_CORE=1 \
        QMLLINT_BASELINE_FILE="$baseline_file" \
        QMLLINT_BIN="$qmllint_bin" \
        BUILD_DIR="$build_dir" \
        PACKAGE_OUTPUT_FILE="$zip_file" \
        "$SCRIPTS_DIR/lib/package-plasmoid.sh"
}

main "$@"
