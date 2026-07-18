#!/usr/bin/env bash

set -euo pipefail

show_help() {
    cat <<'EOF'
Usage: scripts/check-build-environment.sh

Reports the local Plasma, Qt/QML lint, build-tool, distribution, and
architecture versions used to build Punchi Dock Remastered.

This command does not install or replace system packages. Use the Qt 6, KF6,
and Plasma development packages provided by your Linux distribution.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ $# -ne 0 ]]; then
    printf 'Unknown argument: %s\n\n' "$1" >&2
    show_help >&2
    exit 2
fi

distribution="Unknown Linux distribution"
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    distribution="${PRETTY_NAME:-${NAME:-Unknown Linux distribution}}"
fi

find_qmllint() {
    local candidate
    local -a candidates=(
        "${QMLLINT_BIN:-}"
        "/usr/lib64/qt6/bin/qmllint"
        "/usr/lib/qt6/bin/qmllint"
        "qmllint6"
        "qmllint"
    )

    for candidate in "${candidates[@]}"; do
        [[ -n "$candidate" ]] || continue
        if [[ "$candidate" == */* ]]; then
            [[ -x "$candidate" ]] || continue
            printf '%s\n' "$candidate"
            return 0
        fi
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done

    return 1
}

first_version_line() {
    local executable="$1"
    local output

    if ! command -v "$executable" >/dev/null 2>&1; then
        printf 'not found\n'
        return 0
    fi

    output="$("$executable" --version 2>&1 || true)"
    if [[ -n "$output" ]]; then
        printf '%s\n' "${output%%$'\n'*}"
    else
        printf 'version query returned no output\n'
    fi
}

plasma_package_version() {
    local version=""

    if command -v rpm >/dev/null 2>&1; then
        version="$(rpm -q --qf '%{VERSION}' plasma-workspace 2>/dev/null || true)"
    elif command -v dpkg-query >/dev/null 2>&1; then
        version="$(dpkg-query -W -f='${Version}' plasma-workspace 2>/dev/null || true)"
    fi

    if [[ -n "$version" ]]; then
        printf '%s\n' "$version"
    elif command -v plasmashell >/dev/null 2>&1; then
        printf 'installed; package version query unavailable\n'
    else
        printf 'not found\n'
    fi
}

printf 'Punchi Dock Remastered build environment\n'
printf 'Distribution: %s\n' "$distribution"
printf 'Architecture: %s\n' "$(uname -m)"
printf 'Plasma Workspace package: %s\n' "$(plasma_package_version)"
printf 'CMake: %s\n' "$(first_version_line cmake)"

if ! qmllint_path="$(find_qmllint)"; then
    printf 'qmllint: not found\n' >&2
    printf 'Result: install the Qt 6 declarative development tools provided by this distribution before building.\n' >&2
    exit 1
fi

qmllint_version="$("$qmllint_path" --version 2>&1 || true)"
qmllint_version="${qmllint_version%%$'\n'*}"
printf 'qmllint: %s (%s)\n' "$qmllint_version" "$qmllint_path"

if [[ "$qmllint_version" =~ (^|[^0-9])6\.11([\.[:space:]]|$) ]]; then
    printf 'Lint profile: Qt 6.11, the primary validated development profile.\n'
elif [[ "$qmllint_version" =~ (^|[^0-9])6\.8([\.[:space:]]|$) ]]; then
    printf 'Lint profile: Qt 6.8 compatibility profile; diagnostics can differ from Qt 6.11 and require the separate baseline.\n'
elif [[ "$qmllint_version" =~ (^|[^0-9])6\.([0-9]+)([\.[:space:]]|$) ]]; then
    printf 'Lint profile: Qt 6.%s is not calibrated yet; run the packaging checks and review its diagnostics without copying another platform baseline.\n' "${BASH_REMATCH[2]}"
else
    printf 'Result: a Qt 6 qmllint executable is required to validate this project.\n' >&2
    exit 1
fi

printf 'Runtime note: qmllint is a development tool and is not required to install a matching prebuilt .plasmoid.\n'
printf 'Safety note: do not replace the distribution Qt stack with a standalone Qt version; use matching distribution packages.\n'
