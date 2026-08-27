#!/usr/bin/env bash
# Build concurrency and memory safety manager for Punchi Dock Remastered.
# Provides automatic RAM-based throttling, profile labels, and an interactive configuration submenu.

punchi_detect_total_ram_mb() {
    local mem_kb=""
    if [[ -r /proc/meminfo ]]; then
        mem_kb="$(awk '/MemTotal:/ { print $2; exit }' /proc/meminfo 2>/dev/null || true)"
        if [[ -n "$mem_kb" && "$mem_kb" =~ ^[0-9]+$ ]]; then
            printf '%s\n' "$(( mem_kb / 1024 ))"
            return 0
        fi
    fi

    if command -v free >/dev/null 2>&1; then
        local free_mb=""
        free_mb="$(free -m 2>/dev/null | awk '/^Mem:/ { print $2; exit }' || true)"
        if [[ -n "$free_mb" && "$free_mb" =~ ^[0-9]+$ ]]; then
            printf '%s\n' "$free_mb"
            return 0
        fi
    fi

    # Safe fallback: assume 4096 MB if indeterminate
    printf '4096\n'
}

punchi_format_ram_display() {
    local ram_mb="${1:-}"
    if [[ -z "$ram_mb" ]]; then
        ram_mb="$(punchi_detect_total_ram_mb)"
    fi

    if (( ram_mb >= 1024 )); then
        local gib_int=$(( ram_mb / 1024 ))
        local gib_dec=$(( (ram_mb % 1024) * 10 / 1024 ))
        printf '%d.%d GiB\n' "$gib_int" "$gib_dec"
    else
        printf '%d MiB\n' "$ram_mb"
    fi
}

punchi_detect_cpu_cores() {
    local cores=""
    if command -v nproc >/dev/null 2>&1; then
        cores="$(nproc 2>/dev/null || true)"
    fi
    if [[ -z "$cores" ]] && command -v getconf >/dev/null 2>&1; then
        cores="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
    fi
    if [[ -n "$cores" && "$cores" =~ ^[0-9]+$ && "$cores" -gt 0 ]]; then
        printf '%s\n' "$cores"
        return 0
    fi
    printf '1\n'
}

punchi_auto_concurrency_level() {
    local ram_mb=""
    local cores=""
    ram_mb="$(punchi_detect_total_ram_mb)"
    cores="$(punchi_detect_cpu_cores)"

    # Memory safety rules:
    # Heavy C++ compilation (Qt6/KF6) requires ~1.0-1.5 GB of RAM per parallel cc1plus job.
    if (( ram_mb < 4600 )); then
        printf '1\n'
    elif (( ram_mb < 8600 )); then
        if (( cores < 2 )); then
            printf '1\n'
        else
            printf '2\n'
        fi
    elif (( ram_mb < 16500 )); then
        if (( cores < 4 )); then
            printf '%s\n' "$cores"
        else
            printf '4\n'
        fi
    else
        printf '%s\n' "$cores"
    fi
}

punchi_get_concurrency_level() {
    if [[ -n "${PUNCHI_BUILD_JOBS:-}" && "${PUNCHI_BUILD_JOBS:-}" =~ ^[0-9]+$ && "${PUNCHI_BUILD_JOBS:-}" -gt 0 ]]; then
        printf '%s\n' "$PUNCHI_BUILD_JOBS"
        return 0
    fi
    if [[ -n "${CMAKE_BUILD_PARALLEL_LEVEL:-}" && "${CMAKE_BUILD_PARALLEL_LEVEL:-}" =~ ^[0-9]+$ && "${CMAKE_BUILD_PARALLEL_LEVEL:-}" -gt 0 ]]; then
        printf '%s\n' "$CMAKE_BUILD_PARALLEL_LEVEL"
        return 0
    fi
    punchi_auto_concurrency_level
}

punchi_set_concurrency_level() {
    local level="${1:-}"
    if [[ -n "$level" && "$level" =~ ^[0-9]+$ && "$level" -gt 0 ]]; then
        export PUNCHI_BUILD_JOBS="$level"
        export CMAKE_BUILD_PARALLEL_LEVEL="$level"
        export CTEST_PARALLEL_LEVEL="$level"
        return 0
    fi
    return 1
}

punchi_concurrency_profile_label() {
    local jobs="${1:-}"
    local cores=""
    local auto_level=""
    if [[ -z "$jobs" ]]; then
        jobs="$(punchi_get_concurrency_level)"
    fi
    cores="$(punchi_detect_cpu_cores)"
    auto_level="$(punchi_auto_concurrency_level)"

    if (( jobs == 1 )); then
        if command -v punchi_gettext >/dev/null 2>&1; then
            printf '%s (%s)\n' "$(punchi_gettext '1 core')" "$(punchi_gettext 'Safe Mode')"
        else
            printf '1 core (Safe Mode)\n'
        fi
    elif (( jobs == 2 )); then
        if command -v punchi_gettext >/dev/null 2>&1; then
            printf '%s (%s)\n' "$(punchi_gettext '2 cores')" "$(punchi_gettext 'Balanced Mode')"
        else
            printf '2 cores (Balanced Mode)\n'
        fi
    elif (( jobs == cores )); then
        if command -v punchi_gettext >/dev/null 2>&1; then
            printf '%d %s (%s)\n' "$jobs" "$(punchi_gettext 'cores')" "$(punchi_gettext 'Fast Mode')"
        else
            printf '%d cores (Fast Mode)\n' "$jobs"
        fi
    else
        if command -v punchi_gettext >/dev/null 2>&1; then
            printf '%d %s (%s)\n' "$jobs" "$(punchi_gettext 'cores')" "$(punchi_gettext 'Custom')"
        else
            printf '%d cores (Custom)\n' "$jobs"
        fi
    fi
}

punchi_configure_build_concurrency_interactive() {
    local ram_mb=""
    local ram_display=""
    local cores=""
    local current_jobs=""
    local choice=""
    local custom_jobs=""

    ram_mb="$(punchi_detect_total_ram_mb)"
    ram_display="$(punchi_format_ram_display "$ram_mb")"
    cores="$(punchi_detect_cpu_cores)"

    while true; do
        current_jobs="$(punchi_get_concurrency_level)"
        echo ""
        echo "=========================================================="
        if command -v punchi_gettext_line >/dev/null 2>&1; then
            punchi_gettext_line '     Build Concurrency & Memory Configuration           '
        else
            echo "     Build Concurrency & Memory Configuration           "
        fi
        echo "=========================================================="
        if command -v punchi_gettext_format >/dev/null 2>&1; then
            punchi_gettext_format 'Total system RAM: %s | CPU Cores: %s\n' "$ram_display" "$cores"
            punchi_gettext_format 'Current concurrency: %s\n' "$(punchi_concurrency_profile_label "$current_jobs")"
        else
            printf 'Total system RAM: %s | CPU Cores: %s\n' "$ram_display" "$cores"
            printf 'Current concurrency: %s\n' "$(punchi_concurrency_profile_label "$current_jobs")"
        fi
        echo ""
        if command -v punchi_gettext_line >/dev/null 2>&1; then
            punchi_gettext_line 'Select a performance profile:'
            punchi_gettext_line '  [1] Safe Mode (1 core) - Maximum stability for VMs or <= 4 GB RAM'
            punchi_gettext_line '  [2] Balanced Mode (2 cores) - Fast and stable for general usage'
            punchi_gettext_format '  [3] Fast Mode (%s cores) - Use all available CPU cores\n' "$cores"
            punchi_gettext_line '  [4] Custom (enter specific number of parallel jobs)'
            punchi_gettext_line '  [5] Back to main menu'
        else
            echo "Select a performance profile:"
            echo "  [1] Safe Mode (1 core) - Maximum stability for VMs or <= 4 GB RAM"
            echo "  [2] Balanced Mode (2 cores) - Fast and stable for general usage"
            printf '  [3] Fast Mode (%s cores) - Use all available CPU cores\n' "$cores"
            echo "  [4] Custom (enter specific number of parallel jobs)"
            echo "  [5] Back to main menu"
        fi
        echo ""
        if command -v punchi_gettext >/dev/null 2>&1; then
            printf '%s' "$(punchi_gettext 'Select an option [1-5]: ')"
        else
            printf 'Select an option [1-5]: '
        fi

        read -r choice || break
        case "$choice" in
            1)
                punchi_set_concurrency_level 1
                if command -v punchi_gettext_line >/dev/null 2>&1; then
                    punchi_gettext_line '==> Concurrency set to: Safe Mode (1 core)'
                else
                    echo "==> Concurrency set to: Safe Mode (1 core)"
                fi
                break
                ;;
            2)
                punchi_set_concurrency_level 2
                if command -v punchi_gettext_line >/dev/null 2>&1; then
                    punchi_gettext_line '==> Concurrency set to: Balanced Mode (2 cores)'
                else
                    echo "==> Concurrency set to: Balanced Mode (2 cores)"
                fi
                break
                ;;
            3)
                punchi_set_concurrency_level "$cores"
                if command -v punchi_gettext_format >/dev/null 2>&1; then
                    punchi_gettext_format '==> Concurrency set to: Fast Mode (%s cores)\n' "$cores"
                else
                    printf '==> Concurrency set to: Fast Mode (%s cores)\n' "$cores"
                fi
                break
                ;;
            4)
                if command -v punchi_gettext >/dev/null 2>&1; then
                    printf '%s' "$(punchi_gettext 'Enter number of parallel jobs [1-64]: ')"
                else
                    printf 'Enter number of parallel jobs [1-64]: '
                fi
                read -r custom_jobs || break
                if [[ "$custom_jobs" =~ ^[0-9]+$ && "$custom_jobs" -ge 1 && "$custom_jobs" -le 64 ]]; then
                    punchi_set_concurrency_level "$custom_jobs"
                    if command -v punchi_gettext_format >/dev/null 2>&1; then
                        punchi_gettext_format '==> Concurrency set to: %s cores (Custom)\n' "$custom_jobs"
                    else
                        printf '==> Concurrency set to: %s cores (Custom)\n' "$custom_jobs"
                    fi
                    break
                else
                    if command -v punchi_gettext_line >/dev/null 2>&1; then
                        punchi_gettext_line 'Error: Invalid number of jobs. Please enter an integer between 1 and 64.' >&2
                    else
                        echo "Error: Invalid number of jobs. Please enter an integer between 1 and 64." >&2
                    fi
                fi
                ;;
            5|[qQ]|"")
                break
                ;;
            *)
                if command -v punchi_gettext_format >/dev/null 2>&1; then
                    punchi_gettext_format "Error: Invalid option: '%s'\n" "$choice" >&2
                else
                    printf "Error: Invalid option: '%s'\n" "$choice" >&2
                fi
                ;;
        esac
    done
}
