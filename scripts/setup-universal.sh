#!/usr/bin/env bash
# Instalador sencillo de paquetes universal .plasmoid para Punchi Dock Remastered
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
DIST_DIR="$PROJECT_ROOT/dist"

# shellcheck source=lib/local-package-install.sh
source "$LIB_DIR/local-package-install.sh"
# shellcheck source=lib/plasma-runtime-diagnostics.sh
source "$LIB_DIR/plasma-runtime-diagnostics.sh"

PLUGIN_ID="org.kde.plasma.punchi-dock-remastered"
DATA_ROOT="$(qtpaths6 --writable-path GenericDataLocation 2>/dev/null || echo "$HOME/.local/share")"
INSTALL_DIR="$DATA_ROOT/plasma/plasmoids/$PLUGIN_ID"
DEBUG_LOG="$PROJECT_ROOT/debug.log"
PUNCHI_PLASMA_PID=""

show_help() {
    cat <<EOF
Uso: $0 [ruta_al_paquete_universal.plasmoid]

Instala o sobrescribe el plasmoide Punchi Dock Remastered en la distribución actual
(Arch Linux, Fedora, Debian, Kubuntu, etc.) usando el paquete precompilado .plasmoid universal.
Posteriormente reinicia la sesión de Plasma Shell para aplicar los cambios de inmediato.

Ejemplos:
  $0                                                      # Busca e instala el paquete universal en dist/
  $0 dist/punchi-dock-remastered-0.9.7-universal.plasmoid # Especifica un paquete .plasmoid directo
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

    echo "Error: Plasma Shell PID did not change after the restart request." >&2
    return 1
}

# 1. Determinar el paquete universal a instalar
TARGET_PACKAGE="${1:-}"

if [[ -z "$TARGET_PACKAGE" ]]; then
    if [[ -d "$DIST_DIR" ]]; then
        # Buscar paquetes que contengan "universal" o cualquier .plasmoid
        TARGET_PACKAGE="$(find "$DIST_DIR" -type f -name "*universal*.plasmoid" | sort -V | tail -n 1 || true)"
        if [[ -z "$TARGET_PACKAGE" ]]; then
            TARGET_PACKAGE="$(find "$DIST_DIR" -type f -name "*.plasmoid" | sort -V | tail -n 1 || true)"
        fi
    fi
fi

if [[ -z "$TARGET_PACKAGE" || ! -f "$TARGET_PACKAGE" ]]; then
    echo "Error: No se encontró ningún paquete .plasmoid en '$DIST_DIR' ni se especificó una ruta válida." >&2
    echo "Uso: $0 <ruta/al/paquete.plasmoid>" >&2
    exit 1
fi

echo "=========================================================="
echo "  Punchi Dock Remastered - Instalador Universal / Arch   "
echo "=========================================================="
echo "Paquete seleccionado: $TARGET_PACKAGE"
echo "Directorio de destino: $INSTALL_DIR"
echo ""

echo "==> [1/3] Instalando / Sobrescribiendo plasmoide..."
punchi_install_local_package "$TARGET_PACKAGE" "$INSTALL_DIR" "$DATA_ROOT" "$PLUGIN_ID"

if [[ ! -f "$INSTALL_DIR/metadata.json" ]]; then
    echo "Error: kpackagetool6 no dejó una instalación válida en $INSTALL_DIR" >&2
    exit 1
fi

echo "Instalación completada en: $INSTALL_DIR"
echo ""

echo "==> [2/3] Actualizando entorno Plasma Shell..."
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
echo " ✅ Instalación / Actualización finalizada exitosamente."
echo " Archivo instalado: ${TARGET_PACKAGE#"$PROJECT_ROOT/"}"
echo " Diagnóstico guardado en: $DEBUG_LOG"
echo "=========================================================="
