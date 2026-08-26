#!/usr/bin/env bash
# Selector e instalador interactivo de paquetes .plasmoid para Punchi Dock Remastered

set -euo pipefail

DEV_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DEV_SCRIPTS_DIR/.." && pwd)"
DEV_LIB_DIR="$DEV_SCRIPTS_DIR/lib"
PUBLIC_LIB_DIR="$PROJECT_ROOT/scripts-user/lib"

# shellcheck source=../lib/plasma-version.sh
source "$DEV_LIB_DIR/plasma-version.sh"
# shellcheck source=../lib/local-package-install.sh
source "$PUBLIC_LIB_DIR/local-package-install.sh"
# shellcheck source=../lib/plasma-runtime-diagnostics.sh
source "$PUBLIC_LIB_DIR/plasma-runtime-diagnostics.sh"

PLUGIN_ID="org.kde.plasma.punchi-dock-remastered"
DATA_ROOT="$(qtpaths6 --writable-path GenericDataLocation)"
INSTALL_DIR="$DATA_ROOT/plasma/plasmoids/$PLUGIN_ID"
DEBUG_LOG="$PROJECT_ROOT/debug.log"
DIST_DIR="$PROJECT_ROOT/dist"
PUNCHI_PLASMA_PID=""

show_help() {
    cat <<EOF
Uso: $0 [numero_de_opcion | ruta_al_paquete.plasmoid]

Escanea la carpeta dist/ en busca de paquetes .plasmoid compilados
(Debian, Fedora, local-test, releases), permite seleccionar uno e instalarlo
mediante kpackagetool6, para luego reiniciar la sesión de Plasma Shell.

Ejemplos:
  $0                   # Modo interactivo (muestra menú numerado)
  $0 1                 # Instala la opción 1 directamente
  $0 dist/mi-paquete.plasmoid  # Instala la ruta específica enviada
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

restart_plasma_shell() {
    local previous_pid=""
    local current_pid=""

    previous_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
    echo "PID de Plasma Shell antes del reinicio: ${previous_pid:-no iniciado}"

    if command -v systemctl >/dev/null 2>&1 \
        && systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
        echo "Método de reinicio: servicio systemd de usuario"
        systemctl --user restart plasma-plasmashell.service

        sleep 1
        current_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
        if [[ -n "$previous_pid" && "$current_pid" == "$previous_pid" ]]; then
            echo "Systemd mantuvo el proceso activo; forzando detención por kquitapp6"
            if command -v kquitapp6 >/dev/null 2>&1; then
                kquitapp6 plasmashell >/dev/null 2>&1 || true
            else
                killall plasmashell >/dev/null 2>&1 || true
            fi

            sleep 0.5
            if kill -0 "$previous_pid" >/dev/null 2>&1; then
                echo "Enviando SIGTERM al PID $previous_pid..."
                kill "$previous_pid" >/dev/null 2>&1 || true
            fi

            for _stop_attempt in {1..20}; do
                if ! kill -0 "$previous_pid" >/dev/null 2>&1; then
                    break
                fi
                sleep 0.25
            done

            systemctl --user restart plasma-plasmashell.service
        fi
    else
        echo "Método de reinicio: control de aplicación KDE (kquitapp6 / kstart6)"
        if command -v kquitapp6 >/dev/null 2>&1; then
            kquitapp6 plasmashell >/dev/null 2>&1 || true
        else
            killall plasmashell >/dev/null 2>&1 || true
        fi

        sleep 1

        if command -v kstart6 >/dev/null 2>&1; then
            kstart6 plasmashell >/dev/null 2>&1
        elif command -v kstart >/dev/null 2>&1; then
            kstart plasmashell >/dev/null 2>&1
        else
            plasmashell >/dev/null 2>&1 &
        fi
    fi

    for _attempt in {1..20}; do
        current_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
        if [[ -n "$current_pid" && "$current_pid" != "$previous_pid" ]]; then
            PUNCHI_PLASMA_PID="$current_pid"
            echo "PID de Plasma Shell tras reinicio: $current_pid"
            echo "Reinicio de Plasma Shell confirmado exitosamente."
            return 0
        fi
        sleep 0.25
    done

    echo "Advertencia: El PID de Plasma Shell no cambió después del reinicio." >&2
    return 1
}

# 1. Buscar paquetes disponibles en dist/ (priorizando la versión actual)
PACKAGE_VERSION="$(awk -F '"' '/"Version"[[:space:]]*:/ { print $4; exit }' "$PROJECT_ROOT/metadata.json" 2>/dev/null || echo "")"
packages=()
if [[ -d "$DIST_DIR" ]]; then
    if [[ -n "$PACKAGE_VERSION" ]]; then
        while IFS= read -r file; do
            [[ -n "$file" ]] && packages+=("$file")
        done < <(find "$DIST_DIR" -type f -name "*${PACKAGE_VERSION}*.plasmoid" | sort)
    fi

    if (( ${#packages[@]} == 0 )); then
        while IFS= read -r file; do
            [[ -n "$file" ]] && packages+=("$file")
        done < <(find "$DIST_DIR" -maxdepth 2 -type f -name "*.plasmoid" | sort)
    fi
fi

SELECTED_FILE=""

if [[ $# -gt 0 ]]; then
    arg="$1"
    if [[ -f "$arg" ]]; then
        SELECTED_FILE="$(realpath "$arg")"
    elif [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 1 && arg <= ${#packages[@]} )); then
        SELECTED_FILE="${packages[$((arg - 1))]}"
    else
        echo "Error: Argumento no válido o archivo no encontrado: '$arg'" >&2
        show_help
        exit 1
    fi
else
    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "Error: No se encontraron paquetes .plasmoid en '$DIST_DIR'." >&2
        echo "Ejecuta primero ./scripts-dev/setup.sh para crear un paquete de desarrollo." >&2
        exit 1
    fi

    echo "=========================================================="
    echo "  Punchi Dock Remastered - Selector de Paquete a Instalar "
    echo "=========================================================="
    echo "Paquetes disponibles en dist/:"
    echo ""

    for index in "${!packages[@]}"; do
        rel_path="${packages[$index]#"$PROJECT_ROOT/"}"
        size_bytes="$(stat -c%s "${packages[$index]}" 2>/dev/null || echo "0")"
        size_kb="$((size_bytes / 1024))"
        printf "  [%2d] %s (%d KB)\n" "$((index + 1))" "$rel_path" "$size_kb"
    done

    echo ""
    read -rp "Selecciona el número del paquete a instalar [1-${#packages[@]}]: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#packages[@]} )); then
        SELECTED_FILE="${packages[$((choice - 1))]}"
    else
        echo "Error: Selección no válida: '$choice'" >&2
        exit 1
    fi
fi

echo ""
echo "==> Paquete seleccionado: $SELECTED_FILE"
echo "==> [1/3] Instalando paquete con kpackagetool6..."
punchi_install_local_package "$SELECTED_FILE" "$INSTALL_DIR" "$DATA_ROOT" "$PLUGIN_ID"

if [[ ! -f "$INSTALL_DIR/metadata.json" ]]; then
    echo "Error: kpackagetool6 no dejó una instalación válida en $INSTALL_DIR" >&2
    exit 1
fi

echo "Instalación en directorio: $INSTALL_DIR"

echo ""
echo "==> [2/3] Reiniciando entorno Plasma Shell..."
restart_started_at="$(date --iso-8601=seconds)"
restart_plasma_shell

echo ""
echo "==> [3/3] Recolectando diagnóstico..."
sleep 5
if ! kill -0 "$PUNCHI_PLASMA_PID" >/dev/null 2>&1; then
    echo "Error: Plasma Shell PID $PUNCHI_PLASMA_PID stopped during startup." >&2
    exit 1
fi
punchi_collect_plasma_runtime_diagnostics \
    "$PUNCHI_PLASMA_PID" "$restart_started_at" "$DEBUG_LOG" "$PLUGIN_ID"

echo ""
echo "=========================================================="
echo " ✅ Instalación finalizada y Plasma Shell reiniciado."
echo " Archivo instalado: ${SELECTED_FILE#"$PROJECT_ROOT/"}"
echo " Diagnóstico guardado en: $DEBUG_LOG"
echo "=========================================================="
