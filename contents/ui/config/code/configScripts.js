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
