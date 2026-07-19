#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/plasma-version.sh
source "$SCRIPT_DIR/lib/plasma-version.sh"

if [[ ! -r /etc/os-release ]]; then
    echo "Error: the distribution could not be identified from /etc/os-release." >&2
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "ubuntu" && "${ALLOW_UNSUPPORTED_BUILD_HOST:-0}" != "1" ]]; then
    echo "Error: this wrapper must run on Kubuntu or Ubuntu with Plasma (detected: ${ID:-unknown})." >&2
    echo "The native module must be compiled on Kubuntu to test that artifact." >&2
    exit 1
fi

if ! command -v plasmashell >/dev/null 2>&1; then
    echo "Error: plasmashell was not found. This profile requires a Kubuntu Plasma session." >&2
    exit 1
fi

plasma_version_output="$(plasmashell --version 2>&1 || true)"
plasma_version="$(punchi_extract_plasma_version "$plasma_version_output")"
if [[ ! "$plasma_version" =~ ^6\. ]]; then
    echo "Error: Punchi Dock requires Plasma 6 (version output: ${plasma_version_output:-empty})." >&2
    exit 1
fi

package_version="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")"
if [[ -z "$package_version" ]]; then
    echo "Error: the package version could not be read from metadata.json." >&2
    exit 1
fi

platform_version="${VERSION_ID:-unknown}"
package_arch="${PACKAGE_ARCH:-$(uname -m)}"
safe_plasma_version="${plasma_version//[^[:alnum:]._-]/_}"
platform_label="kubuntu${platform_version}-plasma${safe_plasma_version}-${package_arch}"
default_build_root="${XDG_CACHE_HOME:-$HOME/.cache}/punchi-dock-remastered"
default_baseline_file="$default_build_root/$platform_label/qmllint-baseline.env"

export BUILD_DIR="${BUILD_DIR:-$default_build_root/$platform_label}"
export PACKAGE_OUTPUT_FILE="${PACKAGE_OUTPUT_FILE:-$PROJECT_ROOT/dist/punchi-dock-remastered-${package_version}-${platform_label}.plasmoid}"
export QMLLINT_BASELINE_FILE="${QMLLINT_BASELINE_FILE:-$default_baseline_file}"
export QMLLINT_BIN="${QMLLINT_BIN:-/usr/lib/qt6/bin/qmllint}"
export PUNCHI_PACKAGE_CORE=1

if [[ ! -f "$QMLLINT_BASELINE_FILE" && "${QMLLINT_RECORD_BASELINE:-0}" != "1" ]]; then
    if [[ "${PUNCHI_LOCAL_TEST:-0}" == "1" ]]; then
        echo "No Kubuntu qmllint baseline exists for this host; recording the first local baseline."
        echo "Baseline file: $QMLLINT_BASELINE_FILE"
        export QMLLINT_RECORD_BASELINE=1
    else
        echo "Error: no qmllint baseline exists for this Kubuntu profile: $QMLLINT_BASELINE_FILE" >&2
        echo "Calibrate it locally before creating a distributable artifact:" >&2
        echo "  QMLLINT_RECORD_BASELINE=1 scripts/build-kubuntu-package.sh" >&2
        exit 1
    fi
fi

exec "$SCRIPT_DIR/empaquetar-plasmoid.sh"
