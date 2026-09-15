#!/usr/bin/env bash
# Presentation only: callers retain their command order and error policy.

if ! declare -F punchi_gettext >/dev/null; then
    punchi_gettext() { printf '%s' "$1"; }
fi
if ! declare -F punchi_gettext_format >/dev/null; then
    punchi_gettext_format() {
        local format="$1"
        shift
        # shellcheck disable=SC2059
        printf -- "$format" "$@"
    }
fi

punchi_progress_update() {
    local percent="${1:?percentage is required}"
    local label="${2:?label is required}"
    [[ "$percent" =~ ^[0-9]+$ ]] && (( percent <= 100 )) || return 2
    if [[ -z "${PUNCHI_PROGRESS_DIR:-}" ]]; then
        if [[ "${PUNCHI_PROGRESS_PRESENTATION:-}" == static ]]; then
            punchi_progress_render_static "$percent" "$label"
        fi
        return 0
    fi
    printf '%s\t%s\n' "$percent" "$label" >"$PUNCHI_PROGRESS_DIR/next-$BASHPID"
    mv -- "$PUNCHI_PROGRESS_DIR/next-$BASHPID" "$PUNCHI_PROGRESS_DIR/state"
}

# A package manager must retain its original questions and stdin. The owner
# acknowledges suspension before this helper writes to the terminal.
punchi_progress_interactive() {
    if [[ -z "${PUNCHI_PROGRESS_DIR:-}" ]]; then
        "$@"
        return
    fi
    touch "$PUNCHI_PROGRESS_DIR/pause"
    while [[ ! -f "$PUNCHI_PROGRESS_DIR/paused" && -d "$PUNCHI_PROGRESS_DIR" ]]; do sleep 0.05; done
    local -a statuses=()
    local had_errexit=0
    [[ $- != *e* ]] || had_errexit=1
    set +e
    "$@" 2>&1 | tee "/dev/fd/$PUNCHI_PROGRESS_TERMINAL_FD"
    statuses=("${PIPESTATUS[@]}")
    (( had_errexit == 0 )) || set -e
    rm -f -- "$PUNCHI_PROGRESS_DIR/pause" "$PUNCHI_PROGRESS_DIR/paused"
    (( statuses[0] == 0 )) || return "${statuses[0]}"
    return "${statuses[1]}"
}

punchi_progress_label() {
    case "$1" in
        prepare) punchi_gettext 'Preparing environment...' ;;
        dependencies) punchi_gettext 'Checking dependencies...' ;;
        environment) punchi_gettext 'Verifying build environment...' ;;
        lint) punchi_gettext 'Validating QML...' ;;
        configure) punchi_gettext 'Configuring CMake...' ;;
        build) punchi_gettext 'Building native integration...' ;;
        tests) punchi_gettext 'Running tests...' ;;
        stage) punchi_gettext 'Assembling package...' ;;
        package) punchi_gettext 'Creating and verifying the plasmoid...' ;;
        install) punchi_gettext 'Installing local package...' ;;
        restart) punchi_gettext 'Restarting Plasma Shell...' ;;
        diagnostics) punchi_gettext 'Collecting diagnostics...' ;;
        complete) punchi_gettext 'Operation completed successfully' ;;
        failed) punchi_gettext 'Operation failed' ;;
        cancelled) punchi_gettext 'Operation cancelled.' ;;
        *) printf '%s' "$1" ;;
    esac
}

punchi_progress_bar() {
    local percent="${1:?percentage is required}"
    local width="${2:?bar width is required}"
    local fill="${3:-#}" filled_width empty_width filled empty
    [[ "$percent" =~ ^[0-9]+$ ]] && (( percent <= 100 )) || return 2
    [[ "$width" =~ ^[0-9]+$ ]] && (( width > 0 )) || return 2
    filled_width=$(( percent * width / 100 ))
    empty_width=$(( width - filled_width ))
    printf -v filled '%*s' "$filled_width" ''
    printf -v empty '%*s' "$empty_width" ''
    printf '[%s%s]' "${filled// /$fill}" "$empty"
}

punchi_progress_render_static() {
    local percent="${1:?percentage is required}"
    local label="${2:?label is required}"
    local text="" columns=80 bar_width=34 text_width=0 bar_fill='#' bar=""
    text="$(punchi_progress_label "$label")"
    if [[ -t 2 && "${TERM:-}" != dumb ]]; then
        columns="$(tput cols 2>/dev/null || printf 80)"
        [[ "$columns" =~ ^[0-9]+$ ]] || columns=80
        bar_width=$(( columns - 24 ))
        (( bar_width <= 34 )) || bar_width=34
        (( bar_width >= 4 )) || bar_width=4
        text_width=$(( columns - bar_width - 8 ))
        (( text_width >= 0 )) || text_width=0
        text="${text:0:text_width}"
        local locale_name="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
        if [[ "${locale_name^^}" == *UTF-8* || "${locale_name^^}" == *UTF8* ]]; then
            bar_fill='█'
        fi
        bar="$(punchi_progress_bar "$percent" "$bar_width" "$bar_fill")"
        printf '%s %3d%% %s\n' "$bar" "$percent" "$text" >&2
    else
        printf '[%3d%%] %s\n' "$percent" "$text" >&2
    fi
}

# Only descend from the command PID owned by this invocation. Stop descendants
# first so their waiting parents can reap them; never signal the desktop group.
punchi_progress_stop_tree() {
    local parent="${1:?owned PID is required}" child
    while IFS=' ' read -r child; do
        [[ "$child" =~ ^[0-9]+$ ]] || continue
        punchi_progress_stop_tree "$child"
    done < <(ps -o pid= --ppid "$parent" 2>/dev/null || true)
    kill -TERM "$parent" 2>/dev/null || true
}

# The logger starts this function in a private background shell and waits for
# it. Do not add another subshell here: the logger must signal the actual owner.
punchi_progress_run() {
    local log_file="${1:?log file is required}"
    shift
    local worker="" status=0 percent=0 label=prepare last_state=""
    local frame=0 part="" pending="" line="" read_status=0 tty=0 columns=80
    local tests_done=0 tests_total=0 tests_failed=0 tests_skipped=0 last_render=""
    local frames=('/' '-' '\' '|') bar_fill='#' input_fd output_fd
    local locale_name="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
    if [[ "${locale_name^^}" == *UTF-8* || "${locale_name^^}" == *UTF8* ]]; then
        bar_fill='█'
    fi
    exec {input_fd}<&0
    exec {output_fd}>&1
    export PUNCHI_PROGRESS_TERMINAL_FD="$output_fd"
    [[ ! -t 1 || "${TERM:-}" == dumb ]] || tty=1
    export PUNCHI_PROGRESS_DIR
    PUNCHI_PROGRESS_DIR="$(mktemp -d "${TMPDIR:-/tmp}/punchi-progress.XXXXXX")" || exit 1

    cleanup_progress() {
        local saved=$?
        if [[ -n "$worker" ]]; then
            punchi_progress_stop_tree "$worker"
            wait "$worker" 2>/dev/null || true
        fi
        rm -rf -- "$PUNCHI_PROGRESS_DIR"
        exit "$saved"
    }
    trap cleanup_progress EXIT
    # Never read from a trap interrupting read -t: nested reads can disturb its
    # timeout and inherit its temporary IFS. Clean up in the main loop instead.
    trap 'status=130' INT
    trap 'status=143' TERM
    mkfifo "$PUNCHI_PROGRESS_DIR/output"
    local pipe_fd
    exec {pipe_fd}<>"$PUNCHI_PROGRESS_DIR/output"
    punchi_progress_update 0 prepare
    "$@" <&"$input_fd" >"$PUNCHI_PROGRESS_DIR/output" 2>&1 &
    worker=$!

    render_progress() {
        local symbol="$1" text bar bar_width text_width
        text="$(punchi_progress_label "$label")"
        if [[ "$label" == tests && "$tests_total" != 0 ]]; then
            text+=" $tests_done/$tests_total"
        fi
        if (( tty )); then
            columns="$(tput cols 2>/dev/null || printf 80)"
            [[ "$columns" =~ ^[0-9]+$ ]] || columns=80
            bar_width=$(( columns - 29 ))
            (( bar_width <= 34 )) || bar_width=34
            (( bar_width >= 4 )) || bar_width=4
            text_width=$(( columns - bar_width - 13 ))
            (( text_width >= 0 )) || text_width=0
            text="${text:0:text_width}"
            bar="$(punchi_progress_bar "$percent" "$bar_width" "$bar_fill")"
            printf '\r\033[2K[ %s ] %s %3d%% %s' "$symbol" "$bar" "$percent" "$text"
        elif [[ "$last_render" != "$percent:$text:$symbol" ]]; then
            printf '[%3d%%] %s\n' "$percent" "$text"
        fi
        last_render="$percent:$text:$symbol"
    }

    while :; do
        part=""
        if IFS= read -r -t 0.1 -u "$pipe_fd" part; then
            read_status=0
        else
            read_status=$?
        fi
        pending+="$part"
        if (( read_status == 0 )); then
            line="$pending"; pending=""
            printf '%s\n' "$line" >>"$log_file" || { status=1; break; }
            if [[ "$line" =~ ^[[:space:]]*([0-9]+)/([0-9]+)[[:space:]]Test[[:space:]] ]]; then
                tests_done="${BASH_REMATCH[1]}"
                tests_total="${BASH_REMATCH[2]}"
                case "$line" in
                    *'***Skipped'*|*'***Not Run (Disabled)'*) tests_skipped=$((tests_skipped + 1)) ;;
                    *Passed*) ;;
                    *) tests_failed=$((tests_failed + 1)) ;;
                esac
            fi
        fi
        if [[ -f "$PUNCHI_PROGRESS_DIR/state" ]]; then
            IFS=$'\t' read -r percent label <"$PUNCHI_PROGRESS_DIR/state" || true
        fi
        if [[ -f "$PUNCHI_PROGRESS_DIR/pause" ]]; then
            if [[ ! -f "$PUNCHI_PROGRESS_DIR/paused" ]]; then
                (( tty == 0 )) || printf '\r\033[2K'
                touch "$PUNCHI_PROGRESS_DIR/paused"
            fi
        else
            # Render on idle ticks or state changes, not on every build line.
            if (( read_status != 0 )) || [[ "$last_state" != "$percent:$label:$tests_done" ]]; then
                if (( tty )); then render_progress "${frames[frame % 4]}"; else render_progress ''; fi
                frame=$((frame + 1))
                last_state="$percent:$label:$tests_done"
            fi
        fi
        (( status == 0 )) || break
        if (( read_status != 0 )) && ! kill -0 "$worker" 2>/dev/null; then break; fi
    done
    [[ -z "$pending" ]] || printf '%s' "$pending" >>"$log_file"
    if (( status != 0 )); then punchi_progress_stop_tree "$worker"; fi
    local command_status=0
    wait "$worker" || command_status=$?
    worker=""
    (( status != 0 )) || status="$command_status"

    local success_sym="✓" fail_sym="✗"
    if [[ ! -t 1 || "${TERM:-}" == "dumb" ]] || [[ "${locale_name^^}" != *UTF-8* && "${locale_name^^}" != *UTF8* ]]; then
        success_sym="OK"
        fail_sym="XX"
    fi

    if (( status == 0 )); then
        percent=100; label=complete; render_progress "$success_sym"
    else
        local failed_label="$label"
        label=failed
        (( status != 130 && status != 143 )) || label=cancelled
        render_progress "$fail_sym"
        printf '\n%s\n' "$(punchi_progress_label "$failed_label")"
        # Render log contents as plain text: diagnostics must not inject ANSI.
        tail -n 16 "$log_file" | LC_ALL=C tr -d '\000-\010\013-\037\177'
    fi
    (( tty == 0 )) || printf '\n'
    if (( tests_total > 0 )); then
        punchi_gettext_format 'Tests: %s/%s completed; %s failed; %s skipped.\n' "$tests_done" "$tests_total" "$tests_failed" "$tests_skipped"
    fi
    exit "$status"
}
