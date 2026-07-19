#!/usr/bin/env bash

punchi_extract_plasma_version() {
    local version_output="${1:-}"

    if [[ "$version_output" =~ [Pp]lasmashell[^0-9]*([0-9]+(\.[0-9]+){1,3}) ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    elif [[ "$version_output" =~ (^|[^0-9])([0-9]+(\.[0-9]+){1,3})([^0-9]|$) ]]; then
        printf '%s\n' "${BASH_REMATCH[2]}"
    fi

    return 0
}
