.pragma library

function supportsVirtualDesktopInfo(platformPluginName) {
    const pluginName = String(platformPluginName || "")
    return pluginName === "xcb" || pluginName.indexOf("wayland") === 0
}

function setOptionalProperty(target, propertyName, value) {
    if (!target) {
        return false
    }

    try {
        if (target[propertyName] === undefined) {
            return false
        }
        target[propertyName] = value
        return true
    } catch (error) {
        return false
    }
}
