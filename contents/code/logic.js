.pragma library

// Módulo central de lógica de negocio (desacoplado de la UI)

var defaultItems = [
    { type: "app", name: "Files", icon: "system-file-manager", command: "dolphin" },
    { type: "app", name: "Terminal", icon: "utilities-terminal", command: "konsole" },
    { type: "folder", name: "Favorites (Grid)", icon: "folder-favorites", layout: "grid", apps: [
        { type: "app", name: "Files", icon: "system-file-manager", command: "dolphin" },
        { type: "app", name: "Terminal", icon: "utilities-terminal", command: "konsole" },
        { type: "app", name: "Settings", icon: "preferences-system", command: "systemsettings" }
    ]},
    { type: "folder", name: "Tools (Fan)", icon: "folder-download", layout: "fan", apps: [
        { type: "app", name: "Files", icon: "system-file-manager", command: "dolphin" },
        { type: "app", name: "Terminal", icon: "utilities-terminal", command: "konsole" },
        { type: "app", name: "Settings", icon: "preferences-system", command: "systemsettings" },
        { type: "trash", name: "Trash", icon: "user-trash" }
    ]},
    { type: "calendar", name: "Calendar", icon: "x-office-calendar" },
    { type: "trash", name: "Trash", icon: "user-trash" }
];

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
    return defaultItems;
}

function shellQuote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'"
}

function detachedCommand(command) {
    var text = String(command || "").trim();
    if (text.length === 0) return "";
    
    // Si ya es un comando auto-encapsulado (como el script de la papelera)
    if (text.indexOf("kioclient") !== -1 || text.indexOf("gio open") !== -1) {
        return "sh -c " + shellQuote(text);
    }
    
    var quoted = shellQuote(text);
    return "sh -c " + shellQuote(
        "if command -v setsid >/dev/null 2>&1; then "
            + "setsid -f sh -c " + quoted + " >/dev/null 2>&1; "
            + "else nohup sh -c " + quoted + " >/dev/null 2>&1 & fi"
    );
}

function readConfigScript() {
    return "configDir=\"${XDG_CONFIG_HOME:-$HOME/.config}/punchi-dock-remastered\" && mkdir -p \"$configDir\" && if [ -f \"$configDir/dock_items.json\" ]; then cat \"$configDir/dock_items.json\"; else echo 'DEFAULT'; fi";
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
        console.log("Running: Trash");
        commandRunner(launchTrash());
        return;
    }

    if (!item.command) {
        console.warn("Invalid launch attempt:", item);
        return;
    }
    
    var command = item.command.trim();
    if (command.length === 0) return;

    console.log("Running:", command);
    
    // Delegamos la ejecución real a un DataEngine o componente que la UI nos provea
    if (typeof commandRunner === "function") {
        commandRunner(command);
    }
}
