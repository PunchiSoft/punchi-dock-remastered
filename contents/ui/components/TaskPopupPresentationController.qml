import QtQml

QtObject {
    id: root

    property bool mediaEnabled: false
    property string mediaMode: "none"
    property var mediaControllerRef: null

    readonly property bool replacementRequested:
        mediaEnabled && (mediaMode === "card" || mediaMode === "fullCard")
    readonly property bool overlayRequested:
        mediaEnabled && mediaMode === "overlay"

    function controllerMatches(applicationId) {
        return !!root.mediaControllerRef
            && String(root.mediaControllerRef.applicationId || "")
                === String(applicationId || "")
    }

    function resolve(applicationId, previewAvailable) {
        const previewPresentationAvailable = !!previewAvailable
        if (root.replacementRequested) {
            if (root.controllerMatches(applicationId)
                    && root.mediaControllerRef.resolving) {
                return "waiting"
            }
            if (root.controllerMatches(applicationId)
                    && root.mediaControllerRef.available) {
                return root.mediaMode
            }
            return previewPresentationAvailable ? "preview" : "none"
        }
        if (!previewPresentationAvailable) {
            return "none"
        }
        return root.overlayRequested ? "overlay" : "preview"
    }

    function isReplacement(presentation) {
        return presentation === "card" || presentation === "fullCard"
    }
}
