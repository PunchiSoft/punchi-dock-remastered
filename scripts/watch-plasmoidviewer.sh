#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

APPLET_ID="org.kde.plasma.punchi-dock-remastered"
WATCH_ROOT="${1:-contents}"
POLL_INTERVAL="${POLL_INTERVAL:-1}"
VIEWER_FORMFACTOR="${VIEWER_FORMFACTOR:-horizontal}"
VIEWER_LOCATION="${VIEWER_LOCATION:-bottomedge}"

if ! command -v plasmoidviewer >/dev/null 2>&1; then
    echo "plasmoidviewer no está disponible en PATH." >&2
    exit 1
fi

start_viewer() {
    plasmoidviewer -a "$APPLET_ID" -f "$VIEWER_FORMFACTOR" -l "$VIEWER_LOCATION" >/dev/null 2>&1 &
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

snapshot_tree() {
    find "$WATCH_ROOT" metadata.json -type f -printf '%P %T@\n' 2>/dev/null | sort
}

trap cleanup EXIT INT TERM

if command -v inotifywait >/dev/null 2>&1; then
    watcher_backend="inotifywait"
elif command -v fswatch >/dev/null 2>&1; then
    watcher_backend="fswatch"
else
    watcher_backend="polling"
fi

echo "Iniciando plasmoidviewer para $APPLET_ID ($VIEWER_FORMFACTOR, $VIEWER_LOCATION)"
start_viewer

echo "Observando cambios en: $WATCH_ROOT"
if [[ "$watcher_backend" == "polling" ]]; then
    echo "Usando fallback por sondeo cada ${POLL_INTERVAL}s"
    last_snapshot="$(snapshot_tree)"
fi

while true; do
    if [[ "$watcher_backend" == "inotifywait" ]]; then
        inotifywait -qq -r -e close_write,create,delete,move "$WATCH_ROOT" metadata.json
    elif [[ "$watcher_backend" == "fswatch" ]]; then
        fswatch -1 -r "$WATCH_ROOT" metadata.json >/dev/null
    else
        sleep "$POLL_INTERVAL"
        current_snapshot="$(snapshot_tree)"
        [[ "$current_snapshot" == "$last_snapshot" ]] && continue
        last_snapshot="$current_snapshot"
    fi

    echo "Cambio detectado. Reiniciando plasmoidviewer..."
    stop_viewer
    start_viewer
done
