#!/usr/bin/env bash

PUNCHI_PLASMA_PID="${PUNCHI_PLASMA_PID:-}"

if ! declare -F punchi_gettext_line >/dev/null 2>&1; then
    punchi_gettext_line() { printf '%s\n' "$1"; }
    punchi_gettext_format() { local format="$1"; shift; printf -- "$format" "$@"; }
fi

punchi_restart_plasma_shell() {
    local previous_pid=""
    local current_pid=""

    PUNCHI_PLASMA_PID=""
    previous_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
    punchi_gettext_format 'Plasma Shell PID before restart: %s\n' "${previous_pid:-not running}"

    if command -v systemctl >/dev/null 2>&1 \
        && systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
        punchi_gettext_line 'Restart method: systemd user service'
        if ! systemctl --user restart plasma-plasmashell.service; then
            punchi_gettext_line 'Error: the Plasma Shell user service could not be restarted.' >&2
            return 1
        fi

        sleep 1
        current_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
        if [[ -n "$previous_pid" && "$current_pid" == "$previous_pid" ]]; then
            if command -v kquitapp6 >/dev/null 2>&1; then
                kquitapp6 plasmashell >/dev/null 2>&1 || true
            elif command -v killall >/dev/null 2>&1; then
                killall plasmashell >/dev/null 2>&1 || true
            fi
            sleep 0.5
            if ! systemctl --user restart plasma-plasmashell.service; then
                punchi_gettext_line 'Error: Plasma Shell did not stop and the forced restart failed.' >&2
                return 1
            fi
        fi
    else
        punchi_gettext_line 'Restart method: KDE application control'
        if command -v kquitapp6 >/dev/null 2>&1; then
            kquitapp6 plasmashell >/dev/null 2>&1 || true
        elif command -v killall >/dev/null 2>&1; then
            killall plasmashell >/dev/null 2>&1 || true
        fi

        sleep 1
        if command -v kstart6 >/dev/null 2>&1; then
            kstart6 plasmashell >/dev/null 2>&1
        elif command -v kstart >/dev/null 2>&1; then
            kstart plasmashell >/dev/null 2>&1
        elif command -v plasmashell >/dev/null 2>&1; then
            plasmashell >/dev/null 2>&1 &
        else
            punchi_gettext_line 'Error: no supported command is available to start Plasma Shell.' >&2
            return 1
        fi
    fi

    for _attempt in {1..20}; do
        current_pid="$(pgrep -xn plasmashell 2>/dev/null || true)"
        if [[ -n "$current_pid" && "$current_pid" != "$previous_pid" ]]; then
            PUNCHI_PLASMA_PID="$current_pid"
            punchi_gettext_format 'Plasma Shell restarted successfully (new PID: %s).\n' "$current_pid"
            return 0
        fi
        sleep 0.25
    done

    punchi_gettext_line 'Error: Plasma Shell PID did not change after the restart request.' >&2
    return 1
}
