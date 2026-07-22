#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../scripts/lib/qmllint-baseline.sh
source "$PROJECT_ROOT/scripts/lib/qmllint-baseline.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

actual_path="$(punchi_qmllint_baseline_path "/tmp/punchi profile/" "0.9.0+testing/1")"
expected_path="/tmp/punchi profile/qmllint-baseline-0.9.0_testing_1.env"

[[ "$actual_path" == "$expected_path" ]] \
    || fail "expected $expected_path, got $actual_path"

printf 'qmllint baseline path tests passed.\n'
