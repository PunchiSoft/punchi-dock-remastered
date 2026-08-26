#!/usr/bin/env bash

punchi_select_universal_package() {
    local dist_dir="${1:?distribution directory is required}"
    local requested_package="${2:-}"
    local -a candidates=()

    if [[ -n "$requested_package" ]]; then
        [[ -f "$requested_package" ]] || return 1
        printf '%s\n' "$requested_package"
        return 0
    fi

    [[ -d "$dist_dir" ]] || return 1
    mapfile -d '' -t candidates < <(
        find "$dist_dir" -maxdepth 2 -type f \
            -name '*-universal.plasmoid' \
            ! -name '*-local-test.plasmoid' \
            -print0 \
            | sort -zV
    )
    (( ${#candidates[@]} > 0 )) || return 1

    printf '%s\n' "${candidates[-1]}"
}
