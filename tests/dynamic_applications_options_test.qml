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
        verify(checkbox !== null)
        verify(options !== null)
        verify(checkbox.visible)
        verify(checkbox.checked)
        verify(options.visible)
        verify(options.enabled)

        formChangedSpy.target = panel
        panel.setSeparatorStyleValue("diamond")
        panel.setSeparatorThicknessValue(4)
        panel.setSeparatorVisibleChecked(false)
        compare(formChangedSpy.count, 0)
        compare(panel.separatorVisibleChecked, false)
        panel.setSeparatorVisibleChecked(true)
        compare(formChangedSpy.count, 0)

        checkbox.forceActiveFocus(Qt.TabFocusReason)
        verify(checkbox.activeFocus)
        keyClick(Qt.Key_Space)

        tryCompare(checkbox, "checked", false)
        compare(panel.separatorVisibleChecked, false)
        compare(options.enabled, false)
        verify(formChangedSpy.count > 0)
    }
}
