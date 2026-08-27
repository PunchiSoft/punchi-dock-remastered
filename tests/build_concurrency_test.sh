#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONCURRENCY_LIB="$PROJECT_ROOT/scripts-user/lib/build-concurrency.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

[[ -r "$CONCURRENCY_LIB" ]] || fail "the build concurrency helper is missing"

# shellcheck source=../scripts-user/lib/build-concurrency.sh
source "$CONCURRENCY_LIB"

# 1. Test RAM detection
detected_ram="$(punchi_detect_total_ram_mb)"
[[ "$detected_ram" =~ ^[0-9]+$ && "$detected_ram" -gt 0 ]] \
    || fail "total RAM in MB was not detected as a positive integer: $detected_ram"

# 2. Test RAM display formatting
formatted_4gb="$(punchi_format_ram_display 4096)"
[[ "$formatted_4gb" == "4.0 GiB" ]] \
    || fail "4096 MB was not formatted as 4.0 GiB: $formatted_4gb"

formatted_512mb="$(punchi_format_ram_display 512)"
[[ "$formatted_512mb" == "512 MiB" ]] \
    || fail "512 MB was not formatted as 512 MiB: $formatted_512mb"

formatted_8gb="$(punchi_format_ram_display 8192)"
[[ "$formatted_8gb" == "8.0 GiB" ]] \
    || fail "8192 MB was not formatted as 8.0 GiB: $formatted_8gb"

# 3. Test CPU core detection
detected_cores="$(punchi_detect_cpu_cores)"
[[ "$detected_cores" =~ ^[0-9]+$ && "$detected_cores" -ge 1 ]] \
    || fail "CPU core count was not detected as a valid integer >= 1: $detected_cores"

# 4. Test Concurrency Set / Get
unset PUNCHI_BUILD_JOBS CMAKE_BUILD_PARALLEL_LEVEL CTEST_PARALLEL_LEVEL || true

punchi_set_concurrency_level 2 || fail "failed to set concurrency level to 2"
[[ "${PUNCHI_BUILD_JOBS:-}" == "2" ]] || fail "PUNCHI_BUILD_JOBS was not exported as 2"
[[ "${CMAKE_BUILD_PARALLEL_LEVEL:-}" == "2" ]] || fail "CMAKE_BUILD_PARALLEL_LEVEL was not exported as 2"
[[ "${CTEST_PARALLEL_LEVEL:-}" == "2" ]] || fail "CTEST_PARALLEL_LEVEL was not exported as 2"

current_level="$(punchi_get_concurrency_level)"
[[ "$current_level" == "2" ]] || fail "get_concurrency_level did not return 2: $current_level"

# 5. Test invalid concurrency values
if punchi_set_concurrency_level "invalid"; then
    fail "invalid string accepted as concurrency level"
fi
if punchi_set_concurrency_level "0"; then
    fail "zero accepted as concurrency level"
fi
if punchi_set_concurrency_level "-4"; then
    fail "negative number accepted as concurrency level"
fi

# 6. Test Profile Labels
punchi_set_concurrency_level 1
label_1="$(punchi_concurrency_profile_label 1)"
[[ "$label_1" == *"Safe Mode"* || "$label_1" == *"1 core"* ]] \
    || fail "concurrency profile label for 1 core is incorrect: $label_1"

label_2="$(punchi_concurrency_profile_label 2)"
[[ "$label_2" == *"Balanced Mode"* || "$label_2" == *"2 cores"* ]] \
    || fail "concurrency profile label for 2 cores is incorrect: $label_2"

# 7. Check integration into setup entry points and packaging engine
for consumer in \
    "$PROJECT_ROOT/scripts-user/setup.sh" \
    "$PROJECT_ROOT/scripts-dev/setup.sh" \
    "$PROJECT_ROOT/scripts-user/lib/package-plasmoid.sh" \
    "$PROJECT_ROOT/scripts-dev/distro/arch-setup.sh" \
    "$PROJECT_ROOT/scripts-dev/distro/debian13-setup.sh" \
    "$PROJECT_ROOT/scripts-dev/distro/fedora-setup.sh"; do
    grep -q 'source .*build-concurrency\.sh' "$consumer" \
        || fail "script consumer does not source build-concurrency.sh: $consumer"
done

# 8. Test CLI argument handling on scripts
user_help_output="$("$PROJECT_ROOT/scripts-user/setup.sh" --help)"
echo "$user_help_output" | grep -q -- '--jobs' \
    || fail "scripts-user/setup.sh --help does not document --jobs"

dev_help_output="$("$PROJECT_ROOT/scripts-dev/setup.sh" --help)"
echo "$dev_help_output" | grep -q -- '--jobs' \
    || fail "scripts-dev/setup.sh --help does not document --jobs"

printf 'Build concurrency and memory safety tests passed.\n'
