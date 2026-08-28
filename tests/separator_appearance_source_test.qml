import QtQuick
import QtQuick.Window
import QtTest
import "../contents/code/separatorAppearance.js" as SeparatorAppearance
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "SeparatorAppearanceSource"
    when: windowShown
    property var hostWindowUnderTest: null

    Component {
        id: windowComponent

        Window {
            width: 240
            height: 160
            visible: true

            property alias separatorItem: separatorItem

            Item {
                id: layoutStub

                anchors.fill: parent
                property real columnSpacing: 0
                property real rowSpacing: 0
                property bool mediaMorphActive: false
                property bool launcherDropTransitionActive: false
                property int hoveredIndex: -1
                property real mouseOffset: 0
                property real pointerPrimaryAxis: -1
                property real lastPointerPrimaryAxis: -1
                property bool wavePointerInsideLayout: false
                property var popupCoordinator: null

                signal trashUrlsDropped(var urls)

                Components.DockItem {
                    id: separatorItem

                    anchors.centerIn: parent
                    layoutController: layoutStub
                    itemType: "separator"
                    iconSize: 48
                    customSeparatorEnabled: true
                    separatorTheme: ({
                        "style": "star",
                        "thickness": 12,
                        "lengthRatio": 0.45,
                        "opacity": 0.80,
                        "glow": { "size": 5 }
                    })
                    separatorStyleSetting: "diamond"
                    separatorThicknessSetting: 4
                    separatorLengthRatioSetting: 0.90
                    separatorOpacitySetting: 0.25
                    separatorGlowSetting: false
                }
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
    }

    function cleanup() {
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
    }

    function test_legacySourceInferencePreservesExistingChoices() {
        compare(SeparatorAppearance.sourceForItem({
            "type": "separator",
            "separatorStyle": "diamond"
        }), "item")
        compare(SeparatorAppearance.sourceForItem({
            "type": "separator"
        }), "theme")
    }

    function test_runtimeSwitchUsesOneAppearanceSource() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        const separatorItem = hostWindow.separatorItem

        separatorItem.separatorAppearanceSourceSetting = "theme"
        tryCompare(separatorItem.effectiveSeparatorAppearance, "style", "star")
        compare(separatorItem.effectiveSeparatorAppearance.thickness, 12)
        compare(separatorItem.effectiveSeparatorAppearance.lengthRatio, 0.45)
        compare(separatorItem.effectiveSeparatorAppearance.opacity, 0.80)
        verify(separatorItem.effectiveSeparatorAppearance.glowEnabled)
        compare(separatorItem.implicitWidth, 16)

        separatorItem.separatorAppearanceSourceSetting = "item"
        tryCompare(separatorItem.effectiveSeparatorAppearance,
            "style", "diamond")
        compare(separatorItem.effectiveSeparatorAppearance.thickness, 4)
        compare(separatorItem.effectiveSeparatorAppearance.lengthRatio, 0.90)
        compare(separatorItem.effectiveSeparatorAppearance.opacity, 0.25)
        verify(!separatorItem.effectiveSeparatorAppearance.glowEnabled)
        compare(separatorItem.implicitWidth, 10)
    }
}

