import QtQuick

FocusScope {
    id: root

    property var layoutModel: null
    property var layoutController: null
    property bool motionEnabled: true
    property real iconScale: 1.0

    readonly property alias mode: actionState.mode
    readonly property alias waitingForCommit: actionState.waitingForCommit

    signal cancelRequested()
    signal operationFinished(var result, string focusNodeId)

    function showAction(beginFunction) {
        beginFunction()
        Qt.callLater(actionContent.focusInitial)
    }

    function beginCreate(application) {
        showAction(function() {
            actionState.beginCreate(application)
        })
    }

    function beginMove(application) {
        showAction(function() {
            actionState.beginMove(application)
        })
    }

    function beginRename(folderId) {
        showAction(function() {
            actionState.beginRename(folderId)
        })
    }

    function beginDissolve(folderId) {
        showAction(function() {
            actionState.beginDissolve(folderId)
        })
    }

    function beginRemove(application, folderId) {
        showAction(function() {
            actionState.beginRemove(application, folderId)
        })
    }

    function refreshData() {
        actionState.refreshData()
    }

    function reset() {
        actionState.reset()
    }

    function focusInitial() {
        actionContent.focusInitial()
    }

    function operationTitle() {
        return actionState.operationTitle()
    }

    function completeCommitted(subjectId) {
        actionState.completeCommitted(subjectId)
    }

    function completeFailed(errorCode) {
        actionState.completeFailed(errorCode)
    }

    function waitsForTransaction(transactionId) {
        return actionState.waitingForCommit
            && String(actionState.submittedResult.transactionId || "")
                === String(transactionId || "")
    }

    PunchiMenuFolderActionState {
        id: actionState
        layoutModel: root.layoutModel
        layoutController: root.layoutController

        onFailureReported: Qt.callLater(actionContent.focusPrimaryAction)
        onOperationFinished: function(result, focusNodeId) {
            root.operationFinished(result, focusNodeId)
        }
    }

    PunchiMenuFolderActionContent {
        id: actionContent
        anchors.fill: parent
        mode: actionState.mode
        title: actionState.operationTitle()
        description: actionState.operationDescription()
        primaryActionText: actionState.primaryActionText()
        errorMessage: actionState.errorMessage
        sourceStorageId: actionState.sourceStorageId
        applicationCandidates: actionState.applicationCandidates
        selectedStorageIds: actionState.selectedStorageIds
        availableFolders: actionState.availableFolders
        selectedFolderId: actionState.selectedFolderId
        createLabel: actionState.createLabel
        renameLabel: actionState.renameLabel
        busy: actionState.busy
        waitingForCommit: actionState.waitingForCommit
        submitEnabled: actionState.canSubmit()
        maximumFolderMembers: actionState.maximumFolderMembers

        onCancelRequested: root.cancelRequested()
        onSubmitRequested: actionState.submit()
        onCreateLabelEdited: function(value) {
            actionState.createLabel = value
            actionState.errorMessage = ""
        }
        onRenameLabelEdited: function(value) {
            actionState.renameLabel = value
            actionState.errorMessage = ""
        }
        onStorageSelectionRequested: function(storageId, selected) {
            actionState.setStorageIdSelected(storageId, selected)
        }
        onFolderSelectionRequested: function(folderId) {
            actionState.selectedFolderId = folderId
            actionState.errorMessage = ""
        }
    }
}
