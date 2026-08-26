#!/usr/bin/env bash
# Developer Setup, Build & Validation Assistant for Punchi Dock Remastered
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Cleanup handler: remove partial build staging on interruption (Ctrl+C, errors)
_punchi_setup_cleanup() {
    local exit_code=$?
    local package_root="$PROJECT_ROOT/build/package-root"
    if [[ -d "$package_root" && ! -f "$package_root/metadata.json" ]]; then
        echo ""
        echo "Cleaning up incomplete build staging directory: $package_root" >&2
        rm -rf "$package_root"
    fi
    exit "$exit_code"
}
trap _punchi_setup_cleanup EXIT INT TERM

# shellcheck source=lib/setup-logging.sh
source "$SCRIPT_DIR/lib/setup-logging.sh"

# ---------------------------------------------------------------------------
# Locale detection: English (default) and Spanish
# Override with PUNCHI_LANG=en or PUNCHI_LANG=es
# ---------------------------------------------------------------------------
_detect_lang() {
    if [[ -n "${PUNCHI_LANG:-}" ]]; then
        echo "$PUNCHI_LANG"
        return
    fi
    local locale="${LC_ALL:-${LC_MESSAGES:-${LANG:-en_US.UTF-8}}}"
    case "$locale" in
        es*|ES*) echo "es" ;;
        *)       echo "en" ;;
    esac
}

PUNCHI_UI_LANG="$(_detect_lang)"

# ---------------------------------------------------------------------------
# Bilingual message catalog
# ---------------------------------------------------------------------------
msg() {
    local key="$1"
    shift
    case "${PUNCHI_UI_LANG}" in
        es) msg_es "$key" "$@" ;;
        *)  msg_en "$key" "$@" ;;
    esac
}

msg_en() {
    local key="$1"
    shift
    case "$key" in
        help)
            cat <<'EOF'
Usage: scripts-dev/setup.sh [options | path_to_package.plasmoid]

Master interactive and CLI assistant for packaging, testing and installing
Punchi Dock Remastered. Automatically detects the host distribution
(Fedora or Debian 13).

If run without arguments, it opens the accessible interactive menu.

CLI Options:
  --local-test        Build, install on local Plasma Shell and collect logs.
  --clean-install     Remove existing installation, rebuild and install fresh.
  --yes               Pass affirmative answer to the package manager (DNF/APT).
  --skip-dnf          Skip DNF installation on Fedora.
  --skip-apt          Skip APT installation on Debian.
  --skip-update       Skip apt-get update on Debian.
  --dependencies-only Check and install dependencies without building.
  --uninstall         Remove the plasmoid from the local Plasma installation.
  --dry-run           Show planned commands without modifying the system.
  -h, --help          Show this help.

Examples:
  ./scripts-dev/setup.sh                            # Interactive menu mode
  ./scripts-dev/setup.sh --local-test               # Quick local test mode
  ./scripts-dev/setup.sh --clean-install            # Force clean reinstall
  ./scripts-dev/setup.sh dist/my-package.plasmoid   # Direct .plasmoid install
EOF
            ;;
        err_root)        echo "Error: Run this script as the Plasma desktop user, NOT with sudo." >&2
                         echo "The script will request sudo only when DNF or APT need to install packages." >&2 ;;
        err_no_osrel)    echo "Error: Could not identify the distribution from /etc/os-release." >&2 ;;
        err_unsup_deb)   echo "Error: Unsupported Debian version for building: ${1:-unknown}." >&2
                         echo "Supported build environments: Debian 13 (Trixie) or Fedora." >&2
                         echo "To install a prebuilt .plasmoid use: ./scripts-user/setup-universal.sh" >&2 ;;
        warn_unsup_dist) echo "Notice: This distribution (${1:-unknown}) is not an official C++ build environment." >&2
                         echo "Supported build environments: Fedora and Debian 13." >&2
                         echo "To install a prebuilt .plasmoid, use: ./scripts-user/setup-universal.sh" >&2 ;;
        err_no_profile)  echo "Error: Cannot build natively on this system (${1:-unknown})." >&2
                         echo "Use: ./scripts-user/setup-universal.sh <path/to/package.plasmoid> to install." >&2 ;;
        err_no_cli_prof) echo "Error: No build profile exists for the distribution: ${1:-unknown}." >&2 ;;
        banner)          echo "=========================================================="
                         echo "   Punchi Dock Remastered - Master Setup Assistant        "
                         echo "==========================================================" ;;
        detected_host)   echo "Detected host: ${1:-unknown} ($(uname -m))" ;;
        menu_question)   echo "What would you like to do?" ;;
        menu_opt1)       echo "  [1] Build official release package (Release in dist/)" ;;
        menu_opt2)       echo "  [2] Build, install and test locally (--local-test)" ;;
        menu_opt3)       echo "  [3] Install an existing .plasmoid package from dist/" ;;
        menu_opt4)       echo "  [4] Clean install (remove current + rebuild + install)" ;;
        menu_opt5)       echo "  [5] Check and install build dependencies only" ;;
        menu_opt6)       echo "  [6] Uninstall the plasmoid from this system" ;;
        menu_opt7)       echo "  [7] Help (show CLI commands reference)" ;;
        menu_opt8)       echo "  [8] Exit" ;;
        menu_prompt)     printf 'Select an option [1-8]: ' ;;
        start_release)   echo "==> Starting Release build..." ;;
        start_local)     echo "==> Starting build and local test..." ;;
        start_clean)     echo "==> Starting clean install (remove + rebuild + install)..." ;;
        start_deps)      echo "==> Checking and installing build dependencies..." ;;
        start_uninstall) echo "==> Uninstalling the plasmoid..." ;;
        uninstall_done)  echo "==> Plasmoid uninstalled successfully." ;;
        uninstall_none)  echo "Notice: No local installation found for the plasmoid." ;;
        clean_removed)   echo "==> Removed existing installation: ${1:-}" ;;
        start_plasma_restart) echo "==> Restarting Plasma Shell..." ;;
        restart_done)    echo "==> Plasma Shell restart requested." ;;
        prompt_restart)  printf 'Would you like to restart Plasma Shell now? [y/N]: ' ;;
        cancelled)       echo "Operation cancelled." ;;
        err_invalid_opt) echo "Error: Invalid option: '${1:-}'" >&2 ;;
        quick_ref)
            echo ""
            echo "CLI Quick Reference"
            echo "=================="
            echo "  ./scripts-dev/setup.sh                    Interactive menu (this screen)"
            echo "  ./scripts-dev/setup.sh --local-test       Build, install and test locally"
            echo "  ./scripts-dev/setup.sh --clean-install    Force remove + full rebuild + install"
            echo "  ./scripts-dev/setup.sh --dependencies-only  Check/install build dependencies"
            echo "  ./scripts-dev/setup.sh --uninstall        Remove the plasmoid from Plasma"
            echo "  ./scripts-dev/setup.sh --dry-run          Preview commands without executing"
            echo "  ./scripts-dev/setup.sh --yes              Auto-accept package manager prompts"
            echo "  ./scripts-dev/setup.sh --help             Show full help with all options"
            echo "  ./scripts-dev/setup.sh <file.plasmoid>    Install a prebuilt package directly"
            echo ""
            echo "Logs: docs/logs/<distro>/setup-<distro>-latest.log"
            echo "Docs: scripts-dev/README.md | scripts-dev/README.es.md"
            echo "" ;;
    esac
}

msg_es() {
    local key="$1"
    shift
    case "$key" in
        help)
            cat <<'EOF'
Uso: scripts-dev/setup.sh [opciones | ruta_al_paquete.plasmoid]

Asistente maestro interactivo y CLI para empaquetar, probar e instalar
Punchi Dock Remastered. Detecta automáticamente la distribución anfitriona
(Fedora o Debian 13).

Si se ejecuta sin argumentos, abre el menú interactivo accesible.

Opciones CLI:
  --local-test        Compila, instala en Plasma Shell local y recolecta logs.
  --clean-install     Elimina instalación existente, recompila e instala limpio.
  --yes               Pasa respuesta afirmativa al gestor de paquetes (DNF/APT).
  --skip-dnf          Omite instalación DNF en Fedora.
  --skip-apt          Omite instalación APT en Debian.
  --skip-update       Omite apt-get update en Debian.
  --dependencies-only Verifica e instala dependencias sin compilar.
  --uninstall         Desinstala el plasmoide de la instalación local de Plasma.
  --dry-run           Muestra los comandos planificados sin modificar el sistema.
  -h, --help          Muestra esta ayuda.

Ejemplos:
  ./scripts-dev/setup.sh                            # Modo menú interactivo
  ./scripts-dev/setup.sh --local-test               # Modo prueba rápida local
  ./scripts-dev/setup.sh --clean-install            # Reinstalación limpia forzada
  ./scripts-dev/setup.sh dist/mi-paquete.plasmoid  # Instalación directa de .plasmoid
EOF
            ;;
        err_root)        echo "Error: Ejecuta este script como el usuario de escritorio Plasma, NO con sudo." >&2
                         echo "El script solicitará sudo únicamente cuando DNF o APT requieran instalar paquetes." >&2 ;;
        err_no_osrel)    echo "Error: No se pudo identificar la distribución desde /etc/os-release." >&2 ;;
        err_unsup_deb)   echo "Error: Versión de Debian no soportada para compilación: ${1:-unknown}." >&2
                         echo "El entorno de compilación soportado es Debian 13 (Trixie) o Fedora." >&2
                         echo "Para instalar un .plasmoid ya precompilado usa: ./scripts-user/setup-universal.sh" >&2 ;;
        warn_unsup_dist) echo "Aviso: Esta distribución (${1:-unknown}) no es un entorno oficial de compilación C++." >&2
                         echo "Entornos de compilación soportados: Fedora y Debian 13." >&2
                         echo "Si deseas instalar un .plasmoid precompilado, usa: ./scripts-user/setup-universal.sh" >&2 ;;
        err_no_profile)  echo "Error: No se puede compilar nativamente en este sistema (${1:-unknown})." >&2
                         echo "Usa: ./scripts-user/setup-universal.sh <ruta/al/paquete.plasmoid> para instalar." >&2 ;;
        err_no_cli_prof) echo "Error: No existe perfil de compilación para la distribución: ${1:-unknown}." >&2 ;;
        banner)          echo "=========================================================="
                         echo "   Punchi Dock Remastered - Asistente Maestro de Setup    "
                         echo "==========================================================" ;;
        detected_host)   echo "Sistema detectado: ${1:-unknown} ($(uname -m))" ;;
        menu_question)   echo "¿Qué deseas hacer?" ;;
        menu_opt1)       echo "  [1] Compilar paquete de versión oficial (Release en dist/)" ;;
        menu_opt2)       echo "  [2] Compilar, instalar y probar localmente (--local-test)" ;;
        menu_opt3)       echo "  [3] Instalar un paquete .plasmoid ya existente desde dist/" ;;
        menu_opt4)       echo "  [4] Instalación limpia (eliminar actual + recompilar + instalar)" ;;
        menu_opt5)       echo "  [5] Verificar e instalar dependencias de compilación" ;;
        menu_opt6)       echo "  [6] Desinstalar el plasmoide de este sistema" ;;
        menu_opt7)       echo "  [7] Ayuda (ver referencia de comandos CLI)" ;;
        menu_opt8)       echo "  [8] Salir" ;;
        menu_prompt)     printf 'Selecciona una opción [1-8]: ' ;;
        start_release)   echo "==> Iniciando compilación de Release..." ;;
        start_local)     echo "==> Iniciando compilación y prueba local..." ;;
        start_clean)     echo "==> Iniciando instalación limpia (eliminar + recompilar + instalar)..." ;;
        start_deps)      echo "==> Verificando e instalando dependencias de compilación..." ;;
        start_uninstall) echo "==> Desinstalando el plasmoide..." ;;
        uninstall_done)  echo "==> Plasmoide desinstalado exitosamente." ;;
        uninstall_none)  echo "Aviso: No se encontró una instalación local del plasmoide." ;;
        clean_removed)   echo "==> Instalación existente eliminada: ${1:-}" ;;
        start_plasma_restart) echo "==> Reiniciando entorno Plasma Shell..." ;;
        restart_done)    echo "==> Reinicio de Plasma Shell solicitado." ;;
        prompt_restart)  printf '¿Deseas reiniciar Plasma Shell ahora? [s/N]: ' ;;
        cancelled)       echo "Operación cancelada." ;;
        err_invalid_opt) echo "Error: Opción no válida: '${1:-}'" >&2 ;;
        quick_ref)
            echo ""
            echo "Referencia Rápida de Comandos CLI"
            echo "=================================="
            echo "  ./scripts-dev/setup.sh                    Menú interactivo (esta pantalla)"
            echo "  ./scripts-dev/setup.sh --local-test       Compilar, instalar y probar localmente"
            echo "  ./scripts-dev/setup.sh --clean-install    Forzar eliminación + recompilar + instalar"
            echo "  ./scripts-dev/setup.sh --dependencies-only  Verificar/instalar dependencias"
            echo "  ./scripts-dev/setup.sh --uninstall        Desinstalar el plasmoide de Plasma"
            echo "  ./scripts-dev/setup.sh --dry-run          Previsualizar comandos sin ejecutar"
            echo "  ./scripts-dev/setup.sh --yes              Aceptar automáticamente gestor de paquetes"
            echo "  ./scripts-dev/setup.sh --help             Mostrar ayuda completa con todas las opciones"
            echo "  ./scripts-dev/setup.sh <archivo.plasmoid> Instalar un paquete precompilado directamente"
            echo ""
            echo "Logs: docs/logs/<distro>/setup-<distro>-latest.log"
            echo "Docs: scripts-dev/README.md | scripts-dev/README.es.md"
            echo "" ;;
    esac
}

# ---------------------------------------------------------------------------
# Helper: Resolve plasmoid install directory
# ---------------------------------------------------------------------------
_punchi_resolve_install_dir() {
    local plugin_id="org.kde.plasma.punchi-dock-remastered"
    local data_root=""
    data_root="$(qtpaths6 --writable-path GenericDataLocation 2>/dev/null || echo "$HOME/.local/share")"
    echo "$data_root/plasma/plasmoids/$plugin_id"
}

# ---------------------------------------------------------------------------
# Helper: Restart Plasma Shell
# ---------------------------------------------------------------------------
_punchi_restart_plasma() {
    msg start_plasma_restart
    local previous_pid=""
    local current_pid=""

    previous_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"

    if command -v systemctl >/dev/null 2>&1 \
        && systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
        systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
        sleep 1
        current_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
        if [[ -n "$previous_pid" && "$current_pid" == "$previous_pid" ]]; then
            if command -v kquitapp6 >/dev/null 2>&1; then
                kquitapp6 plasmashell >/dev/null 2>&1 || true
            else
                killall plasmashell >/dev/null 2>&1 || true
            fi
            sleep 0.5
            systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
        fi
    else
        if command -v kquitapp6 >/dev/null 2>&1; then
            kquitapp6 plasmashell >/dev/null 2>&1 || true
        else
            killall plasmashell >/dev/null 2>&1 || true
        fi
        sleep 1
        if command -v kstart6 >/dev/null 2>&1; then
            kstart6 plasmashell >/dev/null 2>&1 &
        elif command -v kstart >/dev/null 2>&1; then
            kstart plasmashell >/dev/null 2>&1 &
        else
            plasmashell >/dev/null 2>&1 &
        fi
    fi
    msg restart_done
}

# ---------------------------------------------------------------------------
# Helper: Uninstall the plasmoid
# ---------------------------------------------------------------------------
_punchi_uninstall() {
    local plugin_id="org.kde.plasma.punchi-dock-remastered"
    local install_dir=""
    install_dir="$(_punchi_resolve_install_dir)"
    local auto_restart="${1:-0}"

    msg start_uninstall

    if [[ -d "$install_dir" ]]; then
        kpackagetool6 --type Plasma/Applet -r "$plugin_id" 2>/dev/null || {
            echo "kpackagetool6 removal failed; removing directory manually" >&2
            rm -rf "$install_dir"
        }
        if [[ ! -d "$install_dir" ]]; then
            msg uninstall_done
        else
            echo "Error: Installation directory still exists after removal: $install_dir" >&2
            exit 1
        fi
    else
        msg uninstall_none
    fi

    if (( auto_restart == 1 )); then
        _punchi_restart_plasma
    elif (( $# == 0 )) || [[ "${interactive_mode:-0}" == "1" ]]; then
        echo ""
        read -rp "$(msg prompt_restart)" answer
        case "$answer" in
            [yY]|[sS]|[yY][eE][sS]|[sS][íI])
                _punchi_restart_plasma
                ;;
        esac
    fi
}

# ---------------------------------------------------------------------------
# Helper: Clean install (remove existing + rebuild + install)
# ---------------------------------------------------------------------------
_punchi_clean_install() {
    local install_dir=""
    install_dir="$(_punchi_resolve_install_dir)"

    # Step 1: Remove existing installation if present
    if [[ -d "$install_dir" ]]; then
        local plugin_id="org.kde.plasma.punchi-dock-remastered"
        kpackagetool6 --type Plasma/Applet -r "$plugin_id" 2>/dev/null || {
            rm -rf "$install_dir"
        }
        msg clean_removed "$install_dir"
    fi

    # Step 2: Clean the build directory to force a full recompilation
    local build_dir="$PROJECT_ROOT/build"
    if [[ -d "$build_dir" ]]; then
        rm -rf "$build_dir"
        echo "==> Build cache cleared: $build_dir"
    fi
    local xdg_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/punchi-dock-remastered"
    if [[ -d "$xdg_cache_dir" ]]; then
        rm -rf "$xdg_cache_dir"
        echo "==> XDG build cache cleared: $xdg_cache_dir"
    fi

    # Step 3: Rebuild and install via --local-test
    PUNCHI_LOG_DIR="${PUNCHI_LOG_DIR:-$PROJECT_ROOT/docs/logs/$DETECTED_PROFILE}"
    punchi_run_setup_with_log "$DETECTED_PROFILE" "$SETUP_EXEC" --local-test
}

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------
if (( EUID == 0 )); then
    msg err_root
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    msg err_no_osrel
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

DETECTED_PROFILE=""
SETUP_EXEC=""

case "${ID:-}" in
    fedora)
        DETECTED_PROFILE="fedora"
        SETUP_EXEC="$SCRIPT_DIR/distro/fedora-setup.sh"
        ;;
    debian)
        DETECTED_PROFILE="debian13"
        SETUP_EXEC="$SCRIPT_DIR/distro/debian13-setup.sh"
        ;;
    ubuntu|kubuntu|mint|pop)
        DETECTED_PROFILE="debian13"
        SETUP_EXEC="$SCRIPT_DIR/distro/debian13-setup.sh"
        ;;
    *)
        if [[ "${1:-}" != "-h" && "${1:-}" != "--help" && "${1:-}" != *.plasmoid ]]; then
            msg warn_unsup_dist "${PRETTY_NAME:-unknown}"
        fi
        ;;
esac

# ---------------------------------------------------------------------------
# 1. Help
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    msg help
    exit 0
fi

# ---------------------------------------------------------------------------
# 2. Direct .plasmoid file (Works on ANY distribution)
# ---------------------------------------------------------------------------
if [[ "${1:-}" == *.plasmoid ]]; then
    exec "$PROJECT_ROOT/scripts-user/setup-universal.sh" "$1"
fi

# ---------------------------------------------------------------------------
# 3. Interactive mode (no arguments)
# ---------------------------------------------------------------------------
if (( $# == 0 )); then
    interactive_mode=1
    msg banner
    msg detected_host "${PRETTY_NAME:-$ID}"
    echo ""
    msg menu_question
    msg menu_opt1
    msg menu_opt2
    msg menu_opt3
    msg menu_opt4
    msg menu_opt5
    msg menu_opt6
    msg menu_opt7
    msg menu_opt8
    echo ""
    read -rp "$(msg menu_prompt)" choice

    case "$choice" in
        1)
            if [[ -z "$DETECTED_PROFILE" ]]; then
                msg err_no_profile "${PRETTY_NAME:-unknown}"
                exit 1
            fi
            msg start_release
            PUNCHI_LOG_DIR="${PUNCHI_LOG_DIR:-$PROJECT_ROOT/docs/logs/$DETECTED_PROFILE}"
            punchi_run_setup_with_log "$DETECTED_PROFILE" "$SETUP_EXEC"
            ;;
        2)
            if [[ -z "$DETECTED_PROFILE" ]]; then
                msg err_no_profile "${PRETTY_NAME:-unknown}"
                exit 1
            fi
            msg start_local
            PUNCHI_LOG_DIR="${PUNCHI_LOG_DIR:-$PROJECT_ROOT/docs/logs/$DETECTED_PROFILE}"
            punchi_run_setup_with_log "$DETECTED_PROFILE" "$SETUP_EXEC" --local-test
            ;;
        3)
            exec "$SCRIPT_DIR/instalar-plasmoide.sh"
            ;;
        4)
            if [[ -z "$DETECTED_PROFILE" ]]; then
                msg err_no_profile "${PRETTY_NAME:-unknown}"
                exit 1
            fi
            msg start_clean
            _punchi_clean_install
            ;;
        5)
            if [[ -z "$DETECTED_PROFILE" ]]; then
                msg err_no_profile "${PRETTY_NAME:-unknown}"
                exit 1
            fi
            msg start_deps
            PUNCHI_LOG_DIR="${PUNCHI_LOG_DIR:-$PROJECT_ROOT/docs/logs/$DETECTED_PROFILE}"
            punchi_run_setup_with_log "$DETECTED_PROFILE" "$SETUP_EXEC" --dependencies-only
            ;;
        6)
            _punchi_uninstall
            ;;
        7)
            msg quick_ref
            ;;
        8)
            msg cancelled
            exit 0
            ;;
        *)
            msg err_invalid_opt "$choice"
            exit 1
            ;;
    esac
else
    # ---------------------------------------------------------------------------
    # 4. Direct CLI mode with flags
    # ---------------------------------------------------------------------------
    if [[ "${1:-}" == "--restart" ]]; then
        _punchi_restart_plasma
        exit 0
    fi

    if [[ "${1:-}" == "--uninstall" ]]; then
        local do_restart=0
        if [[ "${2:-}" == "--restart" || "${2:-}" == "-r" ]]; then
            do_restart=1
        fi
        _punchi_uninstall "$do_restart"
        exit $?
    fi

    if [[ -z "$DETECTED_PROFILE" ]]; then
        msg err_no_cli_prof "${ID:-unknown}"
        exit 1
    fi

    if [[ "${1:-}" == "--clean-install" ]]; then
        msg start_clean
        _punchi_clean_install
        exit $?
    fi

    PUNCHI_LOG_DIR="${PUNCHI_LOG_DIR:-$PROJECT_ROOT/docs/logs/$DETECTED_PROFILE}"
    punchi_run_setup_with_log "$DETECTED_PROFILE" "$SETUP_EXEC" "$@"
fi
