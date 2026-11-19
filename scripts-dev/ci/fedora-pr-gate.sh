#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Run the repository's existing full Fedora gate in an ephemeral container.
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ "${PUNCHI_CI_CONTAINER:-}" != "1" ]]; then
    echo "Error: this gate must run inside its disposable CI container." >&2
    exit 2
fi
if [[ ! -f /.dockerenv ]]; then
    echo "Error: refusing to install packages outside the workflow's Docker container." >&2
    exit 2
fi

[[ -r /etc/os-release ]] || {
    echo "Error: cannot identify the CI container distribution." >&2
    exit 1
}
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == "fedora" && "${VERSION_ID:-}" == "44" ]] || {
    echo "Error: expected the pinned Fedora 44 CI image; found ${PRETTY_NAME:-unknown}." >&2
    exit 1
}
(( EUID == 0 )) || {
    echo "Error: the container entry point must create the unprivileged build user." >&2
    exit 1
}

ci_uid="${PUNCHI_CI_UID:-}"
[[ "$ci_uid" =~ ^[1-9][0-9]{0,8}$ ]] || {
    echo "Error: PUNCHI_CI_UID must be a positive numeric owner of the checkout." >&2
    exit 1
}
[[ "$(stat -c '%u' "$project_root")" == "$ci_uid" ]] || {
    echo "Error: the checkout owner does not match PUNCHI_CI_UID." >&2
    exit 1
}
if getent passwd "$ci_uid" >/dev/null; then
    echo "Error: uid $ci_uid is already assigned inside the Fedora image." >&2
    exit 1
fi
if getent passwd punchi-ci >/dev/null; then
    echo "Error: punchi-ci already exists in the Fedora image." >&2
    exit 1
fi
ci_build_root="$project_root/build/ci-fedora44"
if [[ -e "$ci_build_root" ]]; then
    echo "Error: refusing to overwrite an existing CI build directory: $ci_build_root" >&2
    exit 1
fi

# The container is disposable. DNF installs the same declared dependencies as
# the maintainer setup script; the build and tests then run as the checkout owner.
dnf install --assumeyes sudo shadow-utils
useradd --uid "$ci_uid" --user-group --create-home --shell /bin/bash punchi-ci
dnf_path="$(command -v dnf)"
sudoers_file="/etc/sudoers.d/punchi-ci-dnf"
printf 'punchi-ci ALL=(root) NOPASSWD: %s\n' "$dnf_path" >"$sudoers_file"
chmod 0440 "$sudoers_file"
visudo --check --file="$sudoers_file"

runuser --user punchi-ci -- mkdir -p "$ci_build_root/setup-logs"
runuser --user punchi-ci -- env \
    HOME=/home/punchi-ci \
    PUNCHI_LOG_DIR="$ci_build_root/setup-logs" \
    bash "$project_root/scripts-dev/distro/fedora-setup.sh" \
    --dependencies-only --yes --jobs 2

runuser --user punchi-ci -- env \
    HOME=/home/punchi-ci \
    BUILD_DIR="$ci_build_root/build" \
    PACKAGE_OUTPUT_FILE="$ci_build_root/punchi-dock-remastered-ci.plasmoid" \
    QMLLINT_BASELINE_FILE="$project_root/scripts-dev/qmllint-baseline-fedora.env" \
    bash "$project_root/scripts-dev/distro/fedora-package.sh"
