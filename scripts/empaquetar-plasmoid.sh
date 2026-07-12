#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build}"
PACKAGE_ROOT="$BUILD_DIR/package-root"
DIST_DIR="$PROJECT_ROOT/dist"
ZIP_FILE="$DIST_DIR/punchi-dock-remastered.plasmoid"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Required command not found: $1" >&2
        exit 1
    fi
}

require_command cmake
require_command qmllint
require_command unzip
require_command zip

echo "==> [1/4] Validating QML"
find "$PROJECT_ROOT/contents/ui" -name "*.qml" -exec qmllint {} +

echo "==> [2/4] Building the native QML module"
cmake -S "$PROJECT_ROOT" -B "$BUILD_DIR"
cmake --build "$BUILD_DIR" --parallel

echo "==> [3/4] Assembling a clean package tree"
cmake -E rm -rf "$PACKAGE_ROOT"
cmake -E make_directory "$PACKAGE_ROOT"
cmake -E copy "$PROJECT_ROOT/metadata.json" "$PACKAGE_ROOT/metadata.json"
cmake -E copy "$PROJECT_ROOT/LICENSE" "$PACKAGE_ROOT/LICENSE"
cmake -E copy_directory "$PROJECT_ROOT/contents" "$PACKAGE_ROOT/contents"
cmake --build "$BUILD_DIR" --target stage_plasmoid_module

for required_file in \
    "$PACKAGE_ROOT/contents/ui/org/punchi/dock/libpunchidockintegration.so" \
    "$PACKAGE_ROOT/contents/ui/org/punchi/dock/libpunchidockintegrationplugin.so" \
    "$PACKAGE_ROOT/contents/ui/org/punchi/dock/qmldir" \
    "$PACKAGE_ROOT/contents/ui/org/punchi/dock/punchidockintegration.qmltypes"; do
    if [[ ! -f "$required_file" ]]; then
        echo "Required package file was not staged: $required_file" >&2
        exit 1
    fi
done

echo "==> [4/4] Creating and validating the plasmoid"
mkdir -p "$DIST_DIR"
rm -f "$ZIP_FILE"
(
    cd "$PACKAGE_ROOT"
    zip -rq "$ZIP_FILE" metadata.json LICENSE contents
)
unzip -tq "$ZIP_FILE" >/dev/null

if unzip -Z1 "$ZIP_FILE" | grep -Eq '^(build|dist|backup|docs|bitacora|kde-sdk|scripts|src|\.agents|\.git)/|(^|/)(debug\.log|.*\.py|.*\.sh|.*\.plasmoid)$'; then
    echo "Development files were found in the plasmoid" >&2
    exit 1
fi

echo "Package created: $ZIP_FILE"
