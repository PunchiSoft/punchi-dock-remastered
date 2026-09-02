#!/usr/bin/env bash
# Interactive assistant for the standard per-user CMake workflow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLIC_LIB_DIR="$PROJECT_ROOT/scripts-user/lib"
BUILD_DIR="${PUNCHI_CMAKE_BUILD_DIR:-$PROJECT_ROOT/build-cmake-user}"
INSTALL_PREFIX="${PUNCHI_CMAKE_INSTALL_PREFIX:-${HOME:?}/.local}"
JOBS="${PUNCHI_CMAKE_JOBS:-1}"
RESTART_TIMEOUT="${PUNCHI_CMAKE_RESTART_TIMEOUT:-15}"
ACTION=""
NO_RESTART=0
AUTO_YES=0

PUNCHI_ANSI_RESET=$'\033[0m'
PUNCHI_ANSI_BOLD=$'\033[1m'
PUNCHI_ANSI_CYAN=$'\033[36m'
PUNCHI_ANSI_GREEN=$'\033[32m'
PUNCHI_ANSI_YELLOW=$'\033[33m'
PUNCHI_ANSI_RED=$'\033[31m'

# shellcheck source=../scripts-user/lib/setup-localization.sh
source "$PUBLIC_LIB_DIR/setup-localization.sh"
# shellcheck source=../scripts-user/lib/plasma-shell-control.sh
source "$PUBLIC_LIB_DIR/plasma-shell-control.sh"

punchi_terminal_allows_color() {
    [[ -z "${NO_COLOR+x}" && "${TERM:-}" != "dumb" ]]
}

punchi_terminal_supports_color() {
    local descriptor="${1:?file descriptor is required}"
    [[ "$descriptor" =~ ^[0-9]+$ ]] || return 2
    punchi_terminal_allows_color && [[ -t "$descriptor" ]]
}

punchi_terminal_style_code() {
    case "${1:?terminal style is required}" in
        heading) printf '%s%s' "$PUNCHI_ANSI_BOLD" "$PUNCHI_ANSI_CYAN" ;;
        info) printf '%s' "$PUNCHI_ANSI_CYAN" ;;
        success) printf '%s' "$PUNCHI_ANSI_GREEN" ;;
        warning) printf '%s%s' "$PUNCHI_ANSI_BOLD" "$PUNCHI_ANSI_YELLOW" ;;
        error) printf '%s%s' "$PUNCHI_ANSI_BOLD" "$PUNCHI_ANSI_RED" ;;
        *) return 2 ;;
    esac
}

# Keep the brace on the next line so xgettext does not parse this declaration
# as a call to the translation keyword with the third argument set to "{".
punchi_gettext_styled_line()
{
    local style="${1:?terminal style is required}"
    local descriptor="${2:?file descriptor is required}"
    local source_text="${3:?source text is required}"
    local translated_text=""
    local style_code=""

    translated_text="$(punchi_gettext "$source_text")"
    if punchi_terminal_supports_color "$descriptor"; then
        style_code="$(punchi_terminal_style_code "$style")" || return
        printf '%s%s%s\n' \
            "$style_code" "$translated_text" "$PUNCHI_ANSI_RESET" >&"$descriptor"
    else
        printf '%s\n' "$translated_text" >&"$descriptor"
    fi
}

punchi_gettext_styled_format()
{
    local style="${1:?terminal style is required}"
    local descriptor="${2:?file descriptor is required}"
    local source_format="${3:?source format is required}"
    shift 3
    local translated_format=""
    local rendered_text=""
    local style_code=""

    translated_format="$(punchi_gettext "$source_format")"
    printf -v rendered_text -- "$translated_format" "$@"
    if punchi_terminal_supports_color "$descriptor"; then
        style_code="$(punchi_terminal_style_code "$style")" || return
        printf '%s%s%s' \
            "$style_code" "$rendered_text" "$PUNCHI_ANSI_RESET" >&"$descriptor"
    else
        printf '%s' "$rendered_text" >&"$descriptor"
    fi
}

show_help() {
    punchi_gettext_line 'Usage: scripts-cmake/setup.sh [action] [options]

Checks the native build requirements, configures CMake for a per-user prefix,
and provides an interactive menu when no action is specified.

Actions (choose only one):
  --check             Check tools and configure CMake without compiling.
  --build             Configure and compile the native module.
  --install           Install the current compiled build for this user.
  --build-install     Configure, compile, and install for this user.
  --inspect           Inspect the configured installation in temporary staging.
  --restart-plasma    Restart Plasma Shell without compiling or installing.

Options:
  -j, --jobs N        Number of parallel build jobs (default: 1).
  --no-restart        Do not ask to restart Plasma Shell after installation.
  -y, --yes           Restart Plasma Shell after installation without prompting.
  --lang CODE         Select en, es, de, or pt_BR for assistant messages.
  -h, --help          Show this help.

This assistant does not install system packages, use a package manager, create
a .plasmoid artifact, or run the developer validation suite.'
}

die() {
    punchi_gettext_styled_format error 2 'Error: %s\n' "$*"
    exit 1
}

set_action() {
    local requested="$1"
    local option="$2"
    if [[ -n "$ACTION" ]]; then
        die "$(punchi_gettext_format '%s cannot be combined with another action.' "$option")"
    fi
    ACTION="$requested"
}

parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            --check)
                set_action check "$1"
                shift
                ;;
            --build)
                set_action build "$1"
                shift
                ;;
            --install)
                set_action install "$1"
                shift
                ;;
            --build-install)
                set_action build_install "$1"
                shift
                ;;
            --inspect)
                set_action inspect "$1"
                shift
                ;;
            --restart-plasma)
                set_action restart_plasma "$1"
                shift
                ;;
            -j|--jobs)
                (( $# >= 2 )) || die "$(punchi_gettext 'the jobs option requires a positive integer')"
                JOBS="$2"
                shift 2
                ;;
            --jobs=*)
                JOBS="${1#*=}"
                shift
                ;;
            --no-restart)
                NO_RESTART=1
                shift
                ;;
            -y|--yes)
                AUTO_YES=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                die "$(punchi_gettext_format 'unknown option: %s' "$1")"
                ;;
        esac
    done

    [[ "$JOBS" =~ ^[1-9][0-9]*$ ]] \
        || die "$(punchi_gettext 'the parallel job count must be a positive integer')"
    [[ "$RESTART_TIMEOUT" =~ ^[1-9][0-9]*$ ]] \
        || die "$(punchi_gettext 'the Plasma restart timeout must be a positive number of seconds')"
    [[ "$INSTALL_PREFIX" == /* && "$INSTALL_PREFIX" != "/" ]] \
        || die "$(punchi_gettext 'the per-user installation prefix must be an absolute path other than /')"
    if [[ "$NO_RESTART" == "1" && "$AUTO_YES" == "1" ]]; then
        die "$(punchi_gettext '--no-restart cannot be combined with --yes')"
    fi
}

show_requirements() {
    punchi_gettext_styled_line warning 1 'Before compiling Punchi Dock Remastered, this system needs:'
    punchi_gettext_line '  - CMake 3.22 or newer.'
    punchi_gettext_line '  - A C++20 compiler such as GCC or Clang.'
    punchi_gettext_line '  - Extra CMake Modules 6.0 or newer.'
    punchi_gettext_line '  - Qt 6.6 development files for Core, DBus, Gui, Qml, and Quick.'
    punchi_gettext_line '  - KDE Frameworks 6 development files for Config, CoreAddons, GlobalAccel, I18n, JobWidgets, KIO, Service, and WindowSystem.'
    punchi_gettext_line '  - Plasma 6 and LibKWorkspace development files.'
    punchi_gettext_line '  - PipeWire development files and pkg-config.'
    punchi_gettext_line '  - Qt Shader Baker (qsb) and Gettext tools.'
    punchi_gettext_styled_line warning 1 'Use the matching development packages supplied by your Linux distribution.'
}

find_shader_baker() {
    local candidate=""
    local -a candidates=(
        "${QSB_BIN:-}"
        qsb
        qsb-qt6
        /usr/lib/qt6/bin/qsb
        /usr/lib64/qt6/bin/qsb
    )
    for candidate in "${candidates[@]}"; do
        [[ -n "$candidate" ]] || continue
        if [[ "$candidate" == */* ]]; then
            [[ -x "$candidate" ]] && return 0
        elif command -v "$candidate" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

check_basic_requirements() {
    local compiler="${CXX:-c++}"
    local -a missing=()

    command -v cmake >/dev/null 2>&1 || missing+=(cmake)
    command -v "$compiler" >/dev/null 2>&1 || missing+=(compiler)
    command -v pkg-config >/dev/null 2>&1 || missing+=(pkg_config)
    command -v msgfmt >/dev/null 2>&1 || missing+=(msgfmt)
    command -v msgmerge >/dev/null 2>&1 || missing+=(msgmerge)
    command -v timeout >/dev/null 2>&1 || missing+=(timeout)
    find_shader_baker || missing+=(qsb)
    if command -v pkg-config >/dev/null 2>&1 \
        && ! pkg-config --exists libpipewire-0.3; then
        missing+=(pipewire)
    fi

    if (( ${#missing[@]} == 0 )); then
        punchi_gettext_styled_line success 1 'Basic build tools found. CMake will now verify the development libraries.'
        return 0
    fi

    punchi_gettext_styled_line error 2 'The following required tools or development files were not found:'
    local item=""
    for item in "${missing[@]}"; do
        case "$item" in
            cmake)      punchi_gettext_styled_line error 2 '  - CMake 3.22 or newer (cmake).' ;;
            compiler)   punchi_gettext_styled_line error 2 '  - A C++20 compiler (c++ or the compiler selected with CXX).' ;;
            pkg_config) punchi_gettext_styled_line error 2 '  - pkg-config.' ;;
            msgfmt)     punchi_gettext_styled_line error 2 '  - Gettext message compiler (msgfmt).' ;;
            msgmerge)   punchi_gettext_styled_line error 2 '  - Gettext catalog merger (msgmerge).' ;;
            timeout)    punchi_gettext_styled_line error 2 '  - The bounded command runner from GNU Coreutils (timeout).' ;;
            qsb)        punchi_gettext_styled_line error 2 '  - Qt Shader Baker (qsb).' ;;
            pipewire)   punchi_gettext_styled_line error 2 '  - PipeWire development metadata (libpipewire-0.3).' ;;
        esac
    done
    punchi_gettext_styled_line warning 2 'Install the missing development packages and run this assistant again.'
    return 1
}

clean_stale_cache() {
    if [[ -f "$BUILD_DIR/CMakeCache.txt" ]]; then
        local cached_src=""
        cached_src="$(grep '^CMAKE_HOME_DIRECTORY:' "$BUILD_DIR/CMakeCache.txt" | cut -d'=' -f2 || true)"
        if [[ -n "$cached_src" && "$cached_src" != "$PROJECT_ROOT" ]]; then
            rm -rf "$BUILD_DIR"
        fi
    fi
}

configure_project() {
    clean_stale_cache
    punchi_gettext_styled_format info 1 'Checking the complete CMake environment in: %s\n' "$BUILD_DIR"
    if ! cmake \
        -S "$PROJECT_ROOT" \
        -B "$BUILD_DIR" \
        -DBUILD_TESTING=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DPUNCHI_EMBED_QML_MODULE_IN_KPACKAGE=ON; then
        punchi_gettext_styled_line error 2 'CMake configuration failed. Install the development package named in the error above and run this assistant again.'
        return 1
    fi
    punchi_gettext_styled_line success 1 'All required build dependencies were accepted by CMake.'
}

prepare_build_environment() {
    show_requirements
    echo ""
    check_basic_requirements
    configure_project
}

build_project() {
    punchi_gettext_styled_format info 1 'Building with %s parallel job(s)...\n' "$JOBS"
    cmake --build "$BUILD_DIR" --parallel "$JOBS"
    punchi_gettext_styled_format success 1 'CMake build completed: %s\n' "$BUILD_DIR"
}

restart_plasma_shell_bounded() {
    local restart_status=0

    timeout \
        --foreground \
        --kill-after=2s \
        "${RESTART_TIMEOUT}s" \
        bash -c '
            source "$1"
            source "$2"
            punchi_prepare_setup_localization "$3"
            punchi_restart_plasma_shell
        ' bash \
        "$PUBLIC_LIB_DIR/setup-localization.sh" \
        "$PUBLIC_LIB_DIR/plasma-shell-control.sh" \
        "$PROJECT_ROOT" \
        || restart_status=$?

    if (( restart_status == 0 )); then
        return 0
    fi
    if (( restart_status == 124 || restart_status == 137 )); then
        punchi_gettext_styled_format warning 2 \
            'Plasma Shell restart timed out after %s seconds; continuing without waiting.\n' \
            "$RESTART_TIMEOUT"
        return 1
    fi
    punchi_gettext_styled_format error 2 \
        'Plasma Shell restart failed with status %s.\n' \
        "$restart_status"
    return "$restart_status"
}

ask_restart_plasma() {
    local answer=""
    if (( NO_RESTART == 1 )); then
        punchi_gettext_styled_line warning 1 'Plasma Shell restart skipped.'
        return 0
    fi
    if (( AUTO_YES == 1 )); then
        restart_plasma_shell_bounded
        return
    fi
    punchi_gettext_styled_format info 1 'Restart Plasma Shell now to load the installed build? [Y/n]: '
    read -r answer || true
    case "$answer" in
        [yY]|[sS]|[jJ]|""|[yY][eE][sS]|[sS][iI]|[jJ][aA])
            restart_plasma_shell_bounded
            ;;
        *)
            punchi_gettext_styled_line warning 1 'Plasma Shell restart skipped.'
            ;;
    esac
}

install_project() {
    if [[ ! -f "$BUILD_DIR/bin/libpunchidockintegration.so" ]]; then
        punchi_gettext_styled_line error 2 'No compiled native module was found. Build the project before installing it.'
        return 1
    fi
    punchi_gettext_styled_format info 1 'Installing the current build for this user under: %s\n' "$INSTALL_PREFIX"
    cmake --install "$BUILD_DIR"
    punchi_gettext_styled_line success 1 'CMake installation completed successfully.'
    ask_restart_plasma
}

inspect_project() {
    "$SCRIPT_DIR/inspect.sh" "$BUILD_DIR"
}

interactive_menu() {
    local choice=""
    while true; do
        echo ""
        punchi_gettext_styled_line heading 1 'CMake assistant menu:'
        punchi_gettext_line '  [1] Check requirements again'
        punchi_gettext_line '  [2] Configure and build'
        punchi_gettext_line '  [3] Install the current compiled build'
        punchi_gettext_line '  [4] Configure, build, and install'
        punchi_gettext_line '  [5] Inspect the installation in temporary staging'
        punchi_gettext_line '  [6] Restart Plasma Shell'
        punchi_gettext_line '  [7] Exit'
        punchi_gettext_styled_format info 1 'Select an option [1-7]: '
        read -r choice || choice="7"

        case "$choice" in
            1) prepare_build_environment || true ;;
            2) configure_project && build_project || true ;;
            3) install_project || true ;;
            4) configure_project && build_project && install_project || true ;;
            5) inspect_project || true ;;
            6) restart_plasma_shell_bounded || true ;;
            7) punchi_gettext_styled_line info 1 'Exiting the CMake assistant.'; return 0 ;;
            *) punchi_gettext_styled_line warning 2 'Invalid option. Select a number from 1 to 7.' ;;
        esac
    done
}

main() {
    local -a filtered_args=()
    punchi_scan_setup_language_option "$@" || exit 1
    punchi_prepare_setup_localization "$PROJECT_ROOT"
    punchi_filter_setup_language_options filtered_args "$@" || exit 1
    parse_args "${filtered_args[@]}"

    if [[ "$ACTION" == "restart_plasma" ]]; then
        restart_plasma_shell_bounded
        return
    fi

    prepare_build_environment
    case "$ACTION" in
        check) return 0 ;;
        build) build_project ;;
        install) install_project ;;
        build_install) build_project && install_project ;;
        inspect) inspect_project ;;
        "") interactive_menu ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
