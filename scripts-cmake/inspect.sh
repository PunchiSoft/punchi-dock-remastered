#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${1:-$PROJECT_ROOT/build-cmake}"
STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/punchi-cmake-install.XXXXXX")"

cleanup() {
    if [[ -z "$STAGING_ROOT" || ! -d "$STAGING_ROOT" ]]; then
        return
    fi
    if [[ "$(basename "$STAGING_ROOT")" != punchi-cmake-install.* ]]; then
        echo "Refusing to remove an unexpected staging path: $STAGING_ROOT" >&2
        return
    fi
    rm -rf -- "$STAGING_ROOT"
}
trap cleanup EXIT

if [[ ! -f "$BUILD_DIR/cmake_install.cmake" ]]; then
    echo "Error: no configured CMake build was found at $BUILD_DIR." >&2
    echo "Run scripts-cmake/build.sh first." >&2
    exit 2
fi

DESTDIR="$STAGING_ROOT" cmake --install "$BUILD_DIR"

file_count="$(find "$STAGING_ROOT" -type f -printf '.' | wc -c)"
qml_file_count="$(find "$STAGING_ROOT" -type f -name '*.qml' -printf '.' | wc -c)"

echo "Standard CMake installation summary:"
echo "  Total files: $file_count"
echo "  Plasmoid QML files: $qml_file_count"
echo "  Plasma package:"
find "$STAGING_ROOT" -type f -path '*/plasma/plasmoids/*/metadata.json' -printf '    %P\n'
echo "  Native QML module:"
find "$STAGING_ROOT" -type f \
    \( -path '*/qml/org/punchi/dock/*' -o -path '*/contents/ui/org/punchi/dock/*' \) \
    -printf '    %P\n' | LC_ALL=C sort
echo "  Translation catalogs:"
find "$STAGING_ROOT" -type f -path '*/locale/*/LC_MESSAGES/*.mo' -printf '    %P\n' | LC_ALL=C sort
echo "Inspection used a temporary DESTDIR; the active system was not modified."
