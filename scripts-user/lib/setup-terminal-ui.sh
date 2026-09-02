#!/usr/bin/env bash
# Small terminal presentation primitives for the public setup assistant.

PUNCHI_UI_ANSI_RESET=$'\033[0m'
PUNCHI_UI_ANSI_BOLD=$'\033[1m'
PUNCHI_UI_ANSI_CYAN=$'\033[36m'
PUNCHI_UI_ANSI_GREEN=$'\033[32m'
PUNCHI_UI_ANSI_YELLOW=$'\033[33m'
PUNCHI_UI_ANSI_RED=$'\033[31m'

punchi_ui_terminal_allows_color() {
    [[ -z "${NO_COLOR+x}" && "${TERM:-}" != "dumb" ]]
}

punchi_ui_terminal_supports_color() {
    local descriptor="${1:?file descriptor is required}"
    [[ "$descriptor" =~ ^[0-9]+$ ]] || return 2
    punchi_ui_terminal_allows_color && [[ -t "$descriptor" ]]
}

punchi_ui_terminal_supports_unicode() {
    local descriptor="${1:?file descriptor is required}"
    local locale_name="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"

    [[ "$descriptor" =~ ^[0-9]+$ ]] || return 2
    [[ -t "$descriptor" && "${TERM:-}" != "dumb" ]] || return 1
    [[ "${locale_name^^}" == *UTF-8* || "${locale_name^^}" == *UTF8* ]]
}

punchi_ui_style_code() {
    case "${1:?terminal style is required}" in
        heading) printf '%s%s' "$PUNCHI_UI_ANSI_BOLD" "$PUNCHI_UI_ANSI_CYAN" ;;
        info) printf '%s' "$PUNCHI_UI_ANSI_CYAN" ;;
        success) printf '%s' "$PUNCHI_UI_ANSI_GREEN" ;;
        warning) printf '%s%s' "$PUNCHI_UI_ANSI_BOLD" "$PUNCHI_UI_ANSI_YELLOW" ;;
        error) printf '%s%s' "$PUNCHI_UI_ANSI_BOLD" "$PUNCHI_UI_ANSI_RED" ;;
        muted) printf '%s' "$PUNCHI_UI_ANSI_BOLD" ;;
        plain) printf '' ;;
        *) return 2 ;;
    esac
}

punchi_ui_sanitize_text() {
    local value="${1:-}"
    value="${value//$'\n'/ }"
    value="${value//$'\r'/ }"
    value="${value//$'\t'/ }"
    printf '%s' "$value" | LC_ALL=C tr -d '\000-\010\013\014\016-\037\177'
}

punchi_ui_write_styled_line() {
    local style="${1:?terminal style is required}"
    local descriptor="${2:?file descriptor is required}"
    local text="${3:-}"
    local style_code=""

    if punchi_ui_terminal_supports_color "$descriptor"; then
        style_code="$(punchi_ui_style_code "$style")" || return
        printf '%s%s%s\n' "$style_code" "$text" "$PUNCHI_UI_ANSI_RESET" >&"$descriptor"
    else
        printf '%s\n' "$text" >&"$descriptor"
    fi
}

punchi_ui_repeat() {
    local value="${1:?repeat value is required}"
    local count="${2:?repeat count is required}"
    local output=""
    local index=0

    for (( index = 0; index < count; index++ )); do
        output+="$value"
    done
    printf '%s' "$output"
}

punchi_ui_fit_text() {
    local text="${1:-}"
    local width="${2:?text width is required}"
    local ellipsis="${3:-...}"
    local ellipsis_length="${#ellipsis}"

    if (( ${#text} <= width )); then
        printf '%s' "$text"
    elif (( width > ellipsis_length )); then
        printf '%s%s' "${text:0:$(( width - ellipsis_length ))}" "$ellipsis"
    else
        printf '%s' "${text:0:$width}"
    fi
}

punchi_ui_box_line() {
    local descriptor="${1:?file descriptor is required}"
    local style="${2:?terminal style is required}"
    local width="${3:?box width is required}"
    local left="${4:?left border is required}"
    local right="${5:?right border is required}"
    local source_text="${6:-}"
    local text=""
    local padding=0

    text="$(punchi_ui_fit_text "$source_text" "$width" '…')"
    padding=$(( width - ${#text} ))
    punchi_ui_write_styled_line "$style" "$descriptor" \
        "$left $text$(punchi_ui_repeat ' ' "$padding") $right"
}

punchi_ui_render_header() {
    local descriptor="${1:?file descriptor is required}"
    local title=""
    local environment_line=""
    local resources_line=""
    local width=66
    local horizontal=""

    title="$(punchi_ui_sanitize_text "${2:-}")"
    environment_line="$(punchi_ui_sanitize_text "${3:-}")"
    resources_line="$(punchi_ui_sanitize_text "${4:-}")"

    if ! punchi_ui_terminal_supports_unicode "$descriptor"; then
        title="${title//·/-}"
        punchi_ui_write_styled_line heading "$descriptor" "$title"
        printf '%s\n' "$environment_line" >&"$descriptor"
        printf '%s\n' "$resources_line" >&"$descriptor"
        return 0
    fi

    horizontal="$(punchi_ui_repeat '─' "$(( width + 2 ))")"
    punchi_ui_write_styled_line info "$descriptor" "╭${horizontal}╮"
    punchi_ui_box_line "$descriptor" heading "$width" '│' '│' "$title"
    punchi_ui_write_styled_line info "$descriptor" "├${horizontal}┤"
    punchi_ui_box_line "$descriptor" plain "$width" '│' '│' "$environment_line"
    punchi_ui_box_line "$descriptor" plain "$width" '│' '│' "$resources_line"
    punchi_ui_write_styled_line info "$descriptor" "╰${horizontal}╯"
}

punchi_ui_render_phase() {
    local descriptor="${1:?file descriptor is required}"
    local index="${2:?phase index is required}"
    local total="${3:?phase total is required}"
    local state="${4:?phase state is required}"
    local label="${5:?phase label is required}"
    local status_text="${6:?phase status text is required}"
    local detail="${7:-}"
    local symbol=""
    local separator=" - "
    local style="plain"
    local rendered=""

    case "$state" in
        active)  symbol='>>'; style=info ;;
        success) symbol='OK'; style=success ;;
        warning) symbol='!!'; style=warning ;;
        error)   symbol='XX'; style=error ;;
        waiting) symbol='--'; style=plain ;;
        *) return 2 ;;
    esac

    if punchi_ui_terminal_supports_unicode "$descriptor"; then
        separator=' — '
        case "$state" in
            active)  symbol='●' ;;
            success) symbol='✓' ;;
            warning) symbol='!' ;;
            error)   symbol='✗' ;;
            waiting) symbol='○' ;;
        esac
    fi

    rendered="[$index/$total] $symbol $label: $status_text"
    if [[ -n "$detail" ]]; then
        rendered+="$separator$detail"
    fi
    punchi_ui_write_styled_line "$style" "$descriptor" "$rendered"
}
