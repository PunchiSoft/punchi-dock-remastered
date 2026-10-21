#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

# shellcheck source=../scripts-user/lib/universal-package-validation.sh
source "$PROJECT_ROOT/scripts-user/lib/universal-package-validation.sh"

PLUGIN_ID="org.kde.plasma.punchi-dock-remastered"
DIST_DIR="$TEMP_ROOT/dist"
mkdir -p "$DIST_DIR"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

make_package() {
    local package_path="$1"
    local plugin_id="$2"
    local version="$3"
    local structure="${4:-Plasma/Applet}"
    local package_root="$TEMP_ROOT/package"

    rm -rf "$package_root"
    mkdir -p "$package_root"
    cat > "$package_root/metadata.json" <<EOF
{
    "KPackageStructure": "$structure",
    "KPlugin": {
        "Id": "$plugin_id",
        "Version": "$version"
    }
}
EOF
    ( cd "$package_root" && zip -q -r "$package_path" metadata.json )
}

valid="$DIST_DIR/punchi-dock-remastered-0.9.7.75-universal.plasmoid"
make_package "$valid" "$PLUGIN_ID" "0.9.7.75"

version="$(punchi_validate_universal_package "$valid" "$PLUGIN_ID" "0.9.7.74")" \
    || fail "a valid package was rejected"
[[ "$version" == "0.9.7.75" ]] || fail "the package version was not reported"

set +e
version="$(punchi_validate_universal_package "$valid" "$PLUGIN_ID" "0.9.7.76")"
status=$?
set -e
[[ "$status" == "2" ]] || fail "an older package did not report status 2"
[[ "$version" == "0.9.7.75" ]] || fail "the older package version was not reported"

wrong_id="$DIST_DIR/punchi-dock-remastered-0.9.7.75-wrong-id-universal.plasmoid"
make_package "$wrong_id" "org.example.other" "0.9.7.75"
set +e
punchi_validate_universal_package "$wrong_id" "$PLUGIN_ID" "" >/dev/null
status=$?
set -e
[[ "$status" == "1" ]] || fail "a package with a different plugin ID was accepted"

wrong_structure="$DIST_DIR/punchi-dock-remastered-0.9.7.75-wrong-structure-universal.plasmoid"
make_package "$wrong_structure" "$PLUGIN_ID" "0.9.7.75" "Plasma/Theme"
set +e
punchi_validate_universal_package "$wrong_structure" "$PLUGIN_ID" "" >/dev/null
status=$?
set -e
[[ "$status" == "1" ]] || fail "a package with the wrong structure was accepted"

missing_metadata="$DIST_DIR/punchi-dock-remastered-0.9.7.75-no-metadata-universal.plasmoid"
mkdir -p "$TEMP_ROOT/empty-package"
touch "$TEMP_ROOT/empty-package/readme.txt"
( cd "$TEMP_ROOT/empty-package" && zip -q -r "$missing_metadata" readme.txt )
set +e
punchi_validate_universal_package "$missing_metadata" "$PLUGIN_ID" "" >/dev/null
status=$?
set -e
[[ "$status" == "1" ]] || fail "a package without metadata was accepted"

checksum_package="$DIST_DIR/punchi-dock-remastered-0.9.7.75-universal.plasmoid"
( cd "$DIST_DIR" && sha256sum "$(basename "$checksum_package")" \
    > "SHA256SUMS-0.9.7.75.txt" )
punchi_verify_package_checksum "$checksum_package" "$DIST_DIR" "0.9.7.75" \
    || fail "a valid checksum was rejected"
( cd "$TEMP_ROOT" \
    && punchi_verify_package_checksum "dist/$(basename "$checksum_package")" \
        "dist" "0.9.7.75" ) \
    || fail "a relative dist directory was not verified"

printf 'corruption' >> "$checksum_package"
set +e
punchi_verify_package_checksum "$checksum_package" "$DIST_DIR" "0.9.7.75"
status=$?
set -e
[[ "$status" == "1" ]] || fail "a checksum mismatch was not reported"

rm -f "$DIST_DIR/SHA256SUMS-0.9.7.75.txt"
set +e
punchi_verify_package_checksum "$checksum_package" "$DIST_DIR" "0.9.7.75"
status=$?
set -e
[[ "$status" == "3" ]] || fail "a missing checksum file was not reported as unavailable"

metadata_file="$TEMP_ROOT/metadata.json"
cat > "$metadata_file" <<'EOF'
{
    "KPlugin": {
        "Id": "org.kde.plasma.punchi-dock-remastered",
        "Version": "0.9.7.75"
    }
}
EOF
[[ "$(punchi_read_project_version "$metadata_file")" == "0.9.7.75" ]] \
    || fail "the project version could not be read from metadata.json"
if punchi_read_project_version "$TEMP_ROOT/missing.json" >/dev/null 2>&1; then
    fail "a missing metadata file was accepted"
fi

printf 'Universal package validation tests passed.\n'
