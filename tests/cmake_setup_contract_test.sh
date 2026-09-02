#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CMAKE_SETUP="$PROJECT_ROOT/scripts-cmake/setup.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

[[ -x "$CMAKE_SETUP" ]] || fail "the CMake setup assistant is not executable"

help_output="$(LC_ALL=C.UTF-8 LANGUAGE=en PUNCHI_LANG=en "$CMAKE_SETUP" --lang en --help)"
[[ "$help_output" == *"Checks the native build requirements"* ]] \
    || fail "the help does not explain the requirement check"
[[ "$help_output" == *"--build-install"* ]] \
    || fail "the help does not expose the combined build and install action"
[[ "$help_output" == *"--no-restart"* ]] \
    || fail "the help does not expose restart control"
[[ "$help_output" == *"does not install system packages"* ]] \
    || fail "the help does not state the dependency installation boundary"
[[ "$help_output" != *$'\033['* ]] \
    || fail "redirected help output contains ANSI color sequences"

source "$CMAKE_SETUP"
PUNCHI_LANG=en
punchi_prepare_setup_localization "$PROJECT_ROOT"

unset NO_COLOR
TERM=xterm-256color
punchi_terminal_allows_color \
    || fail "a regular terminal type does not allow semantic colors"
NO_COLOR=""
if punchi_terminal_allows_color; then
    fail "NO_COLOR does not disable semantic colors when set to an empty value"
fi
unset NO_COLOR
TERM=dumb
if punchi_terminal_allows_color; then
    fail "TERM=dumb does not disable semantic colors"
fi
TERM=xterm-256color

color_output="$(
    bash -c '
        source "$1"
        punchi_prepare_setup_localization "$2"
        punchi_terminal_supports_color() { return 0; }
        punchi_gettext_styled_line warning 1 "Color warning"
        punchi_gettext_styled_line error 1 "Color error"
        punchi_gettext_styled_line success 1 "Color success"
        punchi_gettext_styled_line info 1 "Color information"
    ' bash "$CMAKE_SETUP" "$PROJECT_ROOT"
)"
[[ "$color_output" == *$'\033[1m\033[33mColor warning\033[0m'* ]] \
    || fail "warning output does not use bold yellow"
[[ "$color_output" == *$'\033[1m\033[31mColor error\033[0m'* ]] \
    || fail "error output does not use bold red"
[[ "$color_output" == *$'\033[32mColor success\033[0m'* ]] \
    || fail "success output does not use green"
[[ "$color_output" == *$'\033[36mColor information\033[0m'* ]] \
    || fail "information output does not use cyan"

set +e
missing_output="$(
    CXX=punchi-missing-cxx \
        LC_ALL=C.UTF-8 LANGUAGE=en PUNCHI_LANG=en \
        "$CMAKE_SETUP" --lang en --check 2>&1
)"
missing_status=$?
set -e
[[ "$missing_status" == "1" ]] \
    || fail "a missing C++ compiler did not stop the requirement check"
[[ "$missing_output" == *"A C++20 compiler"* ]] \
    || fail "the missing compiler diagnostic is not actionable"
[[ "$missing_output" == *"run this assistant again"* ]] \
    || fail "the missing requirement diagnostic lacks the next step"
[[ "$missing_output" != *$'\033['* ]] \
    || fail "redirected diagnostics contain ANSI color sequences"

timeout() {
    return 124
}
PUNCHI_CMAKE_RESTART_TIMEOUT=1
RESTART_TIMEOUT=1
set +e
restart_timeout_output="$(restart_plasma_shell_bounded 2>&1)"
restart_timeout_status=$?
set -e
[[ "$restart_timeout_status" == "1" ]] \
    || fail "a timed-out Plasma restart did not return a controlled failure"
[[ "$restart_timeout_output" == *"timed out after 1 seconds"* ]] \
    || fail "a timed-out Plasma restart lacked a bounded-wait diagnostic"

menu_output="$(
    printf '7\n' | LC_ALL=C.UTF-8 LANGUAGE=en PUNCHI_LANG=en bash -c '
        source "$1"
        punchi_prepare_setup_localization "$2"
        interactive_menu
    ' bash "$CMAKE_SETUP" "$PROJECT_ROOT"
)"
[[ "$menu_output" == *"CMake assistant menu:"* ]] \
    || fail "the interactive menu is unavailable"
[[ "$menu_output" == *"Configure, build, and install"* ]] \
    || fail "the interactive menu lacks the combined workflow"
[[ "$menu_output" == *"Restart Plasma Shell"* ]] \
    || fail "the interactive menu lacks explicit Plasma restart control"
[[ "$menu_output" == *"Exiting the CMake assistant."* ]] \
    || fail "the interactive menu did not exit cleanly"

grep -q 'source .*setup-localization\.sh' "$CMAKE_SETUP" \
    || fail "the CMake assistant does not use shared localization"
grep -q 'source .*plasma-shell-control\.sh' "$CMAKE_SETUP" \
    || fail "the CMake assistant does not use shared Plasma control"
grep -q 'clean_stale_cache' "$CMAKE_SETUP" \
    || fail "the CMake assistant does not clean stale cache directories"

stale_test_dir="$(mktemp -d "${TMPDIR:-/tmp}/punchi-stale-test.XXXXXX")"
echo "CMAKE_HOME_DIRECTORY:INTERNAL=/some/other/path" > "$stale_test_dir/CMakeCache.txt"
BUILD_DIR="$stale_test_dir" clean_stale_cache
[[ ! -d "$stale_test_dir" ]] || fail "clean_stale_cache did not remove the stale cache directory"

if grep -Eq '(^|[[:space:]])(sudo|dnf|apt-get|pacman)([[:space:]]|$)' "$CMAKE_SETUP"; then
    fail "the CMake assistant contains a privileged or distribution package command"
fi

printf 'CMake setup assistant contract tests passed.\n'
