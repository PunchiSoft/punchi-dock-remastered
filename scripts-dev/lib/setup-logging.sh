#!/usr/bin/env bash

# shellcheck source=setup-progress.sh
source "$(dirname "${BASH_SOURCE[0]}")/setup-progress.sh"
# shellcheck source=../../scripts-user/lib/setup-localization.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts-user/lib/setup-localization.sh"

punchi_run_setup_with_log() (
    export PUNCHI_SETUP_LOG_ACTIVE=1
    local profile="${1:?setup profile is required}"
    local setup_command="${2:?setup command is required}"
    shift 2

    if [[ ! "$profile" =~ ^[a-z0-9-]+$ ]]; then
        printf 'Error: invalid setup log profile: %s\n' "$profile" >&2
        return 2
    fi

    local log_root="${PUNCHI_LOG_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/punchi-dock-remastered/logs}"
    local timestamp=""
    local log_file=""
    local latest_file=""
    local started_at=""
    local finished_at=""
    local pipeline_status=()
    local command_status=0
    local tee_status=0
    local plain=0 argument
    for argument in "$@"; do
        case "$argument" in --dry-run|--help|-h) plain=1 ;; esac
    done
    punchi_prepare_setup_localization "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

    timestamp="$(date '+%Y%m%d-%H%M%S')"
    started_at="$(date --iso-8601=seconds)"
    log_file="$log_root/setup-$profile-$timestamp-$$.log"
    latest_file="$log_root/setup-$profile-latest.log"

    mkdir -p -- "$log_root" || {
        printf 'Error: cannot create the setup log directory: %s\n' "$log_root" >&2
        return 1
    }
    chmod 700 -- "$log_root" 2>/dev/null || {
        printf 'Warning: the shared log directory permissions could not be restricted: %s\n' "$log_root" >&2
    }
    (umask 077 && : >"$log_file") || {
        printf 'Error: cannot create the setup log: %s\n' "$log_file" >&2
        return 1
    }

    {
        printf 'Punchi Dock setup log\n'
        printf 'Profile: %s\n' "$profile"
        printf 'Started: %s\n' "$started_at"
        printf 'Log file: %s\n' "$log_file"
        printf '%s\n' '----------------------------------------'
    } >>"$log_file"

    set +e
    if (( plain )); then
        "$setup_command" "$@" 2>&1 | tee -a "$log_file"
        pipeline_status=("${PIPESTATUS[@]}")
    else
        local input_fd runner signal_status=0
        exec {input_fd}<&0
        punchi_progress_run "$log_file" "$setup_command" "$@" <&"$input_fd" &
        runner=$!
        trap 'signal_status=130; kill -TERM "$runner" 2>/dev/null || true' INT
        trap 'signal_status=143; kill -TERM "$runner" 2>/dev/null || true' TERM
        wait "$runner"
        command_status=$?
        if (( signal_status )); then
            wait "$runner" 2>/dev/null || true
            command_status="$signal_status"
        fi
        trap - INT TERM
        pipeline_status=("$command_status" 0)
    fi
    set -e

    command_status="${pipeline_status[0]}"
    tee_status="${pipeline_status[1]}"
    finished_at="$(date --iso-8601=seconds)"

    {
        printf '%s\n' '----------------------------------------'
        printf 'Finished: %s\n' "$finished_at"
        printf 'Exit status: %s\n' "$command_status"
        printf 'Log saved to: %s\n' "$log_file"
    } >>"$log_file"
    printf 'Log: %s\nExit status: %s\n' "$log_file" "$command_status"

    cp -- "$log_file" "$latest_file" || {
        printf 'Warning: could not update the latest log file: %s\n' "$latest_file" >&2
    }

    if (( tee_status != 0 )); then
        printf 'Error: the setup output could not be written completely to %s\n' "$log_file" >&2
        return "$tee_status"
    fi

    return "$command_status"
)
