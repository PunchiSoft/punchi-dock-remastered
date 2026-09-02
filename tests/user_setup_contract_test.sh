#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLIC_SETUP="$PROJECT_ROOT/scripts-user/setup.sh"
PACKAGE_ENGINE="$PROJECT_ROOT/scripts-user/lib/package-plasmoid.sh"
PLASMA_CONTROL="$PROJECT_ROOT/scripts-user/lib/plasma-shell-control.sh"
QTPATHS_RESOLVER="$PROJECT_ROOT/scripts-user/lib/qtpaths-resolver.sh"
TERMINAL_UI="$PROJECT_ROOT/scripts-user/lib/setup-terminal-ui.sh"
UNIVERSAL_SETUP="$PROJECT_ROOT/scripts-user/setup-universal.sh"
DEVELOPER_SETUP="$PROJECT_ROOT/scripts-dev/setup.sh"
unset PUNCHI_LANG PUNCHI_SETUP_LANG_OVERRIDE 2>/dev/null || true

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

help_output="$(LC_ALL=C.UTF-8 LANGUAGE=en PUNCHI_LANG=en "$PUBLIC_SETUP" --lang en --help)"
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
grep -q 'PUNCHI_PACKAGE_VALIDATION_MODE=full' \
    "$PROJECT_ROOT/scripts-dev/distro/arch-package.sh" \
    || fail "the Arch developer package does not select full validation"
grep -q 'qmllint-baseline-arch.env' \
    "$PROJECT_ROOT/scripts-dev/distro/arch-package.sh" \
    || fail "the Arch developer package does not select its own qmllint baseline"
grep -q 'package_arch//\[\^a-zA-Z0-9\._-\]/_' \
    "$PROJECT_ROOT/scripts-dev/distro/arch-package.sh" \
    || fail "the Arch artifact architecture label is not sanitized"
grep -q 'arch-setup.sh' "$DEVELOPER_SETUP" \
    || fail "the developer setup does not dispatch to the Arch profile"
grep -q 'arch-package.sh' "$PACKAGE_ENGINE" \
    || fail "the package engine does not dispatch Arch-family hosts"
[[ -x "$DEVELOPER_SETUP" ]] || fail "the developer setup is not executable"
grep -q 'source .*setup-localization\.sh' "$DEVELOPER_SETUP" \
    || fail "the developer setup does not use the shared localization helper"
if grep -Eq '^(msg_es|msg_en|_detect_lang)\(\)' "$DEVELOPER_SETUP"; then
    fail "the developer setup still contains an inline language catalog"
fi
(( $(grep -c 'punchi_prepare_setup_localization' "$DEVELOPER_SETUP") >= 2 )) \
    || fail "the developer setup does not restore localization after a clean build"
grep -q 'source .*plasma-shell-control\.sh' "$PUBLIC_SETUP" \
    || fail "the public setup does not use the shared Plasma controller"
grep -q 'source .*plasma-shell-control\.sh' "$UNIVERSAL_SETUP" \
    || fail "the package installer does not use the shared Plasma controller"
if grep -Eq '^(do_restart_plasma|restart_plasma_shell)\(\)' \
        "$PUBLIC_SETUP" "$UNIVERSAL_SETUP"; then
    fail "a public entry point duplicates Plasma restart logic"
fi
[[ -r "$PLASMA_CONTROL" ]] || fail "the shared Plasma controller is missing"
[[ -r "$QTPATHS_RESOLVER" ]] || fail "the shared Qt 6 qtpaths resolver is missing"
BUILD_CONCURRENCY="$PROJECT_ROOT/scripts-user/lib/build-concurrency.sh"
[[ -r "$BUILD_CONCURRENCY" ]] || fail "the shared build concurrency helper is missing"
[[ -r "$TERMINAL_UI" ]] || fail "the public setup terminal UI helper is missing"
grep -q 'source .*setup-terminal-ui\.sh' "$PUBLIC_SETUP" \
    || fail "the public setup does not use the shared terminal UI helper"
for qtpaths_consumer in \
    "$PUBLIC_SETUP" \
    "$UNIVERSAL_SETUP" \
    "$DEVELOPER_SETUP" \
    "$PROJECT_ROOT/scripts-dev/lib/install-local-test.sh" \
    "$PROJECT_ROOT/scripts-dev/instalar-plasmoide.sh"; do
    grep -q 'source .*qtpaths-resolver\.sh' "$qtpaths_consumer" \
        || fail "a setup entry point does not use the shared Qt 6 resolver: $qtpaths_consumer"
    if grep -Eq '(^|[[:space:]"$])qtpaths6[[:space:]]+--writable-path' "$qtpaths_consumer"; then
        fail "a setup entry point still invokes qtpaths6 directly: $qtpaths_consumer"
    fi
done
for distro_setup in \
    "$PROJECT_ROOT/scripts-dev/distro/arch-setup.sh" \
    "$PROJECT_ROOT/scripts-dev/distro/debian13-setup.sh" \
    "$PROJECT_ROOT/scripts-dev/distro/fedora-setup.sh"; do
    grep -q 'punchi_find_qtpaths6' "$distro_setup" \
        || fail "a distribution profile still verifies only the bare qtpaths6 command: $distro_setup"
    grep -q 'source .*build-concurrency\.sh' "$distro_setup" \
        || fail "a distribution profile does not source the build concurrency helper: $distro_setup"
done

# shellcheck source=../scripts-user/setup.sh
source "$PUBLIC_SETUP"
[[ "$(safe_label_component 'fedora 44/x86')" == "fedora_44_x86" ]] \
    || fail "the local artifact label was not sanitized"
[[ "$(project_version)" == "$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json")" ]] \
    || fail "the setup header version does not follow metadata.json"
[[ -n "$(system_display_name)" ]] \
    || fail "the setup header did not detect a display name for the host system"

unset NO_COLOR
TERM=xterm-256color
punchi_ui_terminal_allows_color \
    || fail "a regular terminal type does not allow semantic setup colors"
NO_COLOR=""
if punchi_ui_terminal_allows_color; then
    fail "NO_COLOR does not disable semantic setup colors when set to an empty value"
fi
unset NO_COLOR
TERM=dumb
if punchi_ui_terminal_allows_color; then
    fail "TERM=dumb does not disable semantic setup colors"
fi
TERM=xterm-256color

unicode_ui_output="$({
    punchi_ui_terminal_supports_unicode() { return 0; }
    punchi_ui_terminal_supports_color() { return 1; }
    punchi_ui_render_header 1 \
        'Punchi Dock Remastered · Setup' \
        'Version 0.9.7.53 | Test Linux | test-arch' \
        'RAM 8.0 GiB | CPU cores 4 | Build jobs 2'
    punchi_ui_render_phase 1 1 3 success Environment Completed 'Test Linux | test-arch'
})"
[[ "$unicode_ui_output" == *"╭"* && "$unicode_ui_output" == *"Punchi Dock Remastered · Setup"* ]] \
    || fail "the interactive setup header does not render its Unicode frame"
[[ "$unicode_ui_output" == *"[1/3] ✓ Environment: Completed"* ]] \
    || fail "the setup phase output does not provide a non-color status label"
[[ "$unicode_ui_output" != *$'\033['* ]] \
    || fail "the forced colorless setup preview contains ANSI sequences"

build_flow_output="$({
    punchi_ui_terminal_supports_unicode() { return 0; }
    punchi_ui_terminal_supports_color() { return 1; }
    system_display_name() { printf 'Test Linux\n'; }
    uname() { printf 'test-arch\n'; }
    punchi_check_and_report_dependencies() { printf 'Dependencies inspected.\n' >&2; }
    do_build_package() { printf '%s/dist/test-package.plasmoid\n' "$PROJECT_ROOT"; }
    run_build_package_flow
} 2>&1)"
[[ "$build_flow_output" == *"[1/3] ✓ Environment: Completed — Test Linux | test-arch"* ]] \
    || fail "the build flow does not complete environment detection"
[[ "$build_flow_output" == *"[2/3] ● Dependency check: In progress"* \
    && "$build_flow_output" == *"[2/3] ✓ Dependency check: Reviewed"* ]] \
    || fail "the build flow does not expose the dependency check transition"
[[ "$build_flow_output" == *"[3/3] ● Build package: In progress"* \
    && "$build_flow_output" == *"[3/3] ✓ Build package: Completed — dist/test-package.plasmoid"* ]] \
    || fail "the build flow does not expose real package construction states"

warning_flow_output="$({
    punchi_ui_terminal_supports_unicode() { return 0; }
    punchi_ui_terminal_supports_color() { return 1; }
    system_display_name() { printf 'Test Linux\n'; }
    uname() { printf 'test-arch\n'; }
    punchi_check_and_report_dependencies() { return 1; }
    do_build_package() { printf '%s/dist/test-package.plasmoid\n' "$PROJECT_ROOT"; }
    run_build_package_flow
} 2>&1)"
[[ "$warning_flow_output" == *"[2/3] ! Dependency check: Needs attention"* ]] \
    || fail "the build flow does not expose a non-color dependency warning"

filtered_developer_args=()
punchi_filter_setup_language_options filtered_developer_args \
    --lang es --dry-run --dependencies-only
[[ "${filtered_developer_args[*]}" == "--dry-run --dependencies-only" ]] \
    || fail "the global language option would be forwarded to a distribution profile"

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

developer_help="$(LC_ALL=C.UTF-8 LANGUAGE=en PUNCHI_LANG=en "$DEVELOPER_SETUP" --lang en --help)"
[[ "$developer_help" == *"Master interactive and CLI assistant"* ]] \
    || fail "the developer help is unavailable in English"
[[ "$developer_help" == *"--lang CODE"* ]] \
    || fail "the developer help does not document the language override"
developer_spanish_help="$(LC_ALL=C.UTF-8 LANGUAGE=en "$DEVELOPER_SETUP" --lang es --help)"
[[ "$developer_spanish_help" == *"Opciones CLI"* ]] \
    || fail "the developer setup did not honor the Spanish language override"
developer_german_help="$(LC_ALL=C.UTF-8 LANGUAGE=en "$DEVELOPER_SETUP" --lang de --help)"
[[ "$developer_german_help" == *"CLI-Optionen"* ]] \
    || fail "the developer setup did not honor the German language override"
developer_portuguese_help="$(LC_ALL=C.UTF-8 LANGUAGE=en "$DEVELOPER_SETUP" --lang pt_BR --help)"
[[ "$developer_portuguese_help" == *"Opções da CLI"* ]] \
    || fail "the developer setup did not honor the Brazilian Portuguese language override"
developer_environment_help="$(LC_ALL=C.UTF-8 LANGUAGE=en PUNCHI_LANG=de "$DEVELOPER_SETUP" --help)"
[[ "$developer_environment_help" == *"CLI-Optionen"* ]] \
    || fail "the developer setup did not honor PUNCHI_LANG"
arch_spanish_help="$(LC_ALL=C.UTF-8 LANGUAGE=en PUNCHI_LANG=es \
    "$PROJECT_ROOT/scripts-dev/distro/arch-setup.sh" --help)"
[[ "$arch_spanish_help" == *"Pasa --noconfirm a pacman"* ]] \
    || fail "the Arch profile help did not honor the selected setup language"

set +e
developer_language_output="$("$DEVELOPER_SETUP" --lang xx --help 2>&1)"
developer_language_status=$?
set -e
[[ "$developer_language_status" == "1" \
    && "$developer_language_output" == *"unsupported language code"* ]] \
    || fail "the developer setup accepted an unsupported language override"

spanish_help=""
if locale -a 2>/dev/null | grep -qi 'es_ES'; then
    spanish_help="$(PUNCHI_LANG= LC_ALL=es_ES.UTF-8 LANGUAGE= "$PUBLIC_SETUP" --help)"
    [[ "$spanish_help" == *"Compila Punchi Dock Remastered"* ]] \
        || fail "es_ES was not detected automatically"
fi
spanish_override_help="$(LC_ALL=C.UTF-8 LANGUAGE=es "$PUBLIC_SETUP" --lang es --help)"
[[ "$spanish_override_help" == *"Acciones principales"* ]] \
    || fail "the explicit Spanish language override was not honored"
german_help=""
if locale -a 2>/dev/null | grep -qi 'de_DE'; then
    german_help="$(PUNCHI_LANG= LC_ALL=de_DE.UTF-8 LANGUAGE= "$PUBLIC_SETUP" --help)"
    [[ "$german_help" == *"Hauptaktionen"* ]] \
        || fail "de_DE was not detected automatically"
fi
portuguese_help=""
if locale -a 2>/dev/null | grep -qi 'pt_BR'; then
    portuguese_help="$(PUNCHI_LANG= LC_ALL=pt_BR.UTF-8 LANGUAGE= "$PUBLIC_SETUP" --help)"
    [[ "$portuguese_help" == *"Ações principales"* || "$portuguese_help" == *"Ações principais"* ]] \
        || fail "pt_BR was not detected automatically"
fi

menu_output="$(printf '9\n' | LC_ALL=C.UTF-8 LANGUAGE=en PUNCHI_LANG=en "$PUBLIC_SETUP" --lang en)"
[[ "$menu_output" == *"What would you like to do?"* ]] \
    || fail "the default interactive menu did not open"
[[ "$menu_output" == *"Punchi Dock Remastered - Setup"* ]] \
    || fail "the redirected setup menu does not provide a plain-text title"
[[ "$menu_output" == *"Version $(project_version)"* && "$menu_output" == *"$(uname -m)"* ]] \
    || fail "the setup header does not report the current version and architecture"
[[ "$menu_output" == *"Primary actions"* \
    && "$menu_output" == *"Maintenance"* \
    && "$menu_output" == *"Settings and help"* \
    && "$menu_output" == *"(Recommended)"* ]] \
    || fail "the public menu does not expose the approved visual hierarchy"
[[ "$menu_output" != *$'\033['* ]] \
    || fail "redirected setup menu output contains ANSI color sequences"

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
