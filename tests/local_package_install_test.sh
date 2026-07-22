#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

# shellcheck source=../scripts/lib/local-package-install.sh
source "$PROJECT_ROOT/scripts/lib/local-package-install.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

mkdir -p "$TEMP_ROOT/bin" "$TEMP_ROOT/data"
package_file="$TEMP_ROOT/punchi-local-test.plasmoid"
install_dir="$TEMP_ROOT/data/plasma/plasmoids/org.punchi.test"
command_log="$TEMP_ROOT/kpackagetool.log"
: >"$package_file"

cat >"$TEMP_ROOT/bin/kpackagetool6" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$PUNCHI_TEST_COMMAND_LOG"

case " $* " in
    *" -u "*)
        exit 1
        ;;
    *" -i "*)
        if [[ "${PUNCHI_TEST_INSTALL_FAIL:-0}" == "1" ]]; then
            exit 1
        fi
        mkdir -p "$PUNCHI_TEST_INSTALL_DIR"
        printf '{}\n' >"$PUNCHI_TEST_INSTALL_DIR/metadata.json"
        ;;
esac
EOF
chmod +x "$TEMP_ROOT/bin/kpackagetool6"

PATH="$TEMP_ROOT/bin:$PATH" \
PUNCHI_TEST_COMMAND_LOG="$command_log" \
PUNCHI_TEST_INSTALL_DIR="$install_dir" \
    punchi_install_local_package \
        "$package_file" "$install_dir" "$TEMP_ROOT/data" "org.punchi.test"

[[ -f "$install_dir/metadata.json" ]] \
    || fail "a missing local package was not installed"
grep -q -- '-u .*punchi-local-test.plasmoid' "$command_log" \
    || fail "the update path was not attempted first"
grep -q -- '-i .*punchi-local-test.plasmoid' "$command_log" \
    || fail "the fresh install path was not used after update failed"
if compgen -G "$TEMP_ROOT/data/org.punchi.test.backup.*" >/dev/null; then
    fail "a backup was created for a nonexistent installation"
fi

printf 'previous installation\n' >"$install_dir/metadata.json"
PATH="$TEMP_ROOT/bin:$PATH" \
PUNCHI_TEST_COMMAND_LOG="$command_log" \
PUNCHI_TEST_INSTALL_DIR="$install_dir" \
    punchi_install_local_package \
        "$package_file" "$install_dir" "$TEMP_ROOT/data" "org.punchi.test"

grep -q '^{}$' "$install_dir/metadata.json" \
    || fail "an existing same-version package was not replaced"
if compgen -G "$TEMP_ROOT/data/org.punchi.test.backup.*" >/dev/null; then
    fail "the successful replacement left its backup behind"
fi

printf 'restorable installation\n' >"$install_dir/metadata.json"
set +e
PATH="$TEMP_ROOT/bin:$PATH" \
PUNCHI_TEST_COMMAND_LOG="$command_log" \
PUNCHI_TEST_INSTALL_DIR="$install_dir" \
PUNCHI_TEST_INSTALL_FAIL=1 \
    punchi_install_local_package \
        "$package_file" "$install_dir" "$TEMP_ROOT/data" "org.punchi.test"
failed_install_status=$?
set -e

[[ "$failed_install_status" == "1" ]] \
    || fail "expected a failed replacement to return status 1"
grep -q '^restorable installation$' "$install_dir/metadata.json" \
    || fail "the previous installation was not restored after failure"

printf 'Local package installation tests passed.\n'
