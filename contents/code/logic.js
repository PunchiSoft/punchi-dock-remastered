.pragma library
.import "defaultItems.js" as DockDefaults

// Central business logic module, decoupled from the UI.

function loadItems(jsonString) {
    if (jsonString && typeof jsonString === "string" && jsonString.trim().length > 0) {
        try {
            var parsed = JSON.parse(jsonString);
            if (Array.isArray(parsed)) {
                return parsed;
            }
        } catch (e) {
            console.warn("Punchi Dock: Failed to parse dockItemsJson. Falling back to defaults.", e);
        }
    }
    return DockDefaults.cloneItems();
}

function shellQuote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'"
}

function launchTrash() {
    return "if command -v kioclient6 >/dev/null 2>&1; then kioclient6 exec trash:/; else gio open trash:///; fi";
}

function trashUrlsScript(urls) {
    var script = "if command -v kioclient6 >/dev/null 2>&1; then client=kioclient6; else client=''; fi";
    for (var i = 0; i < urls.length; i++) {
        var url = String(urls[i]);
        if (url.length === 0) continue;
        script += "; if [ -n \"$client\" ]; then \"$client\" move " + shellQuote(url)
            + " trash:/; elif command -v gio >/dev/null 2>&1; then gio trash " + shellQuote(url) + "; fi";
    }
    return script;
}

function launchItem(item, commandRunner) {
    if (!item) return;

    if (item.type === "trash") {
        commandRunner(launchTrash());
        return;
    }

    if (!item.command) {
        console.warn("Invalid launch attempt:", item);
        return;
    }
    
    var command = item.command.trim();
    if (command.length === 0) return;

    // Delegate execution to a DataEngine or another component provided by the UI.
    if (typeof commandRunner === "function") {
        commandRunner(command);
    }
}
