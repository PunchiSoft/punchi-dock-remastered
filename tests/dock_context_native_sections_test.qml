// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "DockContextNativeSections"

    property var appItem: ({
        "type": "app",
        "name": "Example",
        "storageId": "org.example.App.desktop"
    })

    QtObject {
        id: tasks
        property var taskActions: []
        function contextActionsForRows() { return taskActions }
        function pinDescriptorForEntry() {
            return { "launcherUrl": "applications:org.example.App.desktop" }
        }
        function dockContainsPinDescriptor() { return false }
        function dockItemApplicationId() { return "" }
        function dockItemLauncherUrl() { return "" }
    }

    QtObject {
        id: items
        property var dockItems: []
        property string lastSortMode: ""
        property string lastSortExpected: ""
        property string lastPath: ""
        function canonicalJsonText(item) { return JSON.stringify(item) }
        function setFolderSortMode(index, mode, expected) {
            lastSortMode = mode
            lastSortExpected = expected
            return index === 0
        }
        function openLocation(path) { lastPath = path }
    }

    QtObject {
        id: discovery
        property bool placesAvailable: false
        property bool recentAvailable: false
        property bool newWindowAvailable: false
        property var extraPlaces: []
        property int recentCalls: 0
        property int placeCalls: 0
        property int newWindowCalls: 0
        property string openedRecent: ""
        property string openedPlace: ""
        property string launchedNewWindow: ""

        function filePlaceActions(applicationId) {
            placeCalls++
            if (!placesAvailable) {
                return []
            }
            const rows = [
                {"name": "Home", "icon": "folder-home", "groupName": "",
                    "resource": "file:///home/user", "available": true}
            ]
            for (let index = 0; index < extraPlaces.length; index++) {
                rows.push(extraPlaces[index])
            }
            rows.push({"name": "USB", "icon": "drive-removable-media",
                "groupName": "Devices", "resource": "file:///media/usb",
                "available": true})
            return rows
        }
        function recentDocumentActions(applicationId) {
            recentCalls++
            if (!recentAvailable) {
                return []
            }
            return [{"name": "doc.txt", "icon": "text-x-generic",
                "resource": "/tmp/doc.txt", "mimeType": "text/plain"}]
        }
        function openRecentDocument(applicationId, resource, mimeType) {
            openedRecent = resource
            return true
        }
        function forgetRecentDocuments(applicationId) { return true }
        function openFilePlace(applicationId, resource) {
            openedPlace = resource
            return true
        }
        function applicationActions(applicationId) { return [] }
        function canLaunchNewWindow(applicationId) {
            return newWindowAvailable
        }
        function launchApplicationNewInstance(applicationId) {
            launchedNewWindow = applicationId
            newWindowCalls++
            return true
        }
    }

    QtObject {
        id: mpris
        property bool available: true
        property string applicationId: "org.example.App.desktop"
        property bool canGoPrevious: true
        property bool canPlay: true
        property bool canPause: true
        property bool canGoNext: true
        property bool canStop: true
        property bool playing: false
        property int previousCalls: 0
        property int toggleCalls: 0
        property int nextCalls: 0
        property int stopCalls: 0
        function previous() { previousCalls++ }
        function togglePlaying() { toggleCalls++ }
        function next() { nextCalls++ }
        function stop() { stopCalls++ }
    }

    Components.DockContextActionsController {
        id: controller
        taskController: tasks
        systemDiscovery: discovery
        mprisController: mpris
        dockItemsController: items
        showConfigureDockAction: true
        configureDockHandler: function() { return true }
    }

    SignalSpy {
        id: showAllPlacesSpy
        target: controller
        signalName: "showAllPlacesRequested"
    }

    function init() {
        discovery.placesAvailable = false
        discovery.recentAvailable = false
        discovery.newWindowAvailable = false
        discovery.extraPlaces = []
        tasks.taskActions = []
        discovery.recentCalls = 0
        discovery.placeCalls = 0
        discovery.newWindowCalls = 0
        discovery.openedRecent = ""
        discovery.openedPlace = ""
        discovery.launchedNewWindow = ""
        mpris.available = true
        mpris.applicationId = "org.example.App.desktop"
        mpris.playing = false
        mpris.previousCalls = 0
        mpris.toggleCalls = 0
        mpris.nextCalls = 0
        mpris.stopCalls = 0
        items.dockItems = []
        items.lastSortMode = ""
        items.lastSortExpected = ""
        items.lastPath = ""
    }

    function actionByName(actions, name) {
        for (let index = 0; index < actions.length; index++) {
            if (actions[index].name === name) {
                return actions[index]
            }
        }
        return null
    }

    function test_recentFilesRenderAsNativeSection() {
        discovery.recentAvailable = true
        const actions = controller.actionsForItem(appItem, [], "pinned", 0)
        const recent = actionByName(actions, "Recent Files")
        verify(recent !== null)
        compare(recent.kind, "section")
        const document = actionByName(actions, "doc.txt")
        verify(document !== null)
        compare(document.kind, "openRecentDocument")
        const forget = actionByName(actions, "Forget Recent Files")
        verify(forget !== null)
        compare(forget.kind, "forgetRecentDocuments")

        verify(controller.triggerAction(document))
        compare(discovery.openedRecent, "/tmp/doc.txt")
        verify(controller.triggerAction(forget))
    }

    function test_placesAndRecentFilesRenderAsSections() {
        discovery.placesAvailable = true
        discovery.recentAvailable = true
        const actions = controller.actionsForItem(appItem, [], "pinned", 0)
        const places = actionByName(actions, "Places")
        verify(places !== null)
        compare(places.kind, "section")
        verify(actionByName(actions, "Recent Files") !== null)
        const actionsHeader = actionByName(actions, "Actions")
        verify(actionsHeader !== null)
        compare(actionsHeader.kind, "section")
        compare(actions.findIndex(action => action.name === "Places")
            < actions.findIndex(action => action.name === "Actions"), true)
        compare(actionByName(actions, "Home").kind, "openFilePlace")
        const devices = actionByName(actions, "Devices")
        verify(devices !== null)
        compare(devices.kind, "submenu")
        compare(devices.children.length, 1)
        verify(controller.triggerAction(devices.children[0]))
        compare(discovery.openedPlace, "file:///media/usb")
    }

    function test_morePlacesRequestsFullMenu() {
        discovery.placesAvailable = true
        const extraPlaces = []
        for (let index = 0; index < 6; index++) {
            extraPlaces.push({
                "name": "Extra " + index,
                "icon": "folder",
                "groupName": "",
                "resource": "file:///tmp/extra-" + index,
                "available": true
            })
        }
        discovery.extraPlaces = extraPlaces
        const actions = controller.actionsForItem(appItem, [], "pinned", 0)
        const more = actionByName(actions, "3 more Places…")
        verify(more !== null)
        compare(more.kind, "showAllPlaces")
        compare(actionByName(actions, "Extra 4"), null)

        verify(controller.triggerAction(more))
        compare(showAllPlacesSpy.count, 1)

        const expanded = controller.actionsForItem(appItem, [], "pinned", 0,
            {"showAllPlaces": true})
        verify(actionByName(expanded, "Extra 0") !== null)
        verify(actionByName(expanded, "Extra 5") !== null)
        compare(actionByName(expanded, "3 more Places…"), null)
    }

    function test_closeStaysLastAndDockFamilyGroupsTogether() {
        tasks.taskActions = [{
            "kind": "taskAction",
            "operation": "close",
            "name": "Close",
            "icon": "window-close",
            "taskRow": 4,
            "enabled": true
        }]
        const actions = controller.actionsForItem(appItem, [4], "dynamic", 0)

        compare(actionByName(actions, "Actions"), null)
        compare(actions[actions.length - 1].name, "Close")
        compare(actions[actions.length - 2].kind, "separator")

        const pinIndex = actions.findIndex(action => action.name === "Pin to Dock")
        const configureIndex = actions.findIndex(
            action => action.name === "Configure Punchi Dock…")
        verify(pinIndex > 0)
        verify(configureIndex > pinIndex)
        compare(actions[pinIndex - 1].kind, "separator")
        verify(actions.findIndex(action => action.name === "Close") > configureIndex)
    }

    function test_newWindowIsOfferedOnlyWithoutRunningRows() {
        discovery.newWindowAvailable = true
        let actions = controller.actionsForItem(appItem, [], "pinned", 0)
        const newWindow = actionByName(actions, "New window")
        verify(newWindow !== null)
        compare(newWindow.kind, "launchNewWindow")
        verify(controller.triggerAction(newWindow))
        compare(discovery.newWindowCalls, 1)

        actions = controller.actionsForItem(appItem, [4], "pinned", 0)
        compare(actionByName(actions, "New window"), null)
    }

    function test_mediaSubmenuDispatchesGuardedCommands() {
        const actions = controller.actionsForItem(appItem, [], "pinned", 0)
        const media = actionByName(actions, "Media")
        verify(media !== null)
        compare(media.children.length, 4)
        verify(controller.triggerAction(media.children[1]))
        compare(mpris.toggleCalls, 1)

        const mismatched = Object.assign({}, media.children[0],
            {"applicationId": "other.desktop"})
        verify(!controller.triggerAction(mismatched))
        mpris.available = false
        verify(!controller.triggerAction(media.children[0]))
    }

    function test_folderSortAndOpenLocationUsePersistentContract() {
        const folder = {
            "type": "folder",
            "name": "Docs",
            "sourcePath": "/tmp/docs",
            "layout": "grid",
            "sortMode": "modified",
            "apps": []
        }
        items.dockItems = [folder]
        const actions = controller.actionsForItem(folder, [], "pinned", 0)
        const sort = actionByName(actions, "Sort by")
        verify(sort !== null)
        compare(sort.children.length, 5)
        compare(sort.children[2].checked, true)
        verify(controller.triggerAction(sort.children[0]))
        compare(items.lastSortMode, "name")
        compare(items.lastSortExpected, JSON.stringify(folder))

        const open = actionByName(actions, "Open in File Manager")
        verify(open !== null)
        verify(controller.triggerAction(open))
        compare(items.lastPath, "/tmp/docs")
    }
}
