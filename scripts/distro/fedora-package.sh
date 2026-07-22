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

if [[ "${ID:-}" != "fedora" && "${ALLOW_UNSUPPORTED_BUILD_HOST:-0}" != "1" ]]; then
    echo "Error: this wrapper must run on Fedora (detected host: ${ID:-unknown})." >&2
    echo "Use ALLOW_UNSUPPORTED_BUILD_HOST=1 only to validate the script, not to publish." >&2
    exit 1
fi

package_version="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")"
if [[ -z "$package_version" ]]; then
    echo "Error: the package version could not be read from metadata.json." >&2
    exit 1
fi

platform_version="${VERSION_ID:-unknown}"
package_arch="${PACKAGE_ARCH:-$(uname -m)}"
platform_label="fedora${platform_version}-${package_arch}"

export BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build/$platform_label}"
export PACKAGE_OUTPUT_FILE="${PACKAGE_OUTPUT_FILE:-$PROJECT_ROOT/dist/punchi-dock-remastered-${package_version}-${platform_label}.plasmoid}"
export QMLLINT_BASELINE_FILE="${QMLLINT_BASELINE_FILE:-$SCRIPTS_DIR/qmllint-baseline-fedora.env}"
export QMLLINT_BIN="${QMLLINT_BIN:-/usr/lib64/qt6/bin/qmllint}"
export PUNCHI_PACKAGE_CORE=1

exec "$SCRIPTS_DIR/lib/package-plasmoid.sh"
