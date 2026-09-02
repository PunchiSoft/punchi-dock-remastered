#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${1:-$PROJECT_ROOT/build-cmake}"
JOBS="${2:-1}"

if [[ ! "$JOBS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: the parallel job count must be a positive integer." >&2
    exit 2
fi

if [[ -f "$BUILD_DIR/CMakeCache.txt" ]]; then
    cached_src="$(grep '^CMAKE_HOME_DIRECTORY:' "$BUILD_DIR/CMakeCache.txt" | cut -d'=' -f2 || true)"
    if [[ -n "$cached_src" && "$cached_src" != "$PROJECT_ROOT" ]]; then
        rm -rf "$BUILD_DIR"
    fi
fi

cmake \
    -S "$PROJECT_ROOT" \
    -B "$BUILD_DIR" \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" --parallel "$JOBS"

echo "CMake build completed: $BUILD_DIR"
echo "Install with: cmake --install $BUILD_DIR"
