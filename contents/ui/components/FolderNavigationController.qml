pragma ComponentBehavior: Bound
import QtQuick
import "../org/punchi/dock" as Punchi

QtObject {
    id: root
    // Reading the root live belongs to the sync choice: a synced container
    // lists the folder, a frozen one keeps its snapshot. Entering and going
    // back is the browsing choice and works from either root, so the two are
    // independent.
    property bool enabled: false
    property bool navigationEnabled: false
    // Entering subfolders is opt-in. Turning it off ends the navigation even
    // though the root listing keeps following the folder, so re-enabling it
    // starts again at the container folder instead of an abandoned subfolder.
    property bool navigationAllowed: true
    // The view may retain the last child listing during its exit transition.
    // Session cancellation still releases it immediately through enabled.
    property bool retainChildModel: false
    property string rootPath: ""
    property string rootName: ""
    property string sortMode: "modified"
    property var history: []
    property int pendingIndex: 0
    property real pendingScroll: 0
    property bool pendingRestore: false
    readonly property bool hasChild: history.length > 0
    readonly property string breadcrumb: {
        const labels = [root.rootName]
        for (let i = 0; i < root.history.length; ++i) {
            labels.push(String(root.history[i].label || ""))
        }
        return labels.join(" / ")
    }
    readonly property Punchi.FolderNavigationModel rootModel: Punchi.FolderNavigationModel {
        enabled: root.enabled
        rootPath: root.rootPath
        sortMode: root.sortMode
        onStateChanged: {
            if (!loading && root.enabled && !root.hasChild) {
                root.restoreRequested(true, 0, 0)
            }
        }
    }
    readonly property Punchi.FolderNavigationModel childModel: Punchi.FolderNavigationModel {
        enabled: root.navigationEnabled && (root.hasChild || root.retainChildModel)
        rootPath: root.rootPath
        sortMode: root.sortMode
        onStateChanged: {
            if (!loading && root.pendingRestore) {
                root.pendingRestore = false
                root.restoreRequested(false, root.pendingIndex, root.pendingScroll)
            }
        }
    }
    signal restoreRequested(bool primary, int index, real scroll)
    signal navigationChanged()

    onEnabledChanged: reset()
    onNavigationAllowedChanged: {
        if (!root.navigationAllowed) {
            reset()
        }
    }
    onRootPathChanged: reset()

    function reset() {
        root.pendingRestore = false
        root.history = []
        root.navigationChanged()
    }

    function enter(entry, index, scroll, primary) {
        // The root model stays rooted at the container folder even when sync
        // disables its listing. Resolve first-level entries there so a stale
        // child-model location from an earlier browsing session cannot reject
        // a directory in a frozen snapshot.
        const model = primary ? root.rootModel : root.childModel
        const target = model.directoryTarget(entry)
        if (!root.navigationEnabled || !target.length
                || (!primary && root.history.length >= model.maximumDepth)) {
            return false
        }
        const path = primary ? [] : root.history.slice()
        for (let i = 0; i < path.length; ++i) {
            if (path[i].location === target) {
                return false
            }
        }
        path.push({
            "location": model.location,
            "index": index,
            "scroll": scroll,
            "label": String(entry.name || "")
        })
        root.pendingIndex = 0
        root.pendingScroll = 0
        root.pendingRestore = false
        // Set the path while disabled on the first entry, then enable its model.
        root.childModel.location = target
        root.history = path
        root.pendingRestore = true
        root.navigationChanged()
        if (!root.childModel.loading && root.pendingRestore) {
            root.pendingRestore = false
            root.restoreRequested(false, 0, 0)
        }
        return true
    }

    function back() {
        if (!root.hasChild) {
            return
        }
        const path = root.history.slice()
        const previous = path.pop()
        root.pendingIndex = Number(previous.index)
        root.pendingScroll = Number(previous.scroll)
        root.pendingRestore = path.length > 0
        root.history = path
        if (path.length === 0) {
            root.restoreRequested(true, root.pendingIndex, root.pendingScroll)
        } else {
            root.childModel.location = String(previous.location)
        }
        root.navigationChanged()
    }
}
