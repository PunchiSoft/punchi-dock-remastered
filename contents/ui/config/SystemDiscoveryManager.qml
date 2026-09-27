import QtQuick
import "../org/punchi/dock" as Punchi

Item {
    id: root

    signal appsDiscovered(var apps, int requestId)
    signal folderEntriesDiscovered(var entries, int requestId)
    signal applicationDiscovered(var application, int requestId)
    signal operationFailed(string operation, string message, int requestId)

    property int applicationsRequestId: 0
    property int applicationRequestId: 0
    property bool folderRequestActive: false
    property string activeFolderPath: ""
    property int activeFolderRequestId: 0
    property string queuedFolderPath: ""
    property int queuedFolderRequestId: 0

    function startFolderRequest(folderPath, requestId) {
        root.folderRequestActive = true
        root.activeFolderPath = String(folderPath || "")
        root.activeFolderRequestId = Number(requestId || 0)
        systemDiscovery.requestFolderEntries(root.activeFolderPath)
    }

    function requestFolderEntries(folderPath, requestId) {
        if (root.folderRequestActive) {
            root.queuedFolderPath = String(folderPath || "")
            root.queuedFolderRequestId = Number(requestId || 0)
            return
        }
        root.startFolderRequest(folderPath, requestId)
    }

    function finishFolderRequest() {
        root.folderRequestActive = false
        root.activeFolderPath = ""
        root.activeFolderRequestId = 0
        if (root.queuedFolderPath.length === 0) {
            return
        }
        const path = root.queuedFolderPath
        const requestId = root.queuedFolderRequestId
        root.queuedFolderPath = ""
        root.queuedFolderRequestId = 0
        Qt.callLater(function() {
            root.startFolderRequest(path, requestId)
        })
    }

    function requestApplications(category, requestId) {
        root.applicationsRequestId = Number(requestId || 0)
        systemDiscovery.requestApplications(category)
    }

    function requestApplication(alias, requestId) {
        root.applicationRequestId = Number(requestId || 0)
        systemDiscovery.requestApplication(alias)
    }

    function validateApplicationLauncherDrop(urls) {
        return systemDiscovery.validateApplicationLauncherDrop(urls || [])
    }

    function iconForCategory(category) {
        return systemDiscovery.iconForCategory(category)
    }

    Punchi.SystemDiscovery {
        id: systemDiscovery

        onFolderEntriesReady: function(entries) {
            const requestId = root.activeFolderRequestId
            root.folderEntriesDiscovered(entries, requestId)
            root.finishFolderRequest()
        }
        onApplicationsReady: function(applications) {
            const requestId = root.applicationsRequestId
            root.applicationsRequestId = 0
            root.appsDiscovered(applications, requestId)
        }
        onApplicationReady: function(application) {
            const requestId = root.applicationRequestId
            root.applicationRequestId = 0
            root.applicationDiscovered(application, requestId)
        }
        onOperationFailed: function(operation, message) {
            const requestId = operation === "folder"
                ? root.activeFolderRequestId : 0
            root.operationFailed(operation, message, requestId)
            if (operation === "folder") {
                root.finishFolderRequest()
            }
        }
    }
}
