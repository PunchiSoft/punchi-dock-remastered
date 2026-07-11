.pragma library

// Shared color presets used by configuration color pickers.
function colorChoices() {
    return []
}

function fileName(path) {
    var text = String(path || "")
    var slash = text.lastIndexOf("/")
    return slash >= 0 ? text.substring(slash + 1) : text
}

function shellQuote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'"
}
