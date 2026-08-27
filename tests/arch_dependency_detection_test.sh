#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../scripts-dev/distro/arch-setup.sh
source "$PROJECT_ROOT/scripts-dev/distro/arch-setup.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

pacman() {
    local package_name="${!#}"

    case "$package_name" in
        installed-package|second-installed-package)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

ID=arch
ID_LIKE=""
is_arch_family || fail "Arch Linux was not recognized"
ID=manjaro
is_arch_family || fail "a known Arch derivative was not recognized"
ID=custom
ID_LIKE="linux arch"
is_arch_family || fail "ID_LIKE=arch was not recognized"
ID=fedora
ID_LIKE="rhel"
if is_arch_family; then
    fail "a non-Arch host was incorrectly recognized"
fi

PACMAN_PACKAGES=(installed-package missing-package second-installed-package)
detected_missing="$(missing_pacman_packages)"
[[ "$detected_missing" == "missing-package" ]] \
    || fail "expected only missing-package, got: ${detected_missing:-empty}"

PACMAN_PACKAGES=(installed-package second-installed-package)
detected_missing="$(missing_pacman_packages)"
[[ -z "$detected_missing" ]] \
    || fail "expected no missing packages, got: $detected_missing"

PACMAN_PACKAGES=(
    base-devel cmake extra-cmake-modules gettext kconfig kcoreaddons
    kglobalaccel ki18n kio kjobwidgets kpackage kservice kwindowsystem
    libpipewire libplasma plasma-workspace qt6-base qt6-declarative
    qt6-shadertools
)
for required_package in \
        base-devel extra-cmake-modules libpipewire libplasma plasma-workspace \
        qt6-base qt6-declarative qt6-shadertools; do
    [[ " ${PACMAN_PACKAGES[*]} " == *" $required_package "* ]] \
        || fail "required Arch package is absent: $required_package"
done

SKIP_PACMAN=0
DRY_RUN=1
ASSUME_YES=1
PACMAN_PACKAGES=(missing-package)
install_plan="$(install_dependencies)"
[[ "$install_plan" == *"sudo pacman -Syu --needed --noconfirm missing-package"* ]] \
    || fail "the Arch install plan is not a full upgrade with --needed"

printf 'Arch dependency detection tests passed.\n'
