#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../scripts/distro/debian14-testing-setup.sh
source "$PROJECT_ROOT/scripts/distro/debian14-testing-setup.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

dpkg-query() {
    local package_name="${!#}"

    case "$package_name" in
        installed-package|second-installed-package)
            printf 'install ok installed'
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

APT_PACKAGES=(installed-package missing-package second-installed-package)
detected_missing="$(missing_apt_packages)"
[[ "$detected_missing" == "missing-package" ]] \
    || fail "expected only missing-package, got: ${detected_missing:-empty}"

APT_PACKAGES=(installed-package second-installed-package)
detected_missing="$(missing_apt_packages)"
[[ -z "$detected_missing" ]] \
    || fail "expected no missing packages, got: $detected_missing"

printf 'Debian dependency detection tests passed.\n'
