import QtQuick
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "DockItemClickFeedback"
    when: windowShown

    Component {
        id: windowComponent
        Window {
            id: host
            width: 420
            height: 320
            visible: true
            property alias dockItem: item
            property int actionCount: 0
            property int launchCount: 0
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
                    id: item
                    anchors.centerIn: parent
                    layoutController: layoutStub
                    iconName: ""
                    itemName: "Test item"
                    iconSize: 48
                    itemIndex: 0
                    hoverAnimationMode: "none"
                    suppressTooltip: true
                    clickEffect: "bounce"
                    inPanel: true
                    panelLocation: PlasmaCore.Types.BottomEdge
                    mediaMainAxisLength: 200
                    mediaLaunchAvailable: true
                    onItemClicked: host.actionCount++
                    onMediaPlaybackLaunchRequested: host.launchCount++
                    onMediaLaunchRequested: host.launchCount++
                }
            }
        }
    }

    Component {
        id: feedbackComponent
        Components.DockItemClickFeedback { effect: "bounce" }
    }

    function init() { failOnWarning(/.?/) }

    function createHost(type) {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        host.dockItem.itemType = type || "app"
        tryCompare(host, "visible", true)
        host.requestActivate()
        tryCompare(host, "active", true)
        return host
    }

    function feedbackFor(item) {
        const feedback = findChild(item, "dockItemClickFeedback")
        verify(feedback !== null)
        return feedback
    }

    function verifySettled(feedback) {
        tryCompare(feedback, "running", false, feedback.duration * 6 + 500)
        fuzzyCompare(feedback.horizontalOffset, 0, 0.001)
        fuzzyCompare(feedback.verticalOffset, 0, 0.001)
        fuzzyCompare(feedback.visualScale, 1, 0.001)
    }

    function test_mouseActivation_data() {
        return ["app", "folder", "trash", "calendar", "note", "punchimenu",
            "control-center", "command", "overflow"].map(function(type) {
                return {tag: type, type: type}
            })
    }

    function test_mouseActivation(data) {
        const host = createHost(data.type)
        const item = host.dockItem
        const feedback = feedbackFor(item)
        const visual = findChild(item, "dockItemVisualArea")
        const width = item.width
        const height = item.height
        const origin = visual.mapToItem(item, 0, 0)
        mousePress(item, item.width / 2, item.height / 2, Qt.LeftButton)
        compare(feedback.pressed, true)
        fuzzyCompare(visual.opacity, 0.72, 0.001)
        compare(host.actionCount, 0)
        mouseRelease(item, item.width / 2, item.height / 2, Qt.LeftButton)
        compare(host.actionCount, 1)
        compare(feedback.running, true)
        tryVerify(function() { return visual.mapToItem(item, 0, 0).y < origin.y - 1 })
        fuzzyCompare(visual.scale, 1, 0.001)
        compare(item.width, width)
        compare(item.height, height)
        feedback.reset()
        verifySettled(feedback)
    }

    function test_keyboardActivation_data() {
        return [{tag: "return", key: Qt.Key_Return}, {tag: "space", key: Qt.Key_Space}]
    }

    function test_keyboardActivation(data) {
        const host = createHost("folder")
        const feedback = feedbackFor(host.dockItem)
        host.dockItem.focusItem()
        tryVerify(function() { return host.activeFocusItem !== null })
        keyPress(data.key)
        compare(host.actionCount, 1)
        compare(feedback.pressed, true)
        compare(feedback.running, true)
        keyRelease(data.key)
        compare(feedback.pressed, false)
        feedback.reset()
    }

    function test_mediaActivation() {
        const host = createHost("media")
        const feedback = feedbackFor(host.dockItem)
        const button = findChild(host.dockItem, "mediaPlayPauseButton")
        verify(button !== null)
        verify(button.enabled)
        mouseClick(button, button.width / 2, button.height / 2)
        compare(host.launchCount, 1)
        compare(host.actionCount, 0)
        compare(feedback.running, true)
        feedback.reset()
        button.forceActiveFocus()
        tryCompare(button, "activeFocus", true)
        keyClick(Qt.Key_Space)
        compare(host.launchCount, 2)
        compare(feedback.running, true)
        feedback.reset()
    }

    function test_direction_data() {
        return [
            {tag: "bottom", edge: PlasmaCore.Types.BottomEdge, vertical: false, sign: -1},
            {tag: "top", edge: PlasmaCore.Types.TopEdge, vertical: false, sign: 1},
            {tag: "left", edge: PlasmaCore.Types.LeftEdge, vertical: true, sign: 1},
            {tag: "right", edge: PlasmaCore.Types.RightEdge, vertical: true, sign: -1}
        ]
    }

    function test_direction(data) {
        const host = createHost("app")
        const item = host.dockItem
        item.panelLocation = data.edge
        const feedback = feedbackFor(item)
        const visual = findChild(item, "dockItemVisualArea")
        const origin = visual.mapToItem(item, 0, 0)
        item.activateItem()
        tryVerify(function() {
            const mapped = visual.mapToItem(item, 0, 0)
            return (data.vertical ? mapped.x - origin.x : mapped.y - origin.y) * data.sign > 1
        })
        compare(data.vertical ? feedback.verticalOffset : feedback.horizontalOffset, 0)
        feedback.reset()
    }

    function test_repeatedClicksDoNotQueueFeedback() {
        const host = createHost("app")
        const feedback = feedbackFor(host.dockItem)
        host.dockItem.activateItem()
        tryVerify(function() { return Math.abs(feedback.verticalOffset) > 1 })
        const offset = feedback.verticalOffset
        for (let n = 0; n < 12; n++) host.dockItem.activateItem()
        compare(host.actionCount, 13)
        compare(feedback.verticalOffset, offset)
        verifySettled(feedback)
    }

    function test_effectChangeAndHiddenItemReset() {
        const host = createHost("app")
        const feedback = feedbackFor(host.dockItem)
        host.dockItem.activateItem()
        tryVerify(function() { return Math.abs(feedback.verticalOffset) > 1 })
        host.dockItem.clickEffect = "none"
        verifySettled(feedback)
        host.dockItem.activateItem()
        compare(feedback.running, false)
        host.dockItem.clickEffect = "bounce"
        host.dockItem.activateItem()
        host.dockItem.visible = false
        verifySettled(feedback)
        host.dockItem.visible = true
        host.dockItem.activateItem()
        compare(feedback.running, true)
        feedback.motionEnabled = false
        verifySettled(feedback)
    }

    function test_scaleEffects_data() {
        return [{tag: "pulse", effect: "pulse"}, {tag: "press", effect: "press"}]
    }

    function test_scaleEffects(data) {
        const feedback = createTemporaryObject(feedbackComponent, testCase, {effect: data.effect})
        feedback.play()
        tryVerify(function() { return feedback.visualScale < 0.99 })
        compare(feedback.horizontalOffset, 0)
        compare(feedback.verticalOffset, 0)
        verifySettled(feedback)
    }

    function test_speedAndReducedMotion() {
        const feedback = createTemporaryObject(feedbackComponent, testCase)
        const defaultDuration = feedback.duration
        feedback.motionSpeedPercent = 50
        compare(feedback.duration, defaultDuration * 2)
        feedback.motionSpeedPercent = 150
        compare(feedback.duration, Math.round(defaultDuration * 100 / 150))
        feedback.motionEnabled = false
        feedback.pressed = true
        compare(feedback.visualOpacity, 0.72)
        feedback.play()
        compare(feedback.running, false)
        verifySettled(feedback)
    }

    function test_structuralItemsDoNotActivate_data() {
        return ["separator", "spacer", "dynamic-applications"].map(function(type) {
            return {tag: type, type: type}
        })
    }

    function test_structuralItemsDoNotActivate(data) {
        const host = createHost(data.type)
        host.dockItem.activateItem()
        compare(host.actionCount, 0)
        compare(feedbackFor(host.dockItem).running, false)
    }

    function test_themeInstantProfile() {
        const host = createHost("app")
        const feedback = feedbackFor(host.dockItem)
        compare(feedback.motionEnabled, Kirigami.Units.longDuration > 1)
        host.dockItem.activateItem()
        compare(host.actionCount, 1)
        compare(feedback.running, feedback.motionEnabled)
        if (!feedback.motionEnabled) {
            verifySettled(feedback)
        } else {
            feedback.reset()
        }
    }
}
