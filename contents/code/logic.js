.pragma library
.import "defaultItems.js" as DockDefaults

// Central business logic module, decoupled from the UI.

const maximumDockItemsJsonLength = 1024 * 1024
const maximumDockItemCount = 512

function withSingleMediaItem(items) {
    var result = []
    var mediaItemAdded = false
    for (var index = 0; index < items.length; index++) {
        var item = items[index]
        if (item && item.type === "media") {
            if (mediaItemAdded) {
                continue
            }
            mediaItemAdded = true
        }
        result.push(item)
    }
    return result
}

function loadItems(jsonString) {
    if (jsonString && typeof jsonString === "string" && jsonString.trim().length > 0
            && jsonString.length <= maximumDockItemsJsonLength) {
        try {
            var parsed = JSON.parse(jsonString);
            if (Array.isArray(parsed) && parsed.length <= maximumDockItemCount) {
                return withSingleMediaItem(parsed);
            }
        } catch (e) {
            console.warn("Punchi Dock: Failed to parse dockItemsJson. Falling back to defaults.", e);
        }
    }
    if (jsonString && typeof jsonString === "string"
            && jsonString.length > maximumDockItemsJsonLength) {
        console.warn("Punchi Dock: dockItemsJson exceeds the supported size. Falling back to defaults.");
    }
    return DockDefaults.cloneItems();
}

function launchItem(item, commandRunner) {
    if (!item) return;

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
