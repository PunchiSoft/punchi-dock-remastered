.pragma library

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
