#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Run Fedora 44 lint, build, packaging and the stable headless test subset.
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

# The minimal Fedora 44 image does not provide a Plasma session. Keep lint,
# build, package and the stable headless test subset here; the full CTest suite
# runs on Fedora 45 in a real session through the same package profile.
headless_selection_file="$project_root/scripts-dev/ci/fedora-headless-tests.txt"
[[ -r "$headless_selection_file" ]] || {
    echo "Error: missing headless test selection: $headless_selection_file" >&2
    exit 1
}
headless_regex="$(awk '
    /^[[:space:]]*#/ { next }
    NF { printf "%s%s", separator, $1; separator = "|" }
' "$headless_selection_file")"
[[ -n "$headless_regex" ]] || {
    echo "Error: the headless test selection is empty." >&2
    exit 1
}
headless_regex="^($headless_regex)$"

# The container is disposable. `util-linux` provides `runuser`; DNF then installs
# the project's declared dependencies through the maintainer setup script.
dnf install --assumeyes sudo shadow-utils util-linux
useradd --uid "$ci_uid" --user-group --create-home --shell /bin/bash punchi-ci
dnf_path="$(command -v dnf)"
sudoers_file="/etc/sudoers.d/punchi-ci-dnf"
printf 'punchi-ci ALL=(root) NOPASSWD: %s\n' "$dnf_path" >"$sudoers_file"
chmod 0440 "$sudoers_file"
visudo --check --file="$sudoers_file"

runuser --user punchi-ci -- mkdir -p "$ci_build_root/setup-logs"
runuser --user punchi-ci -- env \
    HOME=/home/punchi-ci \
    PUNCHI_SETUP_LOG_ACTIVE=1 \
    PUNCHI_PROGRESS_PRESENTATION=static \
    bash "$project_root/scripts-dev/distro/fedora-setup.sh" \
    --dependencies-only --yes --jobs 2 \
    2>&1 | tee "$ci_build_root/setup-logs/dependencies.log"

runuser --user punchi-ci -- env \
    HOME=/home/punchi-ci \
    PUNCHI_SETUP_LOG_ACTIVE=1 \
    PUNCHI_PROGRESS_PRESENTATION=static \
    BUILD_DIR="$ci_build_root/build" \
    PACKAGE_OUTPUT_FILE="$ci_build_root/punchi-dock-remastered-ci.plasmoid" \
    QMLLINT_BASELINE_FILE="$project_root/scripts-dev/qmllint-baseline-fedora.env" \
    PUNCHI_CTEST_SELECTION="$headless_regex" \
    bash "$project_root/scripts-dev/distro/fedora-package.sh" \
    2>&1 | tee "$ci_build_root/setup-logs/package.log"
