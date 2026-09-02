.pragma library
.import "defaultItems.js" as DockDefaults

// Central business logic module, decoupled from the UI.

const maximumDockItemsJsonLength = 1024 * 1024
const maximumDockItemCount = 512

const singletonDockItemTypes = [
    "media", "punchimenu", "control-center", "dynamic-applications"
]

function duplicateSingletonType(items) {
    var seenTypes = {}
    for (var index = 0; index < items.length; index++) {
        var item = items[index]
        var type = String(item && item.type ? item.type : "")
        if (singletonDockItemTypes.indexOf(type) < 0) {
            continue
        }
        if (seenTypes[type]) {
            return type
        }
        seenTypes[type] = true
    }
    return ""
}

function withSingletonItems(items) {
    var result = []
    var seenTypes = {}
    for (var index = 0; index < items.length; index++) {
        var item = items[index]
        var type = String(item && item.type ? item.type : "")
        if (singletonDockItemTypes.indexOf(type) >= 0) {
            if (seenTypes[type]) {
                continue
            }
            seenTypes[type] = true
        }
        result.push(item)
    }
    return result
}

function dynamicApplicationsMarkerUpdate(items) {
    var currentItems = Array.isArray(items) ? items : []
    for (var index = 0; index < currentItems.length; index++) {
        var item = currentItems[index]
        if (item && item.type === "dynamic-applications") {
            return {
                "items": currentItems,
                "changed": false,
                "errorCode": ""
            }
        }
    }
    if (currentItems.length >= maximumDockItemCount) {
        return {
            "items": currentItems,
            "changed": false,
            "errorCode": "maximumItemCount"
        }
    }

    var updatedItems = currentItems.slice()
    updatedItems.push({
        "type": "dynamic-applications",
        "name": "Open applications"
    })
    return {
        "items": updatedItems,
        "changed": true,
        "errorCode": ""
    }
}

function loadItems(jsonString) {
    if (jsonString && typeof jsonString === "string" && jsonString.trim().length > 0
            && jsonString.length <= maximumDockItemsJsonLength) {
        try {
            var parsed = JSON.parse(jsonString);
            if (Array.isArray(parsed) && parsed.length <= maximumDockItemCount) {
                return withSingletonItems(parsed);
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
