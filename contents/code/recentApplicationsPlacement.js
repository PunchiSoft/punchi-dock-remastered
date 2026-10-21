.pragma library

// Structural position only. Recent launchers and history never enter this list.
const markerType = "recent-applications"

function markerIndex(items) {
    const source = Array.isArray(items) ? items : []
    return source.findIndex(function(item) { return item && item.type === markerType })
}

function neighborKey(item) {
    if (!item || item.type === markerType) { return "" }
    return JSON.stringify([String(item.type || "app"),
        String(item.key || item.storageId || item.launcherUrl || item.name || "").slice(0, 512)])
}

function capture(items) {
    const index = markerIndex(items)
    if (index < 0) { return "" }
    return JSON.stringify({ "index": index,
        "before": index > 0 ? neighborKey(items[index - 1]) : "",
        "after": index + 1 < items.length ? neighborKey(items[index + 1]) : "" })
}

function restoreIndex(items, storedPosition) {
    if (String(storedPosition || "").length > 4096) { return items.length }
    let position
    try { position = JSON.parse(String(storedPosition || "")) } catch (error) { return items.length }
    if (!position || typeof position !== "object") { return items.length }
    const after = items.findIndex(function(item) {
        return position.after && neighborKey(item) === position.after
    })
    if (after >= 0) { return after }
    const before = items.findIndex(function(item) {
        return position.before && neighborKey(item) === position.before
    })
    if (before >= 0) { return before + 1 }
    const index = Number(position.index)
    return Number.isInteger(index) && index >= 0 ? Math.min(items.length, index) : items.length
}

function reconcile(items, enabled, storedPosition, maximumItems) {
    const source = Array.isArray(items) ? items : []
    const index = markerIndex(source)
    const position = index >= 0 ? capture(source) : String(storedPosition || "")
    let result = source.filter(function(item, itemIndex) {
        return !item || item.type !== markerType || (enabled && itemIndex === index)
    })
    let errorCode = ""
    if (enabled && index < 0) {
        if (result.length >= maximumItems) {
            errorCode = "maximumItemCount"
        } else {
            result.splice(restoreIndex(result, position), 0,
                { "type": markerType, "name": "Recent applications" })
        }
    }
    const changed = JSON.stringify(result) !== JSON.stringify(source)
    if (!changed) { result = source }
    return { "items": result, "changed": changed, "errorCode": errorCode,
        "position": enabled && markerIndex(result) >= 0 ? capture(result) : position }
}

// The hidden marker is replaced by its presentation slots. An empty block
// adds none. The open-applications marker only takes a visual slot while its
// move handle is active; otherwise its tasks start at the marker's own slot.
function persistentVisualIndex(index, dynamicIndex, dynamicCount, recentIndex, recentSlots,
        dynamicMarkerSlot) {
    const markerSlots = dynamicMarkerSlot === true ? 1 : 0
    return index
        + (dynamicIndex >= 0 && index > dynamicIndex
            ? dynamicCount - 1 + markerSlots : 0)
        + (recentIndex >= 0 && index > recentIndex ? recentSlots - 1 : 0)
}

function recentVisualIndex(index, itemCount, dynamicIndex, dynamicCount, offset,
        dynamicMarkerSlot) {
    const markerSlots = dynamicMarkerSlot === true ? 1 : 0
    return (index >= 0 ? index : itemCount)
        + (index < 0 || (dynamicIndex >= 0 && dynamicIndex < index)
            ? dynamicCount - 1 + markerSlots : 0)
        + offset
}

function dynamicVisualIndex(index, markerSlot, recentIndex, recentSlots, offset) {
    return index + (markerSlot === true ? 1 : 0) + offset
        + (recentIndex >= 0 && recentIndex < index ? recentSlots - 1 : 0)
}
