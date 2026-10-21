import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/config" as Config

TestCase {
    id: testCase

    name: "DynamicApplicationsOptions"
    when: windowShown
    property var hostWindowUnderTest: null

    SignalSpy {
        id: formChangedSpy
        signalName: "formChanged"
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 800
            height: 700
            visible: true

            property alias panel: editorPanel

            Config.ItemEditorPanel {
                id: editorPanel
                anchors.fill: parent
                selectedItemType: "dynamic-applications"
            }
        }
    }

    Component {
        id: separatorWindowComponent

        Window {
            id: separatorHostWindow
            width: 800
            height: 700
            visible: true

            property alias panel: separatorEditorPanel

            Config.ItemEditorPanel {
                id: separatorEditorPanel
                anchors.fill: parent
                selectedItemType: "separator"
                showTypeSelector: false
                itemModeIndex: 3
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        formChangedSpy.clear()
    }

    function cleanup() {
        formChangedSpy.target = null
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
    }

    function test_keyboardTogglesSeparatorWithoutLosingAnchorMode() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        const panel = hostWindow.panel
        wait(0)
        compare(panel.itemModeValue, "dynamic-applications")
        verify(panel.dynamicApplicationsItem)

        const checkbox = findChild(
            panel, "dynamicApplicationsSeparatorVisibleCheckBox")
        const options = findChild(panel, "dynamicApplicationsSeparatorOptions")
        verify(checkbox === null)
        verify(options !== null)
        verify(!options.visible)
        verify(panel.separatorVisibleChecked === undefined)
        compare(panel.separatorAppearanceSourceValue, "theme")
    }

    function test_keyboardSelectsPerItemAppearance() {
        const hostWindow = createTemporaryObject(separatorWindowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        const panel = hostWindow.panel
        wait(0)
        compare(panel.itemModeValue, "separator")
        const appearanceSource = findChild(
            panel, "separatorAppearanceSourceCombo")
        verify(appearanceSource !== null)
        verify(appearanceSource.visible)
        compare(panel.separatorAppearanceSourceValue, "theme")

        formChangedSpy.target = panel
        wait(0)
        appearanceSource.forceActiveFocus(Qt.TabFocusReason)
        tryVerify(function() { return appearanceSource.activeFocus })
        keyClick(Qt.Key_Down)

        tryCompare(panel, "separatorAppearanceSourceValue", "item")
        verify(formChangedSpy.count > 0)
    }
}
