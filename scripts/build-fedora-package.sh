#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -r /etc/os-release ]]; then
    echo "Error: no se pudo identificar la distribución desde /etc/os-release." >&2
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "fedora" && "${ALLOW_UNSUPPORTED_BUILD_HOST:-0}" != "1" ]]; then
    echo "Error: este wrapper debe ejecutarse en Fedora (host detectado: ${ID:-desconocido})." >&2
    echo "Usa ALLOW_UNSUPPORTED_BUILD_HOST=1 solo para validar el script, no para publicar." >&2
    exit 1
fi

package_version="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")"
if [[ -z "$package_version" ]]; then
    echo "Error: no se pudo leer la versión desde metadata.json." >&2
    exit 1
fi

platform_version="${VERSION_ID:-unknown}"
package_arch="${PACKAGE_ARCH:-$(uname -m)}"
platform_label="fedora${platform_version}-${package_arch}"

export BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build/$platform_label}"
export PACKAGE_OUTPUT_FILE="${PACKAGE_OUTPUT_FILE:-$PROJECT_ROOT/dist/punchi-dock-remastered-${package_version}-${platform_label}.plasmoid}"
export QMLLINT_BASELINE_FILE="${QMLLINT_BASELINE_FILE:-$SCRIPT_DIR/qmllint-baseline-fedora.env}"
export QMLLINT_BIN="${QMLLINT_BIN:-/usr/lib64/qt6/bin/qmllint}"
export PUNCHI_PACKAGE_CORE=1

exec "$SCRIPT_DIR/empaquetar-plasmoid.sh"
