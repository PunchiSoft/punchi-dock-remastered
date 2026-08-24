import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/config" as Config

TestCase {
    id: testCase

    name: "ItemActionEditorDrop"
    when: windowShown

    SignalSpy {
        id: launcherDroppedSpy
        signalName: "applicationLauncherDropped"
    }

    SignalSpy {
        id: addRequestedSpy
        signalName: "addActionRequested"
    }

    Component {
        id: windowComponent

        Window {
            width: 720
            height: 520
            visible: true

            property alias editor: itemActionEditor

            ListModel {
                id: applicationModel
            }

            Config.ItemActionEditor {
                id: itemActionEditor
                anchors.fill: parent
                actionModel: applicationModel
                selectedItemIndex: 0
                selectedItemType: "folder"
                itemModeValue: "container"
                applicationLauncherDropEnabled: true
                dropApplicationsHereText: "Drop applications here"
                addApplicationText: "Add application"
                addActionText: "Add action"
            }
        }
    }

    function init() {
        // The isolated runner has no KDE icon provider for the hidden action editor icon.
        ignoreWarning(/QML IconImage: Cannot open: .*application-x-executable/)
        failOnWarning(/.?/)
        launcherDroppedSpy.clear()
        addRequestedSpy.clear()
    }

    function acceptedLauncher(urls) {
        return {
            "accepted": urls.length === 1,
            "storageId": "org.example.Writer.desktop",
            "appId": "org.example.Writer",
            "name": "Writer"
        }
    }

    function test_validatedDropEmitsIntentAndResetsState() {
        const window = createTemporaryObject(windowComponent, testCase)
        verify(window !== null)
        tryCompare(window, "visible", true)
        const editor = window.editor
        launcherDroppedSpy.target = editor
        editor.applicationLauncherDropValidator = acceptedLauncher

        const urls = ["file:///tmp/org.example.Writer.desktop"]
        verify(editor.beginApplicationLauncherDrop(urls))
        compare(editor.applicationLauncherDropState, "acceptable")
        verify(editor.finishApplicationLauncherDrop(urls))
        compare(editor.applicationLauncherDropState, "none")
        compare(launcherDroppedSpy.count, 1)
        compare(launcherDroppedSpy.signalArguments[0][0][0], urls[0])
    }

    function test_rejectedAndDisabledDropsDoNotEmitIntent() {
        const window = createTemporaryObject(windowComponent, testCase)
        verify(window !== null)
        tryCompare(window, "visible", true)
        const editor = window.editor
        launcherDroppedSpy.target = editor
        editor.applicationLauncherDropValidator = function(urls) {
            return { "accepted": false }
        }

        const urls = ["file:///tmp/not-an-application.txt"]
        verify(!editor.beginApplicationLauncherDrop(urls))
        compare(editor.applicationLauncherDropState, "rejected")
        verify(!editor.finishApplicationLauncherDrop(urls))
        compare(launcherDroppedSpy.count, 0)

        editor.applicationLauncherDropEnabled = false
        compare(editor.applicationLauncherDropState, "none")
        verify(!editor.beginApplicationLauncherDrop(urls))
        compare(launcherDroppedSpy.count, 0)
    }

    function test_addButtonRemainsKeyboardAccessible() {
        const window = createTemporaryObject(windowComponent, testCase)
        verify(window !== null)
        tryCompare(window, "visible", true)
        const editor = window.editor
        const addButton = findChild(editor, "addActionButton")
        verify(addButton !== null)
        compare(addButton.Accessible.name, "Add application")

        addRequestedSpy.target = editor
        wait(0)
        addButton.forceActiveFocus(Qt.TabFocusReason)
        tryCompare(addButton, "activeFocus", true)
        keyClick(Qt.Key_Space)
        compare(addRequestedSpy.count, 1)
    }
}
