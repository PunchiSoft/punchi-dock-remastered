#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build}"
PACKAGE_ROOT="$BUILD_DIR/package-root"
DIST_DIR="$PROJECT_ROOT/dist"
ZIP_FILE="$DIST_DIR/punchi-dock-remastered.plasmoid"
QMLLINT_BASELINE_FILE="${QMLLINT_BASELINE_FILE:-$PROJECT_ROOT/scripts/qmllint-baseline.env}"
PACKAGE_BUILD_TYPE="${PACKAGE_BUILD_TYPE:-Release}"
STRIP_BIN="${STRIP_BIN:-strip}"

resolve_qmllint() {
    local candidate=""
    local version=""
    local candidates=()

    if [[ -n "${QMLLINT_BIN:-}" ]]; then
        candidates+=("$QMLLINT_BIN")
    fi

    candidates+=(
        "/usr/lib64/qt6/bin/qmllint"
        "qmllint6"
        "qmllint"
    )

    for candidate in "${candidates[@]}"; do
        if [[ "$candidate" == */* ]]; then
            [[ -x "$candidate" ]] || continue
        elif ! command -v "$candidate" >/dev/null 2>&1; then
            continue
        else
            candidate="$(command -v "$candidate")"
        fi

        version="$("$candidate" --version 2>/dev/null || true)"
        if [[ "$version" =~ ^qmllint[[:space:]]+6(\.|$) ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    echo "A Qt 6 qmllint executable is required. Set QMLLINT_BIN or install /usr/lib64/qt6/bin/qmllint." >&2
    exit 1
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Required command not found: $1" >&2
        exit 1
    fi
}

require_command cmake
require_command ctest
require_command readelf
require_command "$STRIP_BIN"
require_command unzip
require_command zip

QMLLINT_BIN="$(resolve_qmllint)"
QMLLINT_VERSION="$("$QMLLINT_BIN" --version 2>/dev/null || true)"
QMLLINT_LOG="$BUILD_DIR/qmllint.log"

QMLLINT_BASELINE_TOTAL=0
QMLLINT_BASELINE_UNQUALIFIED=0
QMLLINT_BASELINE_LAYOUT=0
QMLLINT_BASELINE_MISSING_PROPERTY=0
QMLLINT_BASELINE_IMPORT=0
if [[ -f "$QMLLINT_BASELINE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$QMLLINT_BASELINE_FILE"
fi

echo "==> [1/4] Validating QML"
echo "Using: $QMLLINT_BIN ($QMLLINT_VERSION)"
mkdir -p "$BUILD_DIR"
mapfile -d '' qml_files < <(find "$PROJECT_ROOT/contents/ui" -name "*.qml" -print0 | sort -z)
if ! "$QMLLINT_BIN" "${qml_files[@]}" >"$QMLLINT_LOG" 2>&1; then
    cat "$QMLLINT_LOG" >&2
    exit 1
fi

warning_total="$(grep -c '^Warning:' "$QMLLINT_LOG" || true)"
warning_unqualified="$(grep '^Warning:' "$QMLLINT_LOG" | grep -c '\[unqualified\]' || true)"
warning_layout="$(grep '^Warning:' "$QMLLINT_LOG" | grep -c '\[Quick.layout-positioning\]' || true)"
warning_missing_property="$(grep '^Warning:' "$QMLLINT_LOG" | grep -c '\[missing-property\]' || true)"
warning_import="$(grep '^Warning:' "$QMLLINT_LOG" | grep -c '\[import\]' || true)"

echo "qmllint warnings: total=$warning_total, unqualified=$warning_unqualified, layout=$warning_layout, missing-property=$warning_missing_property, import=$warning_import"
echo "qmllint log: $QMLLINT_LOG"

if (( warning_total > QMLLINT_BASELINE_TOTAL \
    || warning_unqualified > QMLLINT_BASELINE_UNQUALIFIED \
    || warning_layout > QMLLINT_BASELINE_LAYOUT \
    || warning_missing_property > QMLLINT_BASELINE_MISSING_PROPERTY \
    || warning_import > QMLLINT_BASELINE_IMPORT )); then
    echo "qmllint warnings exceed the recorded baseline in $QMLLINT_BASELINE_FILE" >&2
    exit 1
fi

echo "==> [2/4] Building and testing the native QML module"
echo "Build type: $PACKAGE_BUILD_TYPE"
cmake -S "$PROJECT_ROOT" -B "$BUILD_DIR" \
    -DBUILD_TESTING=ON \
    -DCMAKE_BUILD_TYPE="$PACKAGE_BUILD_TYPE"
cmake --build "$BUILD_DIR" --parallel
ctest --test-dir "$BUILD_DIR" --output-on-failure

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

native_libraries=(
    "$PACKAGE_ROOT/contents/ui/org/punchi/dock/libpunchidockintegration.so"
    "$PACKAGE_ROOT/contents/ui/org/punchi/dock/libpunchidockintegrationplugin.so"
)

echo "Stripping development symbols from the staged native module"
"$STRIP_BIN" --strip-unneeded "${native_libraries[@]}"

for native_library in "${native_libraries[@]}"; do
    if readelf --sections "$native_library" | grep -q '\.debug'; then
        echo "Debug sections remain in packaged library: $native_library" >&2
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

echo "Package created: $ZIP_FILE ($(stat -c '%s' "$ZIP_FILE") bytes)"
