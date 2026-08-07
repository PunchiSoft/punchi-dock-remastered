import QtQuick

// Non-visual state and controller adapter for folder actions.
// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
QtObject {
    id: root

    property var layoutModel: null
    property var layoutController: null
    property string mode: ""
    property var sourceApplication: ({})
    property string folderId: ""
    property var folderData: ({})
    property var applicationCandidates: []
    property var availableFolders: []
    property var selectedStorageIds: []
    property string selectedFolderId: ""
    property string createLabel: ""
    property string renameLabel: ""
    property bool waitingForCommit: false
    property var submittedResult: ({})
    property string requestedFocusNodeId: ""
    property string errorMessage: ""

    readonly property int maximumFolderMembers: 128
    readonly property bool busy: waitingForCommit
        || (layoutController && layoutController.transactionPending)
    readonly property string sourceStorageId:
        applicationStorageId(sourceApplication)
    readonly property string sourceName: applicationName(sourceApplication)
    readonly property string effectiveFolderLabel:
        String(folderData.label || folderData.folderLabel
            || i18nc("@label", "Applications folder"))

    signal operationFinished(var result, string focusNodeId)
    signal failureReported()

    function applicationStorageId(application) {
        if (!application) {
            return ""
        }
        return String(application.appStorageId
            || application.storageId || "")
    }

    function applicationName(application) {
        if (!application) {
            return i18nc("@label", "Application")
        }
        return String(application.appName || application.name
            || applicationStorageId(application)
            || i18nc("@label", "Application"))
    }

    function queryFolderInfo(requestedFolderId) {
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

    function queryStandaloneApplications() {
        if (!layoutModel) {
            return []
        }
        const result = []
        const seenStorageIds = []
        const nodes = layoutModel.nodes || []
        for (let index = 0; index < nodes.length; ++index) {
            const node = nodes[index]
            if (!node || node.nodeType !== "application") {
                continue
            }
            const storageId = applicationStorageId(node)
            if (storageId.length === 0
                    || seenStorageIds.indexOf(storageId) >= 0) {
                continue
            }
            seenStorageIds.push(storageId)
            result.push(node)
        }
        if (sourceStorageId.length > 0
                && seenStorageIds.indexOf(sourceStorageId) < 0) {
            result.unshift(sourceApplication)
        }
        return result
    }

    function queryFolderChoices() {
        if (!layoutModel) {
            return []
        }
        let choices = []
        if (typeof layoutModel.folderChoices === "function") {
            choices = layoutModel.folderChoices() || []
        } else {
            const nodes = layoutModel.nodes || []
            for (let index = 0; index < nodes.length; ++index) {
                const node = nodes[index]
                if (node && node.nodeType === "folder") {
                    choices.push({
                        "folderId": String(node.folderId || ""),
                        "nodeId": String(node.nodeId || ""),
                        "label": String(node.folderLabel || ""),
                        "visibleMemberCount": Number(
                            node.folderMemberCount || 0),
                        "canAcceptMembers": true
                    })
                }
            }
        }

        if (sourceStorageId.length > 0
                && typeof layoutModel.applicationPlacement === "function") {
            const placement = layoutModel.applicationPlacement(
                sourceStorageId)
            if (!placement || placement.placement !== "standalone") {
                return []
            }
        }

        const result = []
        for (let choiceIndex = 0; choiceIndex < choices.length;
                ++choiceIndex) {
            const choice = choices[choiceIndex]
            const choiceId = String(choice.folderId || "")
            if (choiceId.length === 0
                    || choice.canAcceptMembers === false) {
                continue
            }
            result.push(choice)
        }
        return result
    }

    function containsStorageId(storageId) {
        return selectedStorageIds.indexOf(storageId) >= 0
    }

    function setStorageIdSelected(storageId, selected) {
        if (storageId.length === 0 || storageId === sourceStorageId) {
            return
        }
        const next = selectedStorageIds.slice()
        const currentIndex = next.indexOf(storageId)
        if (selected && currentIndex < 0) {
            if (next.length >= maximumFolderMembers) {
                return
            }
            next.push(storageId)
        } else if (!selected && currentIndex >= 0) {
            next.splice(currentIndex, 1)
        }
        selectedStorageIds = next
        errorMessage = ""
    }

    function beginCreate(application) {
        reset()
        mode = "create"
        sourceApplication = application || ({})
        const initialStorageId = applicationStorageId(sourceApplication)
        selectedStorageIds = initialStorageId.length > 0
            ? [initialStorageId] : []
        applicationCandidates = queryStandaloneApplications()
    }

    function beginMove(application) {
        reset()
        mode = "move"
        sourceApplication = application || ({})
        availableFolders = queryFolderChoices()
    }

    function beginRename(requestedFolderId) {
        reset()
        mode = "rename"
        folderId = requestedFolderId
        folderData = queryFolderInfo(folderId)
        renameLabel = effectiveFolderLabel
    }

    function beginDissolve(requestedFolderId) {
        reset()
        mode = "dissolve"
        folderId = requestedFolderId
        folderData = queryFolderInfo(folderId)
    }

    function beginRemove(application, requestedFolderId) {
        reset()
        mode = "remove"
        sourceApplication = application || ({})
        folderId = requestedFolderId
        folderData = queryFolderInfo(folderId)
    }

    function refreshData() {
        if (mode === "create") {
            applicationCandidates = queryStandaloneApplications()
        } else if (mode === "move") {
            availableFolders = queryFolderChoices()
        } else if (folderId.length > 0) {
            folderData = queryFolderInfo(folderId)
        }
    }

    function reset() {
        mode = ""
        sourceApplication = ({})
        folderId = ""
        folderData = ({})
        applicationCandidates = []
        availableFolders = []
        selectedStorageIds = []
        selectedFolderId = ""
        createLabel = ""
        renameLabel = ""
        waitingForCommit = false
        submittedResult = ({})
        requestedFocusNodeId = ""
        errorMessage = ""
    }

    function operationTitle() {
        switch (mode) {
        case "create":
            return i18nc("@title", "Create application folder")
        case "move":
            return i18nc("@title", "Move to a folder")
        case "rename":
            return i18nc("@title", "Rename folder")
        case "dissolve":
            return i18nc("@title", "Dissolve folder")
        case "remove":
            return i18nc("@title", "Remove from folder")
        default:
            return i18nc("@title", "Application folder")
        }
    }

    function operationDescription() {
        switch (mode) {
        case "create":
            return i18nc("@info",
                "Choose a name and at least one more application.")
        case "move":
            return i18nc("@info", "Choose the destination folder for %1.",
                sourceName)
        case "rename":
            return i18nc("@info", "Enter a new name for %1.",
                effectiveFolderLabel)
        case "dissolve":
            return i18nc("@info",
                "Applications will return to the main list. No application will be deleted.")
        case "remove":
            if (Number(folderData.storedMemberCount
                    || folderData.folderMemberCount || 0) === 2) {
                return i18nc("@info",
                    "Removing %1 will dissolve this two-application folder. Both applications will return to the main list, and neither application will be deleted.",
                    sourceName)
            }
            return i18nc("@info",
                "%1 will return to the main list. The application will not be deleted.",
                sourceName)
        default:
            return ""
        }
    }

    function primaryActionText() {
        switch (mode) {
        case "create":
            return i18nc("@action:button", "Create")
        case "move":
            return i18nc("@action:button", "Move")
        case "rename":
            return i18nc("@action:button", "Rename")
        case "dissolve":
            return i18nc("@action:button", "Dissolve")
        case "remove":
            return i18nc("@action:button", "Remove")
        default:
            return i18nc("@action:button", "Apply")
        }
    }

    function canSubmit() {
        if (busy) {
            return false
        }
        if (mode === "create") {
            return selectedStorageIds.length >= 2
                && selectedStorageIds.length <= maximumFolderMembers
                && createLabel.trim().length > 0
        }
        if (mode === "move") {
            return sourceStorageId.length > 0
                && selectedFolderId.length > 0
        }
        if (mode === "rename") {
            return folderId.length > 0 && renameLabel.trim().length > 0
        }
        if (mode === "dissolve") {
            return folderId.length > 0
        }
        if (mode === "remove") {
            return folderId.length > 0 && sourceStorageId.length > 0
        }
        return false
    }

    function errorText(errorCode) {
        if (errorCode === "layout-conflict") {
            return i18nc("@info",
                "The application layout changed. Review it and try again.")
        }
        if (errorCode === "transaction-active") {
            return i18nc("@info",
                "Another folder change is still being saved.")
        }
        return i18nc("@info",
            "The folder change could not be applied. Please try again.")
    }

    function finishAccepted(result) {
        let focusNodeId = requestedFocusNodeId
        const subjectId = String(result.subjectId || "")
        if (mode === "create" && subjectId.length > 0) {
            focusNodeId = "folder:" + subjectId
        }
        waitingForCommit = false
        operationFinished(result, focusNodeId)
    }

    function completeCommitted(subjectId) {
        if (!waitingForCommit) {
            return
        }
        const result = ({})
        for (const key in submittedResult) {
            result[key] = submittedResult[key]
        }
        if (subjectId && String(subjectId).length > 0) {
            result.subjectId = String(subjectId)
        }
        result.accepted = true
        finishAccepted(result)
    }

    function completeFailed(errorCode) {
        if (!waitingForCommit) {
            return
        }
        waitingForCommit = false
        errorMessage = errorText(String(errorCode || ""))
        failureReported()
    }

    function submit() {
        if (!canSubmit() || !layoutController) {
            return
        }

        let result = ({ "accepted": false,
            "errorCode": "operation-unavailable" })
        requestedFocusNodeId = ""
        if (mode === "create"
                && typeof layoutController.requestCreateFolderFromApplications
                    === "function") {
            result = layoutController.requestCreateFolderFromApplications(
                selectedStorageIds, createLabel.trim())
        } else if (mode === "move"
                && typeof layoutController.requestAddApplicationToFolder
                    === "function") {
            requestedFocusNodeId = "folder:" + selectedFolderId
            result = layoutController.requestAddApplicationToFolder(
                sourceStorageId, selectedFolderId)
        } else if (mode === "rename"
                && typeof layoutController.requestRenameFolder
                    === "function") {
            requestedFocusNodeId = "folder:" + folderId
            result = layoutController.requestRenameFolder(folderId,
                renameLabel.trim())
        } else if (mode === "dissolve"
                && typeof layoutController.requestDissolveFolder
                    === "function") {
            result = layoutController.requestDissolveFolder(folderId, true)
        } else if (mode === "remove"
                && typeof layoutController.requestRemoveApplicationFromFolder
                    === "function") {
            requestedFocusNodeId = "application:" + sourceStorageId
            result = layoutController.requestRemoveApplicationFromFolder(
                sourceStorageId, folderId, true)
        }

        if (!result || result.accepted !== true) {
            errorMessage = errorText(result ? result.errorCode : "")
            failureReported()
            return
        }

        errorMessage = ""
        submittedResult = result
        if (layoutController.transactionPending) {
            waitingForCommit = true
            return
        }
        const synchronousError = String(
            layoutController.lastErrorCode || "")
        if (synchronousError.length > 0) {
            errorMessage = errorText(synchronousError)
            failureReported()
            return
        }
        finishAccepted(result)
    }
}
// qmllint enable unqualified
