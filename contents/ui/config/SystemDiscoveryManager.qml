import QtQuick
import org.kde.kirigami as Kirigami
import "../org/punchi/dock" as Punchi

Item {
    id: root

    signal appsDiscovered(var apps)
    signal applicationDiscovered(var application)
    signal operationFailed(string operation, string message)

    function requestFolderEntries(folderPath) {
        systemDiscovery.requestFolderEntries(folderPath)
    }

    function requestApplications(category) {
        systemDiscovery.requestApplications(category)
    }

    function requestApplication(alias) {
        systemDiscovery.requestApplication(alias)
    }

    Punchi.SystemDiscovery {
        id: systemDiscovery

        onFolderEntriesReady: function(entries) {
            root.appsDiscovered(entries)
        }
        onApplicationsReady: function(applications) {
            root.appsDiscovered(applications)
        }
        onApplicationReady: function(application) {
            root.applicationDiscovered(application)
        }
        onOperationFailed: function(operation, message) {
            root.operationFailed(operation, message)
        }
    }
}
