#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTROL_HELPER="$PROJECT_ROOT/scripts-user/lib/plasma-shell-control.sh"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

# shellcheck source=../scripts-user/lib/plasma-shell-control.sh
source "$CONTROL_HELPER"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

sleep() {
    return 0
}

systemctl() {
    return 1
}

kquitapp6() {
    return 0
}

kstart6() {
    return 0
}

pid_state="$TEMP_ROOT/pid-state"
pgrep() {
    if [[ ! -f "$pid_state" ]]; then
        printf 'before\n' >"$pid_state"
        printf '100\n'
    else
        printf '200\n'
    fi
}

punchi_restart_plasma_shell >"$TEMP_ROOT/success.log" 2>&1 \
    || fail "a confirmed PID transition was reported as a failure"
[[ "$PUNCHI_PLASMA_PID" == "200" ]] \
    || fail "the confirmed Plasma PID was not exposed to diagnostics"
grep -q 'restarted successfully' "$TEMP_ROOT/success.log" \
    || fail "the successful restart lacked a confirmation message"

pgrep() {
    return 1
}

set +e
punchi_restart_plasma_shell >"$TEMP_ROOT/failure.log" 2>&1
failure_status=$?
set -e
[[ "$failure_status" == "1" ]] \
    || fail "an unconfirmed Plasma restart returned success"
grep -q 'PID did not change' "$TEMP_ROOT/failure.log" \
    || fail "an unconfirmed restart lacked a clear diagnostic"

printf 'Plasma Shell control tests passed.\n'
