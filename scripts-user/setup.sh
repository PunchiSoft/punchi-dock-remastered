#!/usr/bin/env bash
# User-facing local build, packaging, installation, and setup assistant.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
BUILD_DIR="${BUILD_DIR:-}"
PLUGIN_ID="org.kde.plasma.punchi-dock-remastered"

# shellcheck source=lib/setup-localization.sh
source "$LIB_DIR/setup-localization.sh"
# shellcheck source=lib/plasma-shell-control.sh
source "$LIB_DIR/plasma-shell-control.sh"
# shellcheck source=lib/qtpaths-resolver.sh
source "$LIB_DIR/qtpaths-resolver.sh"
# shellcheck source=lib/build-concurrency.sh
source "$LIB_DIR/build-concurrency.sh"
# shellcheck source=lib/setup-terminal-ui.sh
source "$LIB_DIR/setup-terminal-ui.sh"

ACTION=""
ACTION_OPTION=""
NO_RESTART=0
AUTO_YES=0
TARGET_PACKAGE=""

show_help() {
    punchi_gettext_line 'Usage: scripts-user/setup.sh [options] [path/to/package.plasmoid]

Builds Punchi Dock Remastered for the current Linux system without running
developer tests, creates a local .plasmoid package, installs it, and manages
Plasma Shell integration.

If run without a primary action, it opens the interactive setup menu.

Primary actions (choose only one):
  --install         Build and install the plasmoid locally.
  --build-only      Build the local package without installing or restarting Plasma.
  --package         Alias for --build-only.
  --check-deps      Check system build dependencies for the current distribution.
  --uninstall       Uninstall the plasmoid from the local Plasma environment.
  --restart-plasma  Restart Plasma Shell on demand.

Modifiers:
  -j, --jobs N      Set the number of parallel build jobs (e.g. -j 1 for safe mode).
  --parallel N      Alias for --jobs.
  --no-restart      Skip restarting Plasma Shell after install or uninstall.
  -y, --yes         Automatically confirm a restart prompt.
  --lang CODE       Override the detected language (en, es, de, pt_BR).
  -h, --help        Show this help.

Passing a .plasmoid path installs that existing package without compiling the
source tree. Build dependencies are required only by actions that compile.

Developer validation is available separately through scripts-dev/setup.sh.'
}

message() {
    local key="$1"
    shift || true
    case "$key" in
        menu_title)      punchi_gettext_line 'What would you like to do?' ;;
        menu_primary)    punchi_ui_write_styled_line heading 1 "$(punchi_gettext 'Primary actions')" ;;
        menu_maintenance) punchi_ui_write_styled_line heading 1 "$(punchi_gettext 'Maintenance')" ;;
        menu_settings)   punchi_ui_write_styled_line heading 1 "$(punchi_gettext 'Settings and help')" ;;
        menu_opt1)       punchi_ui_write_styled_line success 1 "$(punchi_gettext '  [1] Build and install locally (Recommended)')" ;;
        menu_opt2)       punchi_gettext_line '  [2] Build .plasmoid package only (no install)' ;;
        menu_opt3)       punchi_gettext_line '  [3] Install an existing .plasmoid package' ;;
        menu_opt4)       punchi_gettext_line '  [4] Uninstall the plasmoid from this system' ;;
        menu_opt5)       punchi_gettext_line '  [5] Restart Plasma Shell only' ;;
        menu_opt6)       punchi_gettext_line '  [6] Configure build concurrency (Safe / Balanced / Custom)' ;;
        menu_opt7)       punchi_gettext_line '  [7] Check system build dependencies' ;;
        menu_opt8)       punchi_gettext_line '  [8] Help (show CLI options)' ;;
        menu_opt9)       punchi_gettext_line '  [9] Exit' ;;
        menu_prompt)     punchi_gettext 'Select an option [1-9]: ' ;;
        prompt_restart)  punchi_gettext 'Restart Plasma Shell now to apply the changes? [Y/n]: ' ;;
        prompt_uninstall_restart) punchi_gettext 'Restart Plasma Shell now to finish uninstalling? [Y/n]: ' ;;
        prompt_package)  punchi_gettext 'Enter the path to a .plasmoid package: ' ;;
        restart_skipped) punchi_gettext_line 'Plasma Shell restart skipped. Log out and back in or restart Plasma later.' ;;
        start_build)     punchi_gettext_line '==> Building the native QML module without developer tests...' ;;
        start_uninstall) punchi_gettext_line '==> Uninstalling Punchi Dock Remastered...' ;;
        uninstall_done)  punchi_gettext_line '==> Plasmoid uninstalled successfully.' ;;
        uninstall_none)  punchi_gettext_line 'Notice: No local installation was found.' ;;
        build_only_done) punchi_gettext_format 'Local package created without installation: %s\n' "${1:-}" ;;
        invalid_choice)  punchi_gettext_format "Error: Invalid menu option: '%s'\n" "${1:-}" >&2 ;;
        cancelled)       punchi_gettext_line 'Operation cancelled.' ;;
        *)               echo "Internal error: unknown message key: $key" >&2; return 2 ;;
    esac
}

die() {
    punchi_gettext_format 'Error: %s\n' "$*" >&2
    exit 1
}

resolve_data_root() {
    punchi_qt6_writable_data_root "$HOME/.local/share"
}

safe_label_component() {
    local value="${1:-unknown}"
    value="${value//[^[:alnum:]._-]/_}"
    printf '%s\n' "${value:-unknown}"
}

project_version() {
    awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json"
}

system_display_name() {
    local distribution_name="Linux"
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        distribution_name="${PRETTY_NAME:-${NAME:-${ID:-Linux}}}"
    fi
    punchi_ui_sanitize_text "$distribution_name"
}

show_setup_header() {
    local package_version=""
    local distribution_name=""
    local architecture=""
    local ram_display=""
    local cpu_cores=""
    local current_jobs=""
    local environment_line=""
    local resources_line=""

    package_version="$(project_version)"
    distribution_name="$(system_display_name)"
    architecture="$(uname -m)"
    ram_display="$(punchi_format_ram_display "$(punchi_detect_total_ram_mb)")"
    cpu_cores="$(punchi_detect_cpu_cores)"
    current_jobs="$(punchi_get_concurrency_level)"
    environment_line="$(punchi_gettext_format 'Version %s | %s | %s' \
        "${package_version:-unknown}" "$distribution_name" "$architecture")"
    resources_line="$(punchi_gettext_format 'RAM %s | CPU cores %s | Build jobs %s' \
        "$ram_display" "$cpu_cores" "$current_jobs")"

    punchi_ui_render_header 1 \
        "$(punchi_gettext 'Punchi Dock Remastered · Setup')" \
        "$environment_line" \
        "$resources_line"
}

local_platform_label() {
    local distribution_id="linux"
    local distribution_version=""

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        distribution_id="${ID:-linux}"
        distribution_version="${VERSION_ID:-}"
    fi

    local id_comp=""
    local ver_comp=""
    local arch_comp=""
    id_comp="$(safe_label_component "$distribution_id")"
    arch_comp="$(safe_label_component "$(uname -m)")"
    if [[ -n "$distribution_version" && "$distribution_version" != "unknown" ]]; then
        ver_comp="$(safe_label_component "$distribution_version")"
        printf '%s%s-%s\n' "$id_comp" "$ver_comp" "$arch_comp"
    else
        printf '%s-%s\n' "$id_comp" "$arch_comp"
    fi
}

resolve_user_build_dir() {
    local platform_label=""
    platform_label="$(local_platform_label)"
    printf '%s
' "${XDG_CACHE_HOME:-$HOME/.cache}/punchi-dock-remastered/user-local-${platform_label}"
}

punchi_detect_user_distro() {
    local distro_id="unknown"
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        distro_id="${ID:-$NAME}"
        distro_id="${distro_id:-unknown}"
    fi
    printf '%s
' "$distro_id" | tr '[:upper:]' '[:lower:]'
}

punchi_user_missing_dependencies() {
    local distro_id=""
    distro_id="$(punchi_detect_user_distro)"
    local -a missing=()

    case "$distro_id" in
        *arch*|*manjaro*|*endeavouros*|*garuda*|*artix*)
            local -a arch_pkgs=(
                base-devel
                cmake
                extra-cmake-modules
                qt6-base
                qt6-declarative
                qt6-shadertools
                plasma-workspace
                pipewire
                kconfig
                ki18n
                kio
                kservice
            )
            for pkg in "${arch_pkgs[@]}"; do
                if ! pacman -Qq "$pkg" >/dev/null 2>&1 && ! pacman -Qg "$pkg" >/dev/null 2>&1; then
                    missing+=("$pkg")
                fi
            done
            if (( ${#missing[@]} > 0 )); then
                printf 'distro:arch\n'
                printf '%s\n' "${missing[@]}"
            fi
            ;;
        *debian*|*ubuntu*|*kubuntu*|*pop*|*mint*)
            local -a deb_pkgs=(
                build-essential
                cmake
                extra-cmake-modules
                qt6-base-dev
                qt6-declarative-dev
                qt6-shader-baker
                libplasma-dev
                libpipewire-0.3-dev
                libkf6config-dev
                libkf6i18n-dev
                libkf6kio-dev
            )
            for pkg in "${deb_pkgs[@]}"; do
                if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -qx 'install ok installed'; then
                    missing+=("$pkg")
                fi
            done
            if (( ${#missing[@]} > 0 )); then
                printf 'distro:debian\n'
                printf '%s\n' "${missing[@]}"
            fi
            ;;
        *fedora*|*rhel*|*nobara*|*centos*)
            local -a fedora_pkgs=(
                gcc-c++
                cmake
                extra-cmake-modules
                qt6-qtbase-devel
                qt6-qtdeclarative-devel
                qt6-qtshadertools
                plasma-workspace-devel
                pipewire-devel
                kf6-kconfig-devel
                kf6-ki18n-devel
                kf6-kio-devel
            )
            for pkg in "${fedora_pkgs[@]}"; do
                if ! rpm -q "$pkg" >/dev/null 2>&1; then
                    missing+=("$pkg")
                fi
            done
            if (( ${#missing[@]} > 0 )); then
                printf 'distro:fedora\n'
                printf '%s\n' "${missing[@]}"
            fi
            ;;
    esac
}

punchi_check_and_report_dependencies() {
    local raw_output=()
    mapfile -t raw_output < <(punchi_user_missing_dependencies)

    if (( ${#raw_output[@]} == 0 )); then
        echo "==> All required build packages are already installed for your distribution." >&2
        return 0
    fi

    local distro_type="${raw_output[0]}"
    local missing_pkgs=("${raw_output[@]:1}")

    echo "==> Notice: Missing build dependencies detected:" >&2
    for pkg in "${missing_pkgs[@]}"; do
        echo "  - $pkg" >&2
    done
    echo "" >&2

    local install_cmd=""
    case "$distro_type" in
        distro:arch)
            install_cmd="sudo pacman -S --needed ${missing_pkgs[*]}"
            ;;
        distro:debian)
            install_cmd="sudo apt-get update && sudo apt-get install ${missing_pkgs[*]}"
            ;;
        distro:fedora)
            install_cmd="sudo dnf install ${missing_pkgs[*]}"
            ;;
    esac

    if [[ -n "$install_cmd" ]] && [[ -t 0 ]]; then
        echo "To install missing packages automatically with sudo:" >&2
        echo "  $install_cmd" >&2
        echo "" >&2
        local answer=""
        read -r -p "¿Deseas instalar las dependencias faltantes ahora con sudo? [S/n]: " answer || true
        case "${answer:-s}" in
            s|S|y|Y|si|Si|yes|Yes|"")
                echo "==> Installing build dependencies with sudo..." >&2
                if eval "$install_cmd"; then
                    echo "==> Dependencies successfully installed." >&2
                    return 0
                else
                    echo "Error: Failed to install dependencies." >&2
                    return 1
                fi
                ;;
            *)
                echo "Skipping automatic installation. Please install the packages manually." >&2
                ;;
        esac
    else
        echo "To install the missing dependencies on your system, run:" >&2
        echo "  $install_cmd" >&2
        echo "" >&2
    fi
}

required_commands_for_action() {
    local action="$1"
    case "$action" in
        build_only)
            printf '%s\n' cmake c++ msgfmt pkg-config readelf strip unzip zip
            ;;
        install)
            printf '%s\n' cmake c++ msgfmt pkg-config readelf strip unzip zip kpackagetool6
            ;;
        install_package)
            printf '%s\n' kpackagetool6
            ;;
        uninstall|restart_plasma|check_deps)
            ;;
        *)
            die "unsupported action for dependency resolution: $action"
            ;;
    esac
}

require_action_commands() {
    local action="$1"
    local command_name=""
    local -a missing=()
    local -a required=()

    mapfile -t required < <(required_commands_for_action "$action")
    for command_name in "${required[@]}"; do
        command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
    done

    if (( ${#missing[@]} > 0 )); then
        printf 'Commands required for %s are missing:\n' "$action" >&2
        printf '  - %s\n' "${missing[@]}" >&2
        return 1
    fi
}

do_build_package() {
    local check_dependencies="${1:-1}"
    local package_version=""
    local platform_label=""
    local package_file=""
    local target_build_dir=""

    package_version="$(project_version)"
    [[ -n "$package_version" ]] || die "the package version could not be read from metadata.json"

    platform_label="$(local_platform_label)"
    package_file="$PROJECT_ROOT/dist/punchi-dock-remastered-${package_version}-${platform_label}-local-build.plasmoid"
    target_build_dir="$(resolve_user_build_dir)"

    # Sanity check: if CMakeCache.txt belongs to another directory or contains invalid tool paths, clear target_build_dir
    if [[ -f "$target_build_dir/CMakeCache.txt" ]]; then
        local cached_src=""
        cached_src="$(grep '^CMAKE_HOME_DIRECTORY:' "$target_build_dir/CMakeCache.txt" | cut -d'=' -f2 || true)"
        if [[ "$cached_src" != "$PROJECT_ROOT" ]]; then
            rm -rf "$target_build_dir"
            echo "==> Stale CMake cache cleared: $target_build_dir" >&2
        fi
    fi

    if (( check_dependencies == 1 )); then
        punchi_check_and_report_dependencies || true
    fi

    message start_build >&2
    printf 'Package output: %s

' "${package_file#"$PROJECT_ROOT/"}" >&2

    env \
        PUNCHI_PACKAGE_CORE=1 \
        PUNCHI_PACKAGE_VALIDATION_MODE=minimal \
        BUILD_DIR="$target_build_dir" \
        PACKAGE_BUILD_TYPE=Release \
        PACKAGE_OUTPUT_FILE="$package_file" \
        "$LIB_DIR/package-plasmoid.sh" >&2

    [[ -f "$package_file" ]] || die "the build completed without creating the expected package: $package_file"
    printf '%s
' "$package_file"
}

run_build_package_flow() {
    local package_file=""
    local platform_detail=""
    local package_detail=""
    local total=3

    platform_detail="$(system_display_name) | $(uname -m)"
    punchi_ui_render_phase 2 1 "$total" success \
        "$(punchi_gettext 'Environment')" \
        "$(punchi_gettext 'Completed')" \
        "$platform_detail"

    punchi_ui_render_phase 2 2 "$total" active \
        "$(punchi_gettext 'Dependency check')" \
        "$(punchi_gettext 'In progress')"
    if punchi_check_and_report_dependencies; then
        punchi_ui_render_phase 2 2 "$total" success \
            "$(punchi_gettext 'Dependency check')" \
            "$(punchi_gettext 'Reviewed')"
    else
        punchi_ui_render_phase 2 2 "$total" warning \
            "$(punchi_gettext 'Dependency check')" \
            "$(punchi_gettext 'Needs attention')"
    fi

    punchi_ui_render_phase 2 3 "$total" active \
        "$(punchi_gettext 'Build package')" \
        "$(punchi_gettext 'In progress')"
    package_file="$(do_build_package 0)"
    package_detail="${package_file#"$PROJECT_ROOT/"}"
    punchi_ui_render_phase 2 3 "$total" success \
        "$(punchi_gettext 'Build package')" \
        "$(punchi_gettext 'Completed')" \
        "$package_detail"

    printf '%s\n' "$package_file"
}

ask_restart_plasma() {
    local prompt_key="${1:-prompt_restart}"
    local answer=""

    if (( NO_RESTART == 1 )); then
        message restart_skipped
        return 0
    fi
    if (( AUTO_YES == 1 )); then
        punchi_restart_plasma_shell
        return
    fi

    message "$prompt_key"
    read -r answer || true
    case "$answer" in
        [yY]|[sS]|[jJ]|""|[yY][eE][sS]|[sS][iI][mM]|[jJ][aA])
            punchi_restart_plasma_shell
            ;;
        *)
            message restart_skipped
            ;;
    esac
}

do_install_package() {
    local package_file="$1"
    local prompt_for_restart="${2:-1}"

    [[ -f "$package_file" ]] || die "package file not found: $package_file"

    if (( NO_RESTART == 1 || prompt_for_restart == 1 )); then
        "$SCRIPT_DIR/setup-universal.sh" --no-restart "$package_file"
        if (( prompt_for_restart == 1 )); then
            echo ""
            ask_restart_plasma prompt_restart
        fi
    else
        "$SCRIPT_DIR/setup-universal.sh" "$package_file"
    fi
}

do_uninstall() {
    local prompt_for_restart="${1:-1}"
    local data_root=""
    local install_dir=""
    local removed=0

    data_root="$(resolve_data_root)"
    [[ -n "$data_root" && "$data_root" != "/" ]] || die "could not resolve a safe user data directory"
    install_dir="$data_root/plasma/plasmoids/$PLUGIN_ID"

    message start_uninstall
    if command -v kpackagetool6 >/dev/null 2>&1 \
        && kpackagetool6 --type Plasma/Applet -r "$PLUGIN_ID" 2>/dev/null; then
        removed=1
    fi

    if [[ -d "$install_dir" ]]; then
        [[ "$install_dir" == "$data_root/plasma/plasmoids/$PLUGIN_ID" ]] \
            || die "refusing to remove an unexpected installation path: $install_dir"
        rm -rf -- "$install_dir"
        removed=1
    fi

    if (( removed == 0 )); then
        message uninstall_none
        return 0
    fi

    message uninstall_done
    echo ""
    if (( prompt_for_restart == 1 )); then
        ask_restart_plasma prompt_uninstall_restart
    elif (( AUTO_YES == 1 && NO_RESTART == 0 )); then
        punchi_restart_plasma_shell
    else
        message restart_skipped
    fi
}

set_primary_action() {
    local action="$1"
    local option="$2"

    if [[ -n "$ACTION" ]]; then
        die "primary actions cannot be combined: $ACTION_OPTION and $option"
    fi
    ACTION="$action"
    ACTION_OPTION="$option"
}

parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            --install)
                set_primary_action install "$1"
                shift
                ;;
            --build-only|--package)
                set_primary_action build_only "$1"
                shift
                ;;
            --check-deps)
                set_primary_action check_deps "$1"
                shift
                ;;
            --uninstall)
                set_primary_action uninstall "$1"
                shift
                ;;
            --restart-plasma)
                set_primary_action restart_plasma "$1"
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
            --lang)
                shift 2
                ;;
            --lang=*)
                shift
                ;;
            -j|--jobs|--parallel)
                (( $# >= 2 )) || die "$1 requires a positive integer argument"
                punchi_set_concurrency_level "$2" || die "invalid number of parallel jobs: $2"
                shift 2
                ;;
            -j=*|--jobs=*|--parallel=*)
                punchi_set_concurrency_level "${1#*=}" || die "invalid number of parallel jobs: ${1#*=}"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *.plasmoid)
                set_primary_action install_package "$1"
                TARGET_PACKAGE="$1"
                shift
                ;;
            *)
                show_help >&2
                die "unknown option: $1"
                ;;
        esac
    done

    if [[ "$ACTION" == "restart_plasma" && "$NO_RESTART" == "1" ]]; then
        die "--restart-plasma cannot be combined with --no-restart"
    fi
}

interactive_menu() {
    local choice=""
    local package_file=""
    local target_package=""

    while true; do
        echo ""
        show_setup_header
        echo ""
        message menu_title
        echo ""
        message menu_primary
        message menu_opt1
        message menu_opt2
        message menu_opt3
        echo ""
        message menu_maintenance
        message menu_opt4
        message menu_opt5
        echo ""
        message menu_settings
        message menu_opt6
        message menu_opt7
        message menu_opt8
        message menu_opt9
        echo ""
        message menu_prompt

        read -r choice || break
        case "$choice" in
            1)
                require_action_commands install
                package_file="$(run_build_package_flow)"
                do_install_package "$package_file" 1
                break
                ;;
            2)
                require_action_commands build_only
                package_file="$(run_build_package_flow)"
                echo ""
                message build_only_done "$package_file"
                break
                ;;
            3)
                message prompt_package
                read -r target_package || break
                require_action_commands install_package
                if [[ -n "$target_package" ]]; then
                    do_install_package "$target_package" 1
                else
                    "$SCRIPT_DIR/setup-universal.sh" --no-restart
                    echo ""
                    ask_restart_plasma prompt_restart
                fi
                break
                ;;
            4)
                do_uninstall 1
                break
                ;;
            5)
                punchi_restart_plasma_shell
                break
                ;;
            6)
                punchi_configure_build_concurrency_interactive
                ;;
            7)
                echo ""
                punchi_check_and_report_dependencies
                ;;
            8)
                echo ""
                show_help
                ;;
            9|[qQ])
                message cancelled
                break
                ;;
            *)
                message invalid_choice "$choice"
                ;;
        esac
    done
}

main() {
    local package_file=""

    punchi_scan_setup_language_option "$@" || exit 1
    punchi_prepare_setup_localization "$PROJECT_ROOT"
    parse_args "$@"
    (( EUID != 0 )) || die "run this script as the Plasma desktop user, not with sudo"

    if [[ -z "$ACTION" ]]; then
        interactive_menu
        return 0
    fi

    show_setup_header
    echo ""
    require_action_commands "$ACTION"
    case "$ACTION" in
        build_only)
            package_file="$(run_build_package_flow)"
            echo ""
            message build_only_done "$package_file"
            ;;
        install)
            package_file="$(run_build_package_flow)"
            do_install_package "$package_file" 0
            ;;
        check_deps)
            punchi_check_and_report_dependencies
            ;;
        install_package)
            do_install_package "$TARGET_PACKAGE" 0
            ;;
        uninstall)
            do_uninstall 1
            ;;
        restart_plasma)
            punchi_restart_plasma_shell
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
