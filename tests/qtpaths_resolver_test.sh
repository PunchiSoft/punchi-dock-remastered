#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESOLVER="$PROJECT_ROOT/scripts-user/lib/qtpaths-resolver.sh"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

mkdir -p "$TEST_ROOT/bin"
printf '%s\n' \
    '#!/usr/bin/env bash' \
    'case "${1:-}" in' \
    '  --qt-version) printf "%s\\n" "6.10.2" ;;' \
    '  --writable-path) printf "%s\\n" "/tmp/punchi-qt6-data" ;;' \
    '  *) exit 2 ;;' \
    'esac' > "$TEST_ROOT/bin/qtpaths6"
chmod +x "$TEST_ROOT/bin/qtpaths6"
printf '%s\n' \
    '#!/usr/bin/env bash' \
    'case "${1:-}" in' \
    '  --qt-version) printf "%s\\n" "5.15.18" ;;' \
    '  *) exit 2 ;;' \
    'esac' > "$TEST_ROOT/bin/qtpaths5"
chmod +x "$TEST_ROOT/bin/qtpaths5"

# shellcheck source=../scripts-user/lib/qtpaths-resolver.sh
source "$RESOLVER"

resolved="$(PATH="$TEST_ROOT/bin:/usr/bin:/bin" punchi_find_qtpaths6)"
[[ "$resolved" == "$TEST_ROOT/bin/qtpaths6" ]] \
    || fail "the Qt 6 executable available through PATH was not resolved"

resolved="$(
    QTPATHS_BIN="$TEST_ROOT/bin/qtpaths5" \
        PATH="$TEST_ROOT/bin:/usr/bin:/bin" \
        punchi_find_qtpaths6
)"
[[ "$resolved" == "$TEST_ROOT/bin/qtpaths6" ]] \
    || fail "a configured Qt 5 executable was accepted as Qt 6"

data_root="$(PATH="$TEST_ROOT/bin:/usr/bin:/bin" punchi_qt6_writable_data_root)"
[[ "$data_root" == "/tmp/punchi-qt6-data" ]] \
    || fail "GenericDataLocation was not queried through the resolved executable"

grep -q '/usr/lib/qt6/bin/qtpaths6' "$RESOLVER" \
    || fail "the standard Arch Linux Qt 6 path is not part of the resolver"
grep -q -- '--qt-version' "$RESOLVER" \
    || fail "the resolver does not verify the Qt major version"

printf 'Qt 6 qtpaths resolver tests passed.\n'
