// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "RecentApplicationTooltip"
    when: windowShown

    Component {
        id: fixtureComponent
        Item {
            id: fixture
            property alias launcher: launcher
            property alias coordinator: coordinator
            property alias preview: preview
            property var popupCoordinator: coordinator
            property real columnSpacing: 0
            property real rowSpacing: 0
            property bool mediaMorphActive: false
            property bool launcherDropTransitionActive: false
            property int hoveredIndex: -1
            property real mouseOffset: 0
            property real pointerPrimaryAxis: -1
            property real lastPointerPrimaryAxis: -1
            property bool wavePointerInsideLayout: false
            QtObject { id: preview; property bool visible: false }
            Components.PopupCoordinator {
                id: coordinator
                taskWindowsDialogRef: preview
            }
            Components.DockItem {
                id: launcher
                layoutController: fixture
                iconName: ""
                itemName: "Example application"
                itemType: "app"
                recentApplicationLauncher: true
            }
        }
    }

    function init() { failOnWarning(/.?/) }

    function test_recentLabelDoesNotRequirePreviewsOrPersistentPin() {
        const fixture = createTemporaryObject(fixtureComponent, testCase)
        verify(fixture !== null)
        const item = fixture.launcher
        compare(item.pinnedApplicationLauncher, false)
        compare(item.tooltipEligibleItem, true)
        compare(item.showAnyTooltip, true)
        fixture.coordinator.windowPreviewsEnabled = false
        compare(item.showAnyTooltip, true)
        fixture.coordinator.windowPreviewsEnabled = true
        compare(item.showAnyTooltip, true)
        item.taskIndicatorCount = 1
        compare(item.showAnyTooltip, false)
        item.taskIndicatorCount = 0
        compare(item.showAnyTooltip, true)
    }

    function test_previewAndContextMenuTakePrecedenceReactively() {
        const fixture = createTemporaryObject(fixtureComponent, testCase)
        verify(fixture !== null)
        const item = fixture.launcher
        compare(item.showAnyTooltip, true)
        fixture.preview.visible = true
        compare(item.isAnyPopupOrMenuOpen, true)
        compare(item.showAnyTooltip, false)
        fixture.preview.visible = false
        compare(item.showAnyTooltip, true)
        fixture.coordinator.contextMenuOpening = true
        compare(item.showAnyTooltip, false)
        fixture.coordinator.contextMenuOpening = false
        compare(item.showAnyTooltip, true)
        item.suppressTooltip = true
        compare(item.showAnyTooltip, false)
        item.suppressTooltip = false
        compare(item.showAnyTooltip, true)
    }

    function test_existingLauncherAndStructuralRulesRemainUnchanged() {
        const fixture = createTemporaryObject(fixtureComponent, testCase)
        verify(fixture !== null)
        const item = fixture.launcher
        item.recentApplicationLauncher = false
        compare(item.showAnyTooltip, false)
        item.pinnedApplicationLauncher = true
        compare(item.showAnyTooltip, true)
        item.taskIndicatorCount = 1
        compare(item.showAnyTooltip, false)
        item.pinnedApplicationLauncher = false
        item.itemType = "folder"
        compare(item.showAnyTooltip, true)
        item.recentApplicationLauncher = true
        item.itemType = "separator"
        compare(item.showAnyTooltip, false)
    }

    function test_destroyAndRecreateAfterPreviewSuppression() {
        for (let cycle = 0; cycle < 2; ++cycle) {
            const fixture = fixtureComponent.createObject(testCase)
            verify(fixture !== null)
            compare(fixture.launcher.showAnyTooltip, true)
            fixture.preview.visible = true
            compare(fixture.launcher.showAnyTooltip, false)
            fixture.destroy()
            wait(0)
        }
    }
}
