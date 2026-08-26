#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

# shellcheck source=../scripts-user/lib/universal-package-selection.sh
source "$PROJECT_ROOT/scripts-user/lib/universal-package-selection.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

dist_dir="$TEMP_ROOT/dist"
mkdir -p "$dist_dir/0.9.6" "$dist_dir/0.9.7"

old_universal="$dist_dir/0.9.6/punchi-dock-remastered-0.9.6-universal.plasmoid"
new_universal="$dist_dir/0.9.7/punchi-dock-remastered-0.9.7-universal.plasmoid"
local_test="$dist_dir/punchi-dock-remastered-9.9.9-fedora-x86_64-local-test.plasmoid"
platform_package="$dist_dir/punchi-dock-remastered-9.9.9-fedora-x86_64.plasmoid"

touch "$old_universal" "$new_universal" "$local_test" "$platform_package"

selected="$(punchi_select_universal_package "$dist_dir" "")"
[[ "$selected" == "$new_universal" ]] \
    || fail "automatic selection did not choose the newest universal package"

selected="$(punchi_select_universal_package "$dist_dir" "$platform_package")"
[[ "$selected" == "$platform_package" ]] \
    || fail "an explicitly requested package was not preserved"

if punchi_select_universal_package "$dist_dir" "$dist_dir/missing.plasmoid" >/dev/null; then
    fail "a missing explicit package was accepted"
fi

rm -f "$old_universal" "$new_universal"
if punchi_select_universal_package "$dist_dir" "" >/dev/null; then
    fail "automatic selection fell back to a platform or local-test package"
fi

printf 'Universal package selection tests passed.\n'
