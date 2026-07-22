#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
CLEAN_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/punchi-package-test.XXXXXX")"

cleanup() {
    rm -rf "$CLEAN_ROOT"
}
trap cleanup EXIT

cd "$PROJECT_ROOT"
git ls-files -z --cached --others --exclude-standard \
    | while IFS= read -r -d '' source_path; do
        if [[ -e "$source_path" ]]; then
            printf '%s\0' "$source_path"
        fi
    done \
    | tar --null -T - -cf - \
    | tar -xf - -C "$CLEAN_ROOT"

if find "$CLEAN_ROOT/contents" -name "*.so" -print -quit | grep -q .; then
    echo "The clean source unexpectedly contains native binaries" >&2
    exit 1
fi

chmod +x "$CLEAN_ROOT/scripts/lib/package-plasmoid.sh"
BUILD_DIR="$CLEAN_ROOT/build" "$CLEAN_ROOT/scripts/lib/package-plasmoid.sh"

echo "Clean-source packaging validation passed"
