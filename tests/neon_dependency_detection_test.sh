#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

OS_RELEASE_FILE="$TEMP_DIR/os-release"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

write_os_release() {
    local distro_id="$1"
    local distro_like="$2"

    cat > "$OS_RELEASE_FILE" <<EOF
ID=$distro_id
ID_LIKE=$distro_like
NAME="Test Linux"
PRETTY_NAME="Test Linux"
EOF
}

# shellcheck source=../scripts-user/setup.sh
source "$PROJECT_ROOT/scripts-user/setup.sh"

dpkg-query() {
    local package_name="${!#}"

    if [[ " ${MISSING_PACKAGES:-} " == *" $package_name "* ]]; then
        return 1
    fi
    printf 'install ok installed'
}

run_dependency_check() {
    local distro_id="$1"
    local distro_like="$2"
    local missing_packages="$3"

    write_os_release "$distro_id" "$distro_like"
    MISSING_PACKAGES="$missing_packages" \
        PUNCHI_OS_RELEASE_FILE="$OS_RELEASE_FILE" \
        punchi_user_missing_dependencies
}

output="$(run_dependency_check neon ubuntu 'plasma-activities-dev libkf6config-dev')"
grep -qx 'distro:debian' <<<"$output" \
    || fail "KDE neon was not classified as Debian: $output"
grep -qx 'plasma-activities-dev' <<<"$output" \
    || fail "KDE neon activities package was not reported: $output"
if grep -qx 'libplasmaactivities-dev' <<<"$output"; then
    fail "KDE neon still reports the Debian-only activities package"
fi

output="$(run_dependency_check neon ubuntu '')"
[[ -z "$output" ]] \
    || fail "an installed KDE neon system should not report missing packages: $output"

output="$(run_dependency_check debian '' 'libplasmaactivities-dev')"
grep -qx 'libplasmaactivities-dev' <<<"$output" \
    || fail "Debian activities package was not reported: $output"
if grep -qx 'plasma-activities-dev' <<<"$output"; then
    fail "Debian incorrectly reports the KDE neon activities package"
fi

output="$(run_dependency_check custom ubuntu 'libplasmaactivities-dev')"
grep -qx 'distro:debian' <<<"$output" \
    || fail "ID_LIKE=ubuntu was not recognized: $output"
grep -qx 'libplasmaactivities-dev' <<<"$output" \
    || fail "ID_LIKE=ubuntu did not use the Debian package list: $output"

output="$(run_dependency_check alpine '' '')"
grep -qx 'distro:unsupported' <<<"$output" \
    || fail "an unsupported distribution was not marked: $output"
grep -qx 'alpine' <<<"$output" \
    || fail "the unsupported distribution name was not reported: $output"

write_os_release alpine ''
set +e
report_output="$(
    PUNCHI_OS_RELEASE_FILE="$OS_RELEASE_FILE" \
        punchi_check_and_report_dependencies 2>&1
)"
report_status=$?
set -e
[[ "$report_status" == "1" ]] \
    || fail "the unsupported dependency check must return a failure status"
[[ "$report_output" == *"Automatic dependency checks are not available for alpine"* ]] \
    || fail "the unsupported dependency notice is missing: $report_output"

printf 'KDE neon dependency detection tests passed.\n'
