#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
PUBLIC_SCRIPTS_DIR="$PROJECT_ROOT/scripts-user"

if [[ ! -r /etc/os-release ]]; then
    echo "Error: the distribution could not be identified from /etc/os-release." >&2
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

is_arch_family=0
case "${ID:-}" in
    arch|manjaro|endeavouros|garuda|artix)
        is_arch_family=1
        ;;
esac
if [[ " ${ID_LIKE:-} " == *' arch '* ]]; then
    is_arch_family=1
fi

if (( is_arch_family == 0 )) && [[ "${ALLOW_UNSUPPORTED_BUILD_HOST:-0}" != "1" ]]; then
    echo "Error: this wrapper must run on Arch Linux or an Arch-family distribution (detected host: ${ID:-unknown})." >&2
    echo "Use ALLOW_UNSUPPORTED_BUILD_HOST=1 only to validate the script, not to publish." >&2
    exit 1
fi

package_version="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")"
if [[ -z "$package_version" ]]; then
    echo "Error: the package version could not be read from metadata.json." >&2
    exit 1
fi

platform_release="${ID:-arch}${VERSION_ID:+${VERSION_ID}}"
platform_release="${platform_release//[^a-zA-Z0-9._-]/_}"
package_arch="${PACKAGE_ARCH:-$(uname -m)}"
package_arch="${package_arch//[^a-zA-Z0-9._-]/_}"
platform_label="${platform_release}-${package_arch}"

export BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build/$platform_label}"
export PACKAGE_OUTPUT_FILE="${PACKAGE_OUTPUT_FILE:-$PROJECT_ROOT/dist/punchi-dock-remastered-${package_version}-${platform_label}.plasmoid}"
export QMLLINT_BASELINE_FILE="${QMLLINT_BASELINE_FILE:-$SCRIPTS_DIR/qmllint-baseline-arch.env}"
export QMLLINT_BIN="${QMLLINT_BIN:-/usr/lib/qt6/bin/qmllint}"
export PUNCHI_PACKAGE_CORE=1

if [[ ! -f "$QMLLINT_BASELINE_FILE" ]]; then
    echo "Error: the strict Arch qmllint baseline is missing: $QMLLINT_BASELINE_FILE" >&2
    echo "The Fedora and Debian baselines are not reused because Qt diagnostics can differ." >&2
    exit 1
fi

export PUNCHI_PACKAGE_VALIDATION_MODE=full
exec "$PUBLIC_SCRIPTS_DIR/lib/package-plasmoid.sh"
