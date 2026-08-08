import QtQuick
import org.kde.kirigami as Kirigami

FocusScope {
    id: root

    property var layoutModel: null
    property var layoutController: null
    property bool motionEnabled: true
    property real iconScale: 1.0
    property var allowedExternalFocusItems: []
    property bool detailedApplicationFeedback: false
    property real applicationHighlightOpacity: 0.30
    property real applicationCornerRadiusScale: 1.0
    property real applicationHoverScale: 1.0
    property bool returnToFolderAfterMemberRemoval: false
    property bool compactLayout: false
    property rect backdropGeometry: Qt.rect(0, 0, -1, -1)
    property real backdropRadius: 0

    property string viewMode: ""
    property string activeFolderId: ""
    property var activeFolderInfo: ({})
    property string returnNodeId: ""
    property string actionOriginFolderId: ""
    property bool actionOpenedFromFolder: false
    property bool closing: false
    property bool notifyAfterClose: false
    property string pendingCloseNodeId: ""

    readonly property bool active: modalSurface.active
    readonly property bool useWidgetModalProfile: viewMode === "action"
        || viewMode === "folder"
    readonly property int activeMemberCount: {
        const members = activeFolderInfo.members
            || activeFolderInfo.folderMembers || []
        return members.length || 0
    }
    readonly property int compactFolderColumnCount: Math.max(2,
        Math.min(5, Math.ceil(Math.sqrt(Math.max(1,
            activeMemberCount)))))
    readonly property int compactFolderRowCount: Math.max(1,
        Math.ceil(Math.max(1, activeMemberCount)
            / compactFolderColumnCount))
    readonly property real compactFolderPreferredWidth: Math.max(
        Kirigami.Units.gridUnit * 20,
        Math.min(Kirigami.Units.gridUnit * 34,
            Kirigami.Units.gridUnit
                * (compactFolderColumnCount * 6 + 4)))
    readonly property real compactFolderPreferredHeight: Math.max(
        Kirigami.Units.gridUnit * 14,
        Math.min(Kirigami.Units.gridUnit * 26,
            Kirigami.Units.gridUnit
                * (compactFolderRowCount * 6 + 6)))

    signal launchRequested(string storageId)
    signal applicationContextRequested(var sourceItem, var application,
        string folderId, real x, real y)
    signal closeRequested(string nodeId)

    function folderInfo(requestedFolderId) {
        if (!layoutModel || requestedFolderId.length === 0) {
            return ({ "found": false })
        }
        if (typeof layoutModel.folderInfo === "function") {
            return layoutModel.folderInfo(requestedFolderId)
        }
        const nodes = layoutModel.nodes || []
        for (let index = 0; index < nodes.length; ++index) {
            const node = nodes[index]
            if (node && node.nodeType === "folder"
                    && String(node.folderId || "")
                        === requestedFolderId) {
                return {
                    "found": true,
                    "folderId": String(node.folderId || ""),
                    "nodeId": String(node.nodeId || ""),
                    "label": String(node.folderLabel || ""),
                    "members": node.folderMembers || [],
                    "previewIcons": node.folderPreviewIcons || [],
                    "visibleMemberCount": Number(
                        node.folderMemberCount || 0),
                    "canAcceptMembers": true
                }
            }
        }
        return ({ "found": false })
    }

    function applicationNodeId(application) {
        if (!application) {
            return ""
        }
        const storageId = String(application.appStorageId
            || application.storageId || "")
        return storageId.length > 0 ? "application:" + storageId : ""
    }

    function showSurface(mode) {
        closing = false
        notifyAfterClose = false
        pendingCloseNodeId = ""
        viewMode = mode
        modalSurface.active = true
    }

    function openFolder(folderId) {
        const requestedFolderId = String(folderId || "")
        const info = folderInfo(requestedFolderId)
        if (!info || info.found !== true || info.visible === false) {
            return false
        }

        activeFolderId = requestedFolderId
        activeFolderInfo = info
        returnNodeId = String(info.nodeId
            || ("folder:" + requestedFolderId))
        actionOriginFolderId = ""
        actionOpenedFromFolder = false
        showSurface("folder")
        Qt.callLater(folderView.focusInitial)
        return true
    }

    function beginCreate(application) {
        returnNodeId = applicationNodeId(application)
        actionOriginFolderId = ""
        actionOpenedFromFolder = false
        showSurface("action")
        actionView.beginCreate(application)
    }

    function beginCreateFromStorageIds(storageIds) {
        const requestedIds = storageIds instanceof Array ? storageIds : []
        if (requestedIds.length !== 2) {
            return false
        }
        returnNodeId = "application:" + String(requestedIds[0] || "")
        actionOriginFolderId = ""
        actionOpenedFromFolder = false
        if (!actionView.beginCreateFromStorageIds(requestedIds)) {
            return false
        }
        showSurface("action")
        return true
    }

    function beginMove(application) {
        returnNodeId = applicationNodeId(application)
        actionOriginFolderId = ""
        actionOpenedFromFolder = false
        showSurface("action")
        actionView.beginMove(application)
    }

    function beginRename(folderId) {
        const requestedFolderId = String(folderId || "")
        actionOpenedFromFolder = viewMode === "folder"
            && activeFolderId === requestedFolderId
        actionOriginFolderId = actionOpenedFromFolder
            ? requestedFolderId : ""
        returnNodeId = "folder:" + requestedFolderId
        showSurface("action")
        actionView.beginRename(requestedFolderId)
    }

    function beginDissolve(folderId) {
        const requestedFolderId = String(folderId || "")
        actionOpenedFromFolder = viewMode === "folder"
            && activeFolderId === requestedFolderId
        actionOriginFolderId = actionOpenedFromFolder
            ? requestedFolderId : ""
        returnNodeId = "folder:" + requestedFolderId
        showSurface("action")
        actionView.beginDissolve(requestedFolderId)
    }

    function beginRemove(application, folderId) {
        const requestedFolderId = String(folderId || "")
        actionOpenedFromFolder = viewMode === "folder"
            && activeFolderId === requestedFolderId
        actionOriginFolderId = actionOpenedFromFolder
            ? requestedFolderId : ""
        returnNodeId = applicationNodeId(application)
        showSurface("action")
        actionView.beginRemove(application, requestedFolderId)
    }

    function dismiss(focusNodeId, notify) {
        if (!modalSurface.active && !modalSurface.visible) {
            if (notify) {
                closeRequested(String(focusNodeId || ""))
            }
            finalizeReset()
            return
        }
        closing = true
        notifyAfterClose = notify
        pendingCloseNodeId = String(focusNodeId || "")
        modalSurface.active = false
        if (!motionEnabled) {
            finalizeClose()
        }
    }

    function finalizeClose() {
        if (!closing) {
            return
        }
        const shouldNotify = notifyAfterClose
        const focusNodeId = pendingCloseNodeId
        finalizeReset()
        if (shouldNotify) {
            closeRequested(focusNodeId)
        }
    }

    function finalizeReset() {
        closing = false
        notifyAfterClose = false
        pendingCloseNodeId = ""
        viewMode = ""
        activeFolderId = ""
        activeFolderInfo = ({})
        actionOriginFolderId = ""
        actionOpenedFromFolder = false
        returnNodeId = ""
        folderView.reset()
        actionView.reset()
    }

    function reset() {
        dismiss("", false)
    }

    function closeCurrentView() {
        if (viewMode === "action" && actionView.waitingForCommit) {
            return
        }
        dismiss(returnNodeId, true)
    }

    function restoreFocus() {
        if (!active) {
            return
        }
        if (viewMode === "folder") {
            Qt.callLater(function() {
                if (root.active && root.viewMode === "folder") {
                    folderView.focusCurrentItem()
                }
            })
        }
    }

    function cancelAction() {
        if (actionView.waitingForCommit) {
            return
        }
        if (actionOpenedFromFolder
                && actionOriginFolderId.length > 0
                && openFolder(actionOriginFolderId)) {
            return
        }
        dismiss(returnNodeId, true)
    }

    function completeAction(result, focusNodeId) {
        const targetNodeId = String(focusNodeId || returnNodeId || "")
        if (actionView.mode === "rename" && actionOpenedFromFolder
                && actionOriginFolderId.length > 0
                && openFolder(actionOriginFolderId)) {
            return
        }
        if (actionView.mode === "remove"
                && returnToFolderAfterMemberRemoval
                && actionOpenedFromFolder
                && actionOriginFolderId.length > 0
                && openFolder(actionOriginFolderId)) {
            return
        }
        if ((actionView.mode === "create" || actionView.mode === "move")
                && targetNodeId.indexOf("folder:") === 0) {
            const targetFolderId = targetNodeId.slice("folder:".length)
            if (openFolder(targetFolderId)) {
                return
            }
        }
        dismiss(targetNodeId, true)
    }

    PunchiMenuModalSurface {
        id: modalSurface
        anchors.fill: parent
        motionEnabled: root.motionEnabled
        preferredWidth: Math.min(root.width
            - Kirigami.Units.largeSpacing * 2,
            root.compactLayout
                ? root.viewMode === "folder"
                    ? root.compactFolderPreferredWidth
                    : Kirigami.Units.gridUnit * 34
                : Kirigami.Units.gridUnit * 42)
        preferredHeight: Math.min(root.height
            - Kirigami.Units.largeSpacing * 2,
            root.compactLayout
                ? root.viewMode === "folder"
                    ? root.compactFolderPreferredHeight
                    : Kirigami.Units.gridUnit * 26
                : Kirigami.Units.gridUnit * 34)
        maximumWidth: root.width - Kirigami.Units.largeSpacing * 2
        maximumHeight: root.height - Kirigami.Units.largeSpacing * 2
        panelBackgroundImagePath: root.useWidgetModalProfile
            ? "widgets/background"
            : root.viewMode === "action"
                ? "solid/dialogs/background" : "dialogs/background"
        panelBackgroundOpacity: 1.0
        panelShadowEnabled: root.viewMode === "action"
            && !root.useWidgetModalProfile
        backdropOpacity: 0.64
        backdropGeometry: root.backdropGeometry
        backdropRadius: root.backdropRadius
        allowedExternalFocusItems: root.allowedExternalFocusItems
        accessibleName: root.viewMode === "folder"
            ? folderView.effectiveLabel : actionView.operationTitle()

        onDismissed: root.closeCurrentView()
        onConcealed: root.finalizeClose()

        PunchiMenuFolderView {
            id: folderView
            anchors.fill: parent
            visible: root.viewMode === "folder"
            enabled: visible
            folderId: root.activeFolderId
            folderLabel: String(root.activeFolderInfo.label
                || root.activeFolderInfo.folderLabel || "")
            members: root.activeFolderInfo.members
                || root.activeFolderInfo.folderMembers || []
            motionEnabled: root.motionEnabled
            iconScale: root.iconScale
            detailedApplicationFeedback: root.detailedApplicationFeedback
            applicationHighlightOpacity: root.applicationHighlightOpacity
            applicationCornerRadiusScale:
                root.applicationCornerRadiusScale
            applicationHoverScale: root.applicationHoverScale

            onLaunchRequested: function(storageId) {
                root.launchRequested(storageId)
                root.dismiss(root.returnNodeId, false)
            }
            onApplicationContextRequested: function(sourceItem, application,
                    folderId, x, y) {
                root.applicationContextRequested(sourceItem, application,
                    folderId, x, y)
            }
            onCloseRequested: root.closeCurrentView()
            onRenameRequested: function(folderId) {
                root.beginRename(folderId)
            }
        }

        PunchiMenuFolderActionView {
            id: actionView
            anchors.fill: parent
            visible: root.viewMode === "action"
            enabled: visible
            layoutModel: root.layoutModel
            layoutController: root.layoutController
            motionEnabled: root.motionEnabled
            iconScale: root.iconScale

            onCancelRequested: root.cancelAction()
            onOperationFinished: function(result, focusNodeId) {
                root.completeAction(result, focusNodeId)
            }
        }
    }

    Connections {
        target: root.layoutController
        enabled: target !== null

        function onTransactionCommitted(transactionId, operation,
                subjectId) {
            if (root.viewMode === "action"
                    && actionView.waitsForTransaction(transactionId)) {
                actionView.completeCommitted(subjectId)
            }
        }

        function onTransactionFailed(transactionId, operation,
                errorCode) {
            if (root.viewMode === "action"
                    && actionView.waitsForTransaction(transactionId)) {
                actionView.completeFailed(errorCode)
            }
        }
    }

    Connections {
        target: root.layoutModel
        enabled: target !== null

        function onNodesChanged() {
            if (root.viewMode === "action") {
                actionView.refreshData()
                return
            }
            if (root.viewMode !== "folder"
                    || root.activeFolderId.length === 0) {
                return
            }
            const info = root.folderInfo(root.activeFolderId)
            if (info && info.found === true && info.visible !== false) {
                root.activeFolderInfo = info
            } else {
                root.dismiss(root.returnNodeId, true)
            }
        }
    }
}
