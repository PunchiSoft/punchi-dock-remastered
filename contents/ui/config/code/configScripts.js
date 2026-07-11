.pragma library

function shellQuote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'"
}

function localPath(value) {
    var text = String(value || "")
    var embeddedUrlIndex = text.indexOf("file:/")
    if (embeddedUrlIndex > 0) {
        text = text.substring(embeddedUrlIndex)
    }
    if (text.indexOf("file://") === 0) {
        text = text.substring(7)
    } else if (text.indexOf("file:") === 0) {
        text = text.substring(5)
    }
    try {
        return decodeURIComponent(text)
    } catch (error) {
        return text
    }
}

function ensureConfigFileScript(configDirectory, configFile, initialJson, seedFile) {
    configDirectory = localPath(configDirectory)
    configFile = localPath(configFile)
    seedFile = localPath(seedFile || "")
    return "mkdir -p " + shellQuote(configDirectory)
        + " && if [ ! -f " + shellQuote(configFile) + " ]; then "
        + "if [ -n " + shellQuote(seedFile) + " ] && [ -f " + shellQuote(seedFile) + " ]; then "
        + "cp " + shellQuote(seedFile) + " " + shellQuote(configFile)
        + "; else printf %s " + shellQuote(initialJson) + " > " + shellQuote(configFile) + "; fi; fi"
}

function loadItemsScript(configDirectory, configFile, initialJson, seedFile) {
    configFile = localPath(configFile)
    return ensureConfigFileScript(configDirectory, configFile, initialJson, seedFile)
        + " && cat " + shellQuote(configFile)
}

function openConfigFileScript(configDirectory, configFile, initialJson, noApplicationMessage, seedFile) {
    configFile = localPath(configFile)
    return ensureConfigFileScript(configDirectory, configFile, initialJson, seedFile)
        + " && if command -v kioclient6 >/dev/null 2>&1; then kioclient6 exec " + shellQuote(configFile)
        + "; elif command -v kioclient5 >/dev/null 2>&1; then kioclient5 exec " + shellQuote(configFile)
        + "; elif command -v kde-open6 >/dev/null 2>&1; then kde-open6 " + shellQuote(configFile)
        + "; elif command -v xdg-open >/dev/null 2>&1; then xdg-open " + shellQuote(configFile)
        + "; else printf '%s\\n' " + shellQuote(noApplicationMessage) + " >&2; exit 1; fi"
}

function saveItemsScript(configDirectory, configFile, formattedJson) {
    configDirectory = localPath(configDirectory)
    configFile = localPath(configFile)
    return "mkdir -p " + shellQuote(configDirectory)
        + " && printf %s " + shellQuote(formattedJson)
        + " > " + shellQuote(configFile)
        + " && cat " + shellQuote(configFile)
}

function iconIndexScript() {
    return "roots=\"$HOME/.local/share/icons /usr/local/share/icons /usr/share/icons\"; "
        + "current_theme=\"\"; "
        + "if command -v kreadconfig6 >/dev/null 2>&1; then current_theme=$(kreadconfig6 --group Icons --key Theme 2>/dev/null); "
        + "elif command -v kreadconfig5 >/dev/null 2>&1; then current_theme=$(kreadconfig5 --group Icons --key Theme 2>/dev/null); fi; "
        + "theme_dirs() { theme_name=\"$1\"; seen_names=\" $2 \"; [ -z \"$theme_name\" ] && return; "
        + "case \"$seen_names\" in *\" $theme_name \"*) return;; esac; seen_names=\"$seen_names$theme_name \"; "
        + "for root in $roots; do [ -d \"$root/$theme_name\" ] && printf '%s\\n' \"$root/$theme_name\"; done; "
        + "inherits=\"\"; for root in $roots; do index_file=\"$root/$theme_name/index.theme\"; "
        + "[ -f \"$index_file\" ] && inherits=$(awk -F= '/^Inherits=/ { print $2; exit }' \"$index_file\") && break; done; "
        + "old_ifs=$IFS; IFS=','; for inherited in $inherits; do inherited=$(printf '%s' \"$inherited\" | sed 's/^ *//; s/ *$//'); "
        + "[ -n \"$inherited\" ] && theme_dirs \"$inherited\" \"$seen_names\"; done; IFS=$old_ifs; }; "
        + "{ theme_dirs \"$current_theme\" \"\"; theme_dirs hicolor \"\"; } "
        + "| while IFS= read -r dir; do [ -d \"$dir\" ] && find \"$dir\" -type f \\( -name '*.svg' -o -name '*.svgz' -o -name '*.png' -o -name '*.xpm' \\); done; "
        + "2>/dev/null | while IFS= read -r path; do base=${path##*/}; name=${base%.*}; printf '%s|%s\\n' \"$name\" \"$path\"; done "
        + "| awk -F'|' '!seen[$1]++' | sort | head -n 12000"
}

function trashSoundPreviewScript(configuredSound, fallbackSound, applicationName) {
    return "sound_file=" + shellQuote(configuredSound) + "; "
        + "if [ ! -f \"$sound_file\" ]; then sound_file=" + shellQuote(fallbackSound) + "; fi; "
        + "if command -v paplay >/dev/null 2>&1 && [ -f \"$sound_file\" ] "
        + "&& paplay \"$sound_file\" >/dev/null 2>&1; then :; "
        + "elif command -v pw-play >/dev/null 2>&1 && [ -f \"$sound_file\" ] "
        + "&& pw-play \"$sound_file\" >/dev/null 2>&1; then :; "
        + "elif command -v canberra-gtk-play >/dev/null 2>&1; then "
        + "canberra-gtk-play -i trash-empty -d " + shellQuote(applicationName) + " >/dev/null 2>&1; fi"
}
