#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/setup-logging.sh
source "$SCRIPT_DIR/lib/setup-logging.sh"

PUNCHI_LOG_DIR="${PUNCHI_LOG_DIR:-$PROJECT_ROOT/docs/logs/kubuntu}"
punchi_run_setup_with_log "kubuntu" "$SCRIPT_DIR/distro/kubuntu-setup.sh" "$@"
