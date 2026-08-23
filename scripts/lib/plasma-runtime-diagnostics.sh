#!/usr/bin/env bash

punchi_collect_plasma_runtime_diagnostics() {
    local plasma_pid="${1:-}"
    local restart_started_at="${2:-}"
    local output_file="${3:-}"
    local plugin_id="${4:-}"
    local temporary_output=""
    local blocking_lines=""
    local blocking_pattern='Error loading QML|QQmlComponent|QQmlObjectCreator|TypeError:|ReferenceError:|Binding loop detected|Cyclic alias|Cannot read propert|Cannot assign[^:]*null|fullRepresentation[^:]*null|compactRepresentation[^:]*null'

    if [[ ! "$plasma_pid" =~ ^[0-9]+$ ]]; then
        printf 'Error: invalid Plasma Shell PID: %s\n' "${plasma_pid:-empty}" >&2
        return 2
    fi
    if [[ -z "$restart_started_at" ]]; then
        printf 'Error: the Plasma Shell restart timestamp is empty.\n' >&2
        return 2
    fi
    if [[ -z "$output_file" || -z "$plugin_id" ]]; then
        printf 'Error: the diagnostics output path or plugin id is empty.\n' >&2
        return 2
    fi
    if ! command -v journalctl >/dev/null 2>&1; then
        printf 'Error: journalctl is required to validate Plasma Shell.\n' >&2
        return 1
    fi

    temporary_output="$(mktemp "${output_file}.tmp.XXXXXX")" || {
        printf 'Error: could not create a private diagnostics file.\n' >&2
        return 1
    }
    if ! chmod 600 "$temporary_output"; then
        printf 'Error: could not restrict diagnostics file permissions.\n' >&2
        rm -f -- "$temporary_output"
        return 1
    fi

    if ! journalctl --user "_PID=$plasma_pid" \
            --since "$restart_started_at" --no-pager --quiet \
            >"$temporary_output"; then
        printf 'Error: could not read the journal for Plasma Shell PID %s.\n' \
            "$plasma_pid" >&2
        rm -f -- "$temporary_output"
        return 1
    fi

    if ! mv -f -- "$temporary_output" "$output_file"; then
        printf 'Error: could not publish Plasma Shell diagnostics.\n' >&2
        rm -f -- "$temporary_output"
        return 1
    fi

    blocking_lines="$(
        grep -iE "$blocking_pattern" "$output_file" \
            | grep -F -- "$plugin_id" || true
    )"
    if [[ -n "$blocking_lines" ]]; then
        printf 'Error: blocking QML diagnostics were emitted by %s:\n' \
            "$plugin_id" >&2
        printf '%s\n' "$blocking_lines" >&2
        return 1
    fi

    printf 'Plasma Shell diagnostics captured for PID %s: %s\n' \
        "$plasma_pid" "$output_file"
}
