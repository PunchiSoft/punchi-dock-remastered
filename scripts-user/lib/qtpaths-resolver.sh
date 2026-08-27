#!/usr/bin/env bash

# Resolve the Qt 6 qtpaths executable across distribution-specific layouts.
punchi_find_qtpaths6() {
    local candidate=""
    local resolved=""
    local qt_version=""
    local -a candidates=(
        "${QTPATHS_BIN:-}"
        qtpaths6
        /usr/lib/qt6/bin/qtpaths6
        /usr/lib64/qt6/bin/qtpaths6
        /usr/lib/qt6/bin/qtpaths
        /usr/lib64/qt6/bin/qtpaths
        qtpaths
    )

    for candidate in "${candidates[@]}"; do
        [[ -n "$candidate" ]] || continue

        if [[ "$candidate" == */* ]]; then
            [[ -x "$candidate" ]] || continue
            resolved="$candidate"
        else
            resolved="$(command -v "$candidate" 2>/dev/null || true)"
            [[ -n "$resolved" ]] || continue
        fi

        qt_version="$("$resolved" --qt-version 2>/dev/null || true)"
        if [[ "$qt_version" == 6 || "$qt_version" == 6.* ]]; then
            printf '%s\n' "$resolved"
            return 0
        fi
    done

    return 1
}

punchi_qt6_writable_data_root() {
    local fallback="${1:-}"
    local qtpaths_path=""
    local data_root=""

    if qtpaths_path="$(punchi_find_qtpaths6)"; then
        data_root="$("$qtpaths_path" --writable-path GenericDataLocation 2>/dev/null || true)"
        if [[ -n "$data_root" ]]; then
            printf '%s\n' "$data_root"
            return 0
        fi
    fi

    if [[ -n "$fallback" ]]; then
        printf '%s\n' "$fallback"
        return 0
    fi

    return 1
}
