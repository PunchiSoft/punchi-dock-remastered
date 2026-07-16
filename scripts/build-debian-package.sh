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

if [[ "${ID:-}" != "debian" && "${ALLOW_UNSUPPORTED_BUILD_HOST:-0}" != "1" ]]; then
    echo "Error: este wrapper debe ejecutarse en Debian (host detectado: ${ID:-desconocido})." >&2
    echo "El binario nativo debe compilarse en Debian para publicar ese artefacto." >&2
    exit 1
fi

package_version="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")"
if [[ -z "$package_version" ]]; then
    echo "Error: no se pudo leer la versión desde metadata.json." >&2
    exit 1
fi

platform_version="${VERSION_ID:-unknown}"
package_arch="${PACKAGE_ARCH:-$(uname -m)}"
platform_label="debian${platform_version}-${package_arch}"
default_build_root="${XDG_CACHE_HOME:-$HOME/.cache}/punchi-dock-remastered"

export BUILD_DIR="${BUILD_DIR:-$default_build_root/$platform_label}"
export PACKAGE_OUTPUT_FILE="${PACKAGE_OUTPUT_FILE:-$PROJECT_ROOT/dist/punchi-dock-remastered-${package_version}-${platform_label}.plasmoid}"
export QMLLINT_BASELINE_FILE="${QMLLINT_BASELINE_FILE:-$SCRIPT_DIR/qmllint-baseline-debian.env}"
export QMLLINT_BIN="${QMLLINT_BIN:-/usr/lib/qt6/bin/qmllint}"
export PUNCHI_PACKAGE_CORE=1

if [[ ! -f "$QMLLINT_BASELINE_FILE" && "${QMLLINT_RECORD_BASELINE:-0}" != "1" ]]; then
    echo "Error: falta calibrar el baseline de qmllint para Debian: $QMLLINT_BASELINE_FILE" >&2
    echo "No se reutiliza el baseline de Fedora porque Qt puede emitir diagnósticos distintos." >&2
    echo "Primera calibración: QMLLINT_RECORD_BASELINE=1 scripts/build-debian-package.sh" >&2
    exit 1
fi

exec "$SCRIPT_DIR/empaquetar-plasmoid.sh"
