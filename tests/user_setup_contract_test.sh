#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLIC_SETUP="$PROJECT_ROOT/scripts-user/setup.sh"
PACKAGE_ENGINE="$PROJECT_ROOT/scripts-user/lib/package-plasmoid.sh"
PLASMA_CONTROL="$PROJECT_ROOT/scripts-user/lib/plasma-shell-control.sh"
UNIVERSAL_SETUP="$PROJECT_ROOT/scripts-user/setup-universal.sh"
DEVELOPER_SETUP="$PROJECT_ROOT/scripts-dev/setup.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

help_output="$(LC_ALL=en_US.UTF-8 LANGUAGE=en "$PUBLIC_SETUP" --help)"
help_output_single_line="${help_output//$'\n'/ }"
[[ "$help_output_single_line" == *"without running developer tests"* ]] \
    || fail "the public help does not state that developer tests are disabled"
[[ "$help_output" == *"scripts-dev/setup.sh"* ]] \
    || fail "the public help does not point developers to the strict setup"
[[ "$help_output" == *"--build-only"* ]] \
    || fail "the public help does not list --build-only"
[[ "$help_output" == *"--uninstall"* ]] \
    || fail "the public help does not list --uninstall"
[[ "$help_output" == *"--no-restart"* ]] \
    || fail "the public help does not list --no-restart"
[[ "$help_output" == *"--lang CODE"* ]] \
    || fail "the public help does not list the language override"
[[ "$help_output" == *"choose only one"* ]] \
    || fail "the public help does not explain primary action exclusivity"

grep -q 'PUNCHI_PACKAGE_VALIDATION_MODE=minimal' "$PUBLIC_SETUP" \
    || fail "the public setup does not select minimal packaging"
if grep -Eq '^[[:space:]]*(ctest|qmllint)([[:space:]]|$)' "$PUBLIC_SETUP"; then
    fail "the public setup directly executes a developer test command"
fi

grep -q 'build_testing=OFF' "$PACKAGE_ENGINE" \
    || fail "the package engine does not default minimal builds to BUILD_TESTING=OFF"
grep -q 'PUNCHI_PACKAGE_VALIDATION_MODE=full' \
    "$PROJECT_ROOT/scripts-dev/distro/fedora-package.sh" \
    || fail "the Fedora developer package does not select full validation"
grep -q 'PUNCHI_PACKAGE_VALIDATION_MODE=full' \
    "$PROJECT_ROOT/scripts-dev/distro/debian13-package.sh" \
    || fail "the Debian developer package does not select full validation"
[[ -x "$DEVELOPER_SETUP" ]] || fail "the developer setup is not executable"
grep -q 'source .*plasma-shell-control\.sh' "$PUBLIC_SETUP" \
    || fail "the public setup does not use the shared Plasma controller"
grep -q 'source .*plasma-shell-control\.sh' "$UNIVERSAL_SETUP" \
    || fail "the package installer does not use the shared Plasma controller"
if grep -Eq '^(do_restart_plasma|restart_plasma_shell)\(\)' \
        "$PUBLIC_SETUP" "$UNIVERSAL_SETUP"; then
    fail "a public entry point duplicates Plasma restart logic"
fi
[[ -r "$PLASMA_CONTROL" ]] || fail "the shared Plasma controller is missing"

# shellcheck source=../scripts-user/setup.sh
source "$PUBLIC_SETUP"
[[ "$(safe_label_component 'fedora 44/x86')" == "fedora_44_x86" ]] \
    || fail "the local artifact label was not sanitized"

mapfile -t uninstall_commands < <(required_commands_for_action uninstall)
(( ${#uninstall_commands[@]} == 0 )) \
    || fail "uninstall still requires build commands"
mapfile -t restart_commands < <(required_commands_for_action restart_plasma)
(( ${#restart_commands[@]} == 0 )) \
    || fail "restart still requires build commands"
mapfile -t package_commands < <(required_commands_for_action install_package)
[[ " ${package_commands[*]} " == *" kpackagetool6 "* ]] \
    || fail "installing an existing package does not require kpackagetool6"
[[ " ${package_commands[*]} " != *" c++ "* ]] \
    || fail "installing an existing package incorrectly requires a C++ compiler"
[[ " ${package_commands[*]} " != *" msgfmt "* ]] \
    || fail "installing an existing package incorrectly requires msgfmt"
[[ " ${package_commands[*]} " != *" cmake "* ]] \
    || fail "installing an existing package incorrectly requires CMake"

set +e
conflict_output="$(bash -c 'source "$1"; parse_args --uninstall --build-only' bash "$PUBLIC_SETUP" 2>&1)"
conflict_status=$?
restart_conflict_output="$(bash -c 'source "$1"; parse_args --restart-plasma --no-restart' bash "$PUBLIC_SETUP" 2>&1)"
restart_conflict_status=$?
language_output="$("$PUBLIC_SETUP" --lang xx --help 2>&1)"
language_status=$?
set -e
[[ "$conflict_status" == "1" && "$conflict_output" == *"cannot be combined"* ]] \
    || fail "conflicting primary actions were not rejected"
[[ "$restart_conflict_status" == "1" && "$restart_conflict_output" == *"cannot be combined"* ]] \
    || fail "--restart-plasma and --no-restart were not rejected"
[[ "$language_status" == "1" && "$language_output" == *"unsupported language code"* ]] \
    || fail "an unsupported language override was not rejected"

spanish_help="$(LC_ALL=es_ES.UTF-8 LANGUAGE= "$PUBLIC_SETUP" --help)"
[[ "$spanish_help" == *"Compila Punchi Dock Remastered"* ]] \
    || fail "es_ES was not detected automatically"
spanish_override_help="$(LC_ALL=en_US.UTF-8 LANGUAGE=en "$PUBLIC_SETUP" --lang es --help)"
[[ "$spanish_override_help" == *"Acciones principales"* ]] \
    || fail "the explicit Spanish language override was not honored"
german_help="$(LC_ALL=de_DE.UTF-8 LANGUAGE= "$PUBLIC_SETUP" --help)"
[[ "$german_help" == *"Hauptaktionen"* ]] \
    || fail "de_DE was not detected automatically"
portuguese_help="$(LC_ALL=pt_BR.UTF-8 LANGUAGE= "$PUBLIC_SETUP" --help)"
[[ "$portuguese_help" == *"Ações principais"* ]] \
    || fail "pt_BR was not detected automatically"

menu_output="$(printf '7\n' | LC_ALL=en_US.UTF-8 LANGUAGE=en "$PUBLIC_SETUP")"
[[ "$menu_output" == *"What would you like to do?"* ]] \
    || fail "the default interactive menu did not open"

set +e
invalid_output="$(
    PUNCHI_PACKAGE_CORE=1 \
    PUNCHI_PACKAGE_VALIDATION_MODE=invalid \
    PACKAGE_OUTPUT_FILE="$PROJECT_ROOT/dist/invalid-mode-test.plasmoid" \
        "$PACKAGE_ENGINE" 2>&1
)"
invalid_status=$?
set -e
[[ "$invalid_status" == "1" ]] \
    || fail "an invalid package validation mode was accepted"
[[ "$invalid_output" == *"unsupported package validation mode"* ]] \
    || fail "an invalid package validation mode lacked a clear diagnostic"

printf 'User/developer setup separation contract tests passed.\n'
