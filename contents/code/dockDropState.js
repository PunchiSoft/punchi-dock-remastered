.pragma library

// Returns undefined for drop states that do not belong to launcher handling.
function launcherDropAcceptance(state) {
    switch (String(state || "")) {
    case "launcherAcceptable":
    case "launcherContainmentAcceptable":
        return true
    case "rejected":
    case "launcherContainmentRejected":
        return false
    default:
        return undefined
    }
}
