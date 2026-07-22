#!/usr/bin/env bash
set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$LIB_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'EOF'
Usage: scripts/lib/package-plasmoid.sh

Internal packaging engine. It detects Fedora, Debian, or Kubuntu and creates a
versioned package for the current system. Prefer a distribution setup command:
  scripts/setup-fedora.sh
  scripts/setup-debian13.sh
  scripts/setup-debian14-testing.sh
  scripts/setup-kubuntu.sh

EOF
    exit 0
fi

if (( $# > 0 )); then
    echo "Error: this script accepts no arguments. Use --help to list the distribution entry points." >&2
    exit 1
fi

if [[ "${PUNCHI_PACKAGE_CORE:-0}" != "1" ]]; then
    if [[ ! -r /etc/os-release ]]; then
        echo "Error: the distribution could not be detected from /etc/os-release." >&2
        exit 1
    fi

    # shellcheck disable=SC1091
    source /etc/os-release

    case "${ID:-}" in
        fedora)
            echo "==> Detected profile: Fedora ${VERSION_ID:-unknown}"
            exec "$SCRIPTS_DIR/distro/fedora-package.sh"
            ;;
        debian)
            if [[ "${VERSION_ID:-}" == "13" || "${VERSION_CODENAME:-}" == "trixie" ]]; then
                echo "==> Detected profile: Debian 13"
                exec "$SCRIPTS_DIR/distro/debian13-package.sh"
            fi
            if [[ "${VERSION_ID:-}" == "14" || "${VERSION_CODENAME:-}" == "forky" ]]; then
                echo "==> Detected profile: Debian 14/testing"
                exec "$SCRIPTS_DIR/distro/debian14-testing-package.sh"
            fi
            echo "Error: unsupported Debian release: ${PRETTY_NAME:-unknown}." >&2
            echo "Use an explicit setup script matching the Debian release." >&2
            exit 1
            ;;
        ubuntu)
            echo "==> Detected profile: Kubuntu/Ubuntu ${VERSION_ID:-unknown}"
            exec "$SCRIPTS_DIR/distro/kubuntu-package.sh"
            ;;
        *)
            echo "Error: no packaging profile exists for distribution: ${ID:-unknown}." >&2
            echo "Available profiles: Fedora, Debian, and Kubuntu." >&2
            exit 1
            ;;
    esac
fi

BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build}"
PACKAGE_ROOT="$BUILD_DIR/package-root"
DIST_DIR="${DIST_DIR:-$PROJECT_ROOT/dist}"

if [[ -z "${PACKAGE_OUTPUT_FILE:-}" ]]; then
    echo "Internal error: the platform profile did not define PACKAGE_OUTPUT_FILE." >&2
    exit 1
fi

if [[ "$PACKAGE_OUTPUT_FILE" != /* ]]; then
    PACKAGE_OUTPUT_FILE="$PROJECT_ROOT/$PACKAGE_OUTPUT_FILE"
fi

ZIP_FILE="$PACKAGE_OUTPUT_FILE"
DIST_DIR="$(dirname "$ZIP_FILE")"
QMLLINT_BASELINE_FILE="${QMLLINT_BASELINE_FILE:-$PROJECT_ROOT/scripts/qmllint-baseline.env}"
PACKAGE_BUILD_TYPE="${PACKAGE_BUILD_TYPE:-Release}"
STRIP_BIN="${STRIP_BIN:-strip}"
TRANSLATION_DOMAIN="plasma_applet_org.kde.plasma.punchi-dock-remastered"
PO_DIR="$PROJECT_ROOT/po"

echo "==> Target artifact: $ZIP_FILE"

resolve_qmllint() {
    local candidate=""
    local version=""
    local candidates=()

    if [[ -n "${QMLLINT_BIN:-}" ]]; then
        candidates+=("$QMLLINT_BIN")
    fi

    candidates+=(
        "/usr/lib64/qt6/bin/qmllint"
        "/usr/lib/qt6/bin/qmllint"
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

    echo "A Qt 6 qmllint executable is required. Set QMLLINT_BIN or install the Qt 6 development tools." >&2
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
require_command msgfmt
require_command msgattrib
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
if [[ ! -f "$QMLLINT_BASELINE_FILE" && "${QMLLINT_RECORD_BASELINE:-0}" != "1" ]]; then
    echo "Error: no existe el baseline de qmllint: $QMLLINT_BASELINE_FILE" >&2
    echo "Define QMLLINT_BASELINE_FILE con un baseline calibrado para esta plataforma." >&2
    exit 1
fi

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

report_warning_category_excess() {
    local category_name="$1"
    local warning_count="$2"
    local baseline_count="$3"
    local warning_pattern="$4"
    local detail_limit=12

    if (( warning_count <= baseline_count )); then
        return
    fi

    echo "Baseline exceeded for $category_name: current=$warning_count, baseline=$baseline_count, delta=+$((warning_count - baseline_count))" >&2
    grep '^Warning:' "$QMLLINT_LOG" \
        | grep "$warning_pattern" \
        | sed -n "1,${detail_limit}p" >&2 || true
    if (( warning_count > detail_limit )); then
        echo "... $((warning_count - detail_limit)) additional $category_name warnings omitted. Full log: $QMLLINT_LOG" >&2
    fi
}

echo "qmllint warnings: total=$warning_total, unqualified=$warning_unqualified, layout=$warning_layout, missing-property=$warning_missing_property, import=$warning_import"
echo "qmllint log: $QMLLINT_LOG"

if [[ "${QMLLINT_RECORD_BASELINE:-0}" == "1" ]]; then
    mkdir -p "$(dirname "$QMLLINT_BASELINE_FILE")"
    printf 'QMLLINT_BASELINE_TOTAL=%s\n' "$warning_total" >"$QMLLINT_BASELINE_FILE"
    printf 'QMLLINT_BASELINE_UNQUALIFIED=%s\n' "$warning_unqualified" >>"$QMLLINT_BASELINE_FILE"
    printf 'QMLLINT_BASELINE_LAYOUT=%s\n' "$warning_layout" >>"$QMLLINT_BASELINE_FILE"
    printf 'QMLLINT_BASELINE_MISSING_PROPERTY=%s\n' "$warning_missing_property" >>"$QMLLINT_BASELINE_FILE"
    printf 'QMLLINT_BASELINE_IMPORT=%s\n' "$warning_import" >>"$QMLLINT_BASELINE_FILE"
    echo "qmllint baseline recorded: $QMLLINT_BASELINE_FILE"

    QMLLINT_BASELINE_TOTAL="$warning_total"
    QMLLINT_BASELINE_UNQUALIFIED="$warning_unqualified"
    QMLLINT_BASELINE_LAYOUT="$warning_layout"
    QMLLINT_BASELINE_MISSING_PROPERTY="$warning_missing_property"
    QMLLINT_BASELINE_IMPORT="$warning_import"
fi

if (( warning_total > QMLLINT_BASELINE_TOTAL \
    || warning_unqualified > QMLLINT_BASELINE_UNQUALIFIED \
    || warning_layout > QMLLINT_BASELINE_LAYOUT \
    || warning_missing_property > QMLLINT_BASELINE_MISSING_PROPERTY \
    || warning_import > QMLLINT_BASELINE_IMPORT )); then
    echo "qmllint warnings exceed the recorded baseline in $QMLLINT_BASELINE_FILE" >&2
    report_warning_category_excess "total" "$warning_total" "$QMLLINT_BASELINE_TOTAL" '^Warning:'
    report_warning_category_excess "unqualified" "$warning_unqualified" "$QMLLINT_BASELINE_UNQUALIFIED" '\[unqualified\]'
    report_warning_category_excess "layout" "$warning_layout" "$QMLLINT_BASELINE_LAYOUT" '\[Quick\.layout-positioning\]'
    report_warning_category_excess "missing-property" "$warning_missing_property" "$QMLLINT_BASELINE_MISSING_PROPERTY" '\[missing-property\]'
    report_warning_category_excess "import" "$warning_import" "$QMLLINT_BASELINE_IMPORT" '\[import\]'
    exit 1
fi

echo "==> [2/4] Building and testing the native QML module"
echo "Build type: $PACKAGE_BUILD_TYPE"
env \
    GIT_CONFIG_COUNT=1 \
    GIT_CONFIG_KEY_0=safe.directory \
    GIT_CONFIG_VALUE_0="$PROJECT_ROOT" \
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

translation_count=0
shopt -s nullglob
translation_catalogs=("$PO_DIR"/*.po)
for translation_catalog in "${translation_catalogs[@]}"; do
    language="$(basename "$translation_catalog" .po)"
    untranslated_count="$(msgattrib --untranslated --no-obsolete "$translation_catalog" | grep -c '^msgid ' || true)"
    fuzzy_count="$(msgattrib --only-fuzzy --no-obsolete "$translation_catalog" | grep -c '^msgid ' || true)"
    if (( untranslated_count > 1 || fuzzy_count > 1 )); then
        echo "Translation catalog is incomplete or fuzzy: $translation_catalog" >&2
        exit 1
    fi

    catalog_dir="$PACKAGE_ROOT/contents/locale/$language/LC_MESSAGES"
    cmake -E make_directory "$catalog_dir"
    msgfmt \
        --check \
        --check-format \
        --output-file="$catalog_dir/$TRANSLATION_DOMAIN.mo" \
        "$translation_catalog"
    ((translation_count += 1))
done

if (( translation_count == 0 )); then
    echo "No translation catalogs were found in $PO_DIR" >&2
    exit 1
fi

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

if ! unzip -Z1 "$ZIP_FILE" | grep -qx "contents/locale/es/LC_MESSAGES/$TRANSLATION_DOMAIN.mo"; then
    echo "The Spanish translation catalog is missing from the plasmoid" >&2
    exit 1
fi

if unzip -Z1 "$ZIP_FILE" | grep -q '^locale/'; then
    echo "Translation catalogs were staged outside the KPackage contents prefix" >&2
    exit 1
fi

if unzip -Z1 "$ZIP_FILE" | grep -Eq '\.(po|pot)$'; then
    echo "Translation source files were found in the plasmoid" >&2
    exit 1
fi

if unzip -Z1 "$ZIP_FILE" | grep -Eq '^(build|dist|backup|docs|bitacora|kde-sdk|scripts|src|\.agents|\.git)/|(^|/)(debug\.log|.*\.py|.*\.sh|.*\.plasmoid)$'; then
    echo "Development files were found in the plasmoid" >&2
    exit 1
fi

echo "Package created: $ZIP_FILE ($(stat -c '%s' "$ZIP_FILE") bytes)"
