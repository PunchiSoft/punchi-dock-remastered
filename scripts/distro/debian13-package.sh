#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"

if [[ ! -r /etc/os-release ]]; then
    echo "Error: the distribution could not be identified from /etc/os-release." >&2
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

is_debian13=0
if [[ "${ID:-}" == "debian" ]] \
    && { [[ "${VERSION_ID:-}" == "13" ]] || [[ "${VERSION_CODENAME:-}" == "trixie" ]]; }; then
    is_debian13=1
fi

if (( is_debian13 == 0 )) && [[ "${ALLOW_UNSUPPORTED_BUILD_HOST:-0}" != "1" ]]; then
    echo "Error: this package profile requires Debian 13/trixie (detected: ${PRETTY_NAME:-unknown})." >&2
    echo "Use scripts/setup-debian14-testing.sh on Debian 14/testing." >&2
    exit 1
fi

package_version="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")"
if [[ -z "$package_version" ]]; then
    echo "Error: the package version could not be read from metadata.json." >&2
    exit 1
fi

platform_version="${VERSION_ID:-unknown}"
package_arch="${PACKAGE_ARCH:-$(uname -m)}"
platform_label="debian${platform_version}-${package_arch}"
default_build_root="${XDG_CACHE_HOME:-$HOME/.cache}/punchi-dock-remastered"

export BUILD_DIR="${BUILD_DIR:-$default_build_root/$platform_label}"
export PACKAGE_OUTPUT_FILE="${PACKAGE_OUTPUT_FILE:-$PROJECT_ROOT/dist/punchi-dock-remastered-${package_version}-${platform_label}.plasmoid}"
export QMLLINT_BASELINE_FILE="${QMLLINT_BASELINE_FILE:-$SCRIPTS_DIR/qmllint-baseline-debian.env}"
export QMLLINT_BIN="${QMLLINT_BIN:-/usr/lib/qt6/bin/qmllint}"
export PUNCHI_PACKAGE_CORE=1

if [[ ! -f "$QMLLINT_BASELINE_FILE" && "${QMLLINT_RECORD_BASELINE:-0}" != "1" ]]; then
    echo "Error: the Debian 13 qmllint baseline is missing: $QMLLINT_BASELINE_FILE" >&2
    echo "The Fedora baseline is not reused because Qt diagnostics can differ." >&2
    echo "First calibration: QMLLINT_RECORD_BASELINE=1 scripts/setup-debian13.sh" >&2
    exit 1
fi

exec "$SCRIPTS_DIR/lib/package-plasmoid.sh"
