#!/usr/bin/env bash
set -euo pipefail

APPLET_ID="org.kde.plasma.punchi-dock-remastered"
WATCH_ROOT="${1:-contents}"

if ! command -v plasmoidviewer >/dev/null 2>&1; then
    echo "plasmoidviewer no está disponible en PATH." >&2
    exit 1
fi

start_viewer() {
    plasmoidviewer -a "$APPLET_ID" >/dev/null 2>&1 &
    viewer_pid=$!
}

stop_viewer() {
    if [[ -n "${viewer_pid:-}" ]] && kill -0 "$viewer_pid" >/dev/null 2>&1; then
        kill "$viewer_pid" >/dev/null 2>&1 || true
        wait "$viewer_pid" 2>/dev/null || true
    else
        pkill -f "plasmoidviewer -a $APPLET_ID" >/dev/null 2>&1 || true
    fi
}

cleanup() {
    stop_viewer
}

trap cleanup EXIT INT TERM

if command -v inotifywait >/dev/null 2>&1; then
    watcher_backend="inotifywait"
elif command -v fswatch >/dev/null 2>&1; then
    watcher_backend="fswatch"
else
    echo "Necesitas inotifywait o fswatch para usar este watcher." >&2
    exit 1
fi

echo "Iniciando plasmoidviewer para $APPLET_ID"
start_viewer

echo "Observando cambios en: $WATCH_ROOT"
while true; do
    if [[ "$watcher_backend" == "inotifywait" ]]; then
        inotifywait -qq -r -e close_write,create,delete,move "$WATCH_ROOT" metadata.json
    else
        fswatch -1 -r "$WATCH_ROOT" metadata.json >/dev/null
    fi

    echo "Cambio detectado. Reiniciando plasmoidviewer..."
    stop_viewer
    start_viewer
done
