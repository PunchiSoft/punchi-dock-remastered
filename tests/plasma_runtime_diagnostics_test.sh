#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

# shellcheck source=../scripts/lib/plasma-runtime-diagnostics.sh
source "$PROJECT_ROOT/scripts/lib/plasma-runtime-diagnostics.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

mkdir -p "$TEMP_ROOT/bin"

cat >"$TEMP_ROOT/bin/journalctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$PUNCHI_TEST_JOURNAL_ARGS"
printf '%s\n' "${PUNCHI_TEST_JOURNAL_OUTPUT:-}"
exit "${PUNCHI_TEST_JOURNAL_STATUS:-0}"
EOF
chmod +x "$TEMP_ROOT/bin/journalctl"

plugin_id="org.kde.plasma.punchi-dock-remastered"
restart_timestamp="2026-08-23T12:34:56-04:00"
argument_log="$TEMP_ROOT/journal-arguments.log"
clean_log="$TEMP_ROOT/clean.log"

PATH="$TEMP_ROOT/bin:$PATH" \
PUNCHI_TEST_JOURNAL_ARGS="$argument_log" \
PUNCHI_TEST_JOURNAL_OUTPUT="Normal startup for $plugin_id" \
    punchi_collect_plasma_runtime_diagnostics \
        4242 "$restart_timestamp" "$clean_log" "$plugin_id"

[[ -f "$clean_log" ]] || fail "the PID-scoped log was not created"
[[ "$(stat -c '%a' "$clean_log")" == "600" ]] \
    || fail "the diagnostics log is not private"
grep -q -- '--user' "$argument_log" \
    || fail "journalctl was not limited to the user journal"
grep -q -- '_PID=4242' "$argument_log" \
    || fail "journalctl was not limited to the new Plasma Shell PID"
grep -q -- "--since $restart_timestamp" "$argument_log" \
    || fail "journalctl did not use the exact restart timestamp"
grep -q -- '--no-pager --quiet' "$argument_log" \
    || fail "journalctl did not use deterministic non-interactive output"

unrelated_log="$TEMP_ROOT/unrelated.log"
PATH="$TEMP_ROOT/bin:$PATH" \
PUNCHI_TEST_JOURNAL_ARGS="$argument_log" \
PUNCHI_TEST_JOURNAL_OUTPUT='file:///other/plugin/main.qml:1: TypeError: unrelated failure' \
    punchi_collect_plasma_runtime_diagnostics \
        4242 "$restart_timestamp" "$unrelated_log" "$plugin_id"

blocking_log="$TEMP_ROOT/blocking.log"
set +e
PATH="$TEMP_ROOT/bin:$PATH" \
PUNCHI_TEST_JOURNAL_ARGS="$argument_log" \
PUNCHI_TEST_JOURNAL_OUTPUT="file:///plasma/plasmoids/$plugin_id/contents/ui/main.qml:42: TypeError: Cannot read property 'width' of null" \
    punchi_collect_plasma_runtime_diagnostics \
        4242 "$restart_timestamp" "$blocking_log" "$plugin_id"
blocking_status=$?
set -e
[[ "$blocking_status" == "1" ]] \
    || fail "a project QML runtime error did not fail diagnostics"
grep -q 'TypeError:' "$blocking_log" \
    || fail "the blocking line was not preserved for diagnosis"

failed_log="$TEMP_ROOT/journal-failed.log"
set +e
PATH="$TEMP_ROOT/bin:$PATH" \
PUNCHI_TEST_JOURNAL_ARGS="$argument_log" \
PUNCHI_TEST_JOURNAL_STATUS=9 \
    punchi_collect_plasma_runtime_diagnostics \
        4242 "$restart_timestamp" "$failed_log" "$plugin_id"
journal_status=$?
set -e
[[ "$journal_status" == "1" ]] \
    || fail "a journalctl failure did not stop diagnostics"
[[ ! -e "$failed_log" ]] \
    || fail "a failed journal read published an incomplete log"

set +e
PATH="$TEMP_ROOT/bin:$PATH" \
PUNCHI_TEST_JOURNAL_ARGS="$argument_log" \
    punchi_collect_plasma_runtime_diagnostics \
        '42;unsafe' "$restart_timestamp" "$TEMP_ROOT/invalid.log" "$plugin_id"
invalid_pid_status=$?
set -e
[[ "$invalid_pid_status" == "2" ]] \
    || fail "an invalid PID was not rejected before journalctl"

installer_scripts=(
    "$PROJECT_ROOT/scripts/lib/install-local-test.sh"
    "$PROJECT_ROOT/scripts/setup-universal.sh"
    "$PROJECT_ROOT/scripts/dev/instalar-plasmoide.sh"
)
for installer_script in "${installer_scripts[@]}"; do
    grep -q 'source "$LIB_DIR/plasma-runtime-diagnostics.sh"' \
        "$installer_script" \
        || fail "$installer_script does not use the shared diagnostics helper"
    grep -q 'restart_started_at="$(date --iso-8601=seconds)"' \
        "$installer_script" \
        || fail "$installer_script does not record the exact restart time"
    grep -q 'punchi_collect_plasma_runtime_diagnostics' "$installer_script" \
        || fail "$installer_script does not validate the PID-scoped journal"
    if grep -q 'journalctl --user --since "10 seconds ago"' \
            "$installer_script"; then
        fail "$installer_script still reads an unscoped journal window"
    fi
    if grep -q 'restart_plasma_shell || true' "$installer_script"; then
        fail "$installer_script still ignores a failed Plasma Shell restart"
    fi
done

printf 'Plasma runtime diagnostics tests passed.\n'
