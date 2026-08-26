#!/usr/bin/env bash

PUNCHI_SETUP_TRANSLATION_DOMAIN="plasma_applet_org.kde.plasma.punchi-dock-remastered"
PUNCHI_SETUP_LANGUAGE="en"
PUNCHI_SETUP_LANG_OVERRIDE=""
PUNCHI_SETUP_LOCALE_READY=0

punchi_normalize_setup_language() {
    local requested="${1:-en}"
    requested="${requested,,}"
    requested="${requested%%.*}"
    requested="${requested//-/_}"

    case "$requested" in
        en|en_*) printf 'en\n' ;;
        es|es_*) printf 'es\n' ;;
        de|de_*) printf 'de\n' ;;
        pt|pt_*) printf 'pt_BR\n' ;;
        *) return 1 ;;
    esac
}

punchi_set_setup_language_override() {
    local requested="${1:-}"
    local normalized=""

    normalized="$(punchi_normalize_setup_language "$requested")" || {
        printf 'Error: unsupported language code: %s (supported: en, es, de, pt_BR)\n' "$requested" >&2
        return 1
    }
    PUNCHI_SETUP_LANG_OVERRIDE="$normalized"
}

punchi_scan_setup_language_option() {
    local -a arguments=("$@")
    local index=0
    local argument=""

    while (( index < ${#arguments[@]} )); do
        argument="${arguments[$index]}"
        case "$argument" in
            --lang)
                (( index + 1 < ${#arguments[@]} )) || {
                    echo "Error: --lang requires a language code." >&2
                    return 1
                }
                punchi_set_setup_language_override "${arguments[$((index + 1))]}" || return
                ((index += 2))
                ;;
            --lang=*)
                punchi_set_setup_language_override "${argument#--lang=}" || return
                ((index += 1))
                ;;
            *)
                ((index += 1))
                ;;
        esac
    done
}

punchi_prepare_setup_localization() {
    local project_root="${1:?project root is required}"
    local requested=""
    local po_file=""
    local locale_root="$project_root/build/user-local/setup-locale"
    local mo_dir=""
    local mo_file=""

    requested="${PUNCHI_SETUP_LANG_OVERRIDE:-${PUNCHI_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-en}}}}}"
    PUNCHI_SETUP_LANGUAGE="$(punchi_normalize_setup_language "$requested" 2>/dev/null || printf 'en\n')"

    export TEXTDOMAIN="$PUNCHI_SETUP_TRANSLATION_DOMAIN"
    export PUNCHI_LANG="$PUNCHI_SETUP_LANGUAGE"
    export LANGUAGE="$PUNCHI_SETUP_LANGUAGE"
    PUNCHI_SETUP_LOCALE_READY=0

    if [[ "$PUNCHI_SETUP_LANGUAGE" == "en" ]]; then
        return 0
    fi

    po_file="$project_root/po/$PUNCHI_SETUP_LANGUAGE.po"
    mo_dir="$locale_root/$PUNCHI_SETUP_LANGUAGE/LC_MESSAGES"
    mo_file="$mo_dir/$PUNCHI_SETUP_TRANSLATION_DOMAIN.mo"

    if ! command -v gettext >/dev/null 2>&1 \
        || ! command -v msgfmt >/dev/null 2>&1 \
        || [[ ! -f "$po_file" ]]; then
        echo "Notice: localized setup messages are unavailable; using English." >&2
        PUNCHI_SETUP_LANGUAGE="en"
        export PUNCHI_LANG="en"
        export LANGUAGE="en"
        return 0
    fi

    mkdir -p "$mo_dir"
    if [[ ! -f "$mo_file" || "$po_file" -nt "$mo_file" ]]; then
        msgfmt --check --check-format --output-file="$mo_file" "$po_file"
    fi

    export TEXTDOMAINDIR="$locale_root"
    PUNCHI_SETUP_LOCALE_READY=1
}

punchi_gettext() {
    local source_text="$1"
    if (( PUNCHI_SETUP_LOCALE_READY == 1 )); then
        gettext "$source_text"
    else
        printf '%s' "$source_text"
    fi
}

punchi_gettext_line() {
    punchi_gettext "$1"
    printf '\n'
}

punchi_gettext_format() {
    local source_format="$1"
    shift
    local translated_format=""
    translated_format="$(punchi_gettext "$source_format")"
    printf -- "$translated_format" "$@"
}
