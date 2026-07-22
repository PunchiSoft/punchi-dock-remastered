#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

# shellcheck source=../scripts/lib/setup-logging.sh
source "$PROJECT_ROOT/scripts/lib/setup-logging.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

set +e
captured_output="$(
    PUNCHI_LOG_DIR="$TEMP_ROOT/logs" \
        punchi_run_setup_with_log "test-profile" \
        bash -c 'printf "standard output marker\n"; printf "error output marker\n" >&2; exit 7'
)"
captured_status=$?
set -e

[[ "$captured_status" == "7" ]] \
    || fail "expected wrapped exit status 7, got $captured_status"
[[ "$captured_output" == *"standard output marker"* ]] \
    || fail "standard output was not preserved"
[[ "$captured_output" == *"error output marker"* ]] \
    || fail "error output was not preserved"
[[ "$captured_output" == *"Exit status: 7"* ]] \
    || fail "the final exit status was not reported"

latest_log="$TEMP_ROOT/logs/setup-test-profile-latest.log"
[[ -f "$latest_log" ]] || fail "latest log file was not created"
grep -q 'standard output marker' "$latest_log" \
    || fail "standard output is missing from the log"
grep -q 'error output marker' "$latest_log" \
    || fail "error output is missing from the log"
grep -q 'Exit status: 7' "$latest_log" \
    || fail "exit status is missing from the log"

log_mode="$(stat -c '%a' "$latest_log")"
[[ "$log_mode" == "600" ]] || fail "expected private log mode 600, got $log_mode"

chmod() {
    return 1
}

set +e
shared_output="$(
    PUNCHI_LOG_DIR="$TEMP_ROOT/shared-logs" \
        punchi_run_setup_with_log "shared-profile" bash -c 'exit 0' 2>&1
)"
shared_status=$?
set -e
unset -f chmod

[[ "$shared_status" == "0" ]] \
    || fail "a shared filesystem chmod limitation stopped the setup"
[[ "$shared_output" == *"permissions could not be restricted"* ]] \
    || fail "the shared filesystem permission warning was not reported"

printf 'Setup logging tests passed.\n'
