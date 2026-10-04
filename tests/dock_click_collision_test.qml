import QtQuick
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import "../contents/ui/components" as Components
import "../contents/ui/config" as Config

TestCase {
    id: testCase
    name: "DockClickCollision"
    when: windowShown

    Component {
        id: itemComponent
        Components.DockItem {
            iconName: ""
            itemName: "Collision fixture"
            iconSize: 48
            width: 60
            height: 60
            inPanel: true
            clickEffect: "collision"
            hoverAnimationMode: "none"
            suppressTooltip: true
        }
    }
    Component {
        id: hostComponent
        Window {
            id: host
            width: 500
            height: 500
            visible: true
            property bool vertical: false
            property bool floating: false
            property int actionCount: 0
            property var items: []
            property alias collision: collision
            property alias container: container
            property var samples: []

            Item {
                id: container
                anchors.fill: parent
                property real columnSpacing: 4
                property real rowSpacing: 4
                property bool mediaMorphActive: false
                property bool launcherDropTransitionActive: false
                property int hoveredIndex: -1
                property real mouseOffset: 0
                property real pointerPrimaryAxis: -1
                property real lastPointerPrimaryAxis: -1
                property bool wavePointerInsideLayout: false
                property var popupCoordinator: null
                signal trashUrlsDropped(var urls)
            }
            Components.DockClickCollision {
                id: collision
                layoutItem: container
                verticalPanel: host.vertical
                motionSpeedPercent: 50
            }
            Connections {
                target: collision
                function onOriginOffsetChanged() {
                    host.samples.push({origin: collision.originOffset,
                        positive: collision.positiveOffset, negative: collision.negativeOffset})
                }
            }
            function addItem(index) {
                const item = itemComponent.createObject(container, {
                    x: host.vertical ? 80 : 20 + index * 64,
                    y: host.vertical ? 20 + index * 64 : 80,
                    layoutController: container,
                    clickCollisionController: collision,
                    itemIndex: index,
                    inPanel: !host.floating,
                    panelLocation: host.vertical ? PlasmaCore.Types.LeftEdge : PlasmaCore.Types.BottomEdge
                })
                item.itemClicked.connect(function() { host.actionCount++ })
                return item
            }
        }
    }
    Component {
        id: configComponent
        Config.ConfigMouse { width: 700; height: 600 }
    }

    function init() { failOnWarning(/.?/) }

    function createHost(vertical, floating, count) {
        const host = createTemporaryObject(hostComponent, testCase,
            {vertical: !!vertical, floating: !!floating})
        verify(host !== null)
        for (let n = 0; n < (count === undefined ? 5 : count); n++) {
            const item = host.addItem(n)
            verify(item !== null)
            host.items.push(item)
        }
        host.requestActivate()
        tryCompare(host, "active", true)
        return host
    }

    function settled(host) {
        tryCompare(host.collision, "running", false, host.collision.beat * 5 + 500)
        compare(host.collision.originOffset, 0)
        compare(host.collision.positiveOffset, 0)
        compare(host.collision.negativeOffset, 0)
        compare(host.collision.originItem, null)
        for (const item of host.items) {
            if (item) compare(item.clickCollisionOffset, 0)
        }
    }

    function test_impactsAndStableGeometry_data() {
        return [{tag: "horizontal-panel", vertical: false, floating: false},
            {tag: "vertical-panel", vertical: true, floating: false},
            {tag: "horizontal-floating", vertical: false, floating: true},
            {tag: "vertical-floating", vertical: true, floating: true}]
    }

    function test_impactsAndStableGeometry(data) {
        const host = createHost(data.vertical, data.floating)
        const item = host.items[2]
        const originalGeometry = host.items.map(function(i) { return [i.x, i.y, i.width, i.height] })
        mouseClick(item, 30, 30)
        compare(host.actionCount, 1)
        compare(host.collision.originItem, item)
        compare(host.collision.positiveItem, host.items[3])
        compare(host.collision.negativeItem, host.items[1])
        tryVerify(function() { return item.clickCollisionOffset > 1 })
        tryVerify(function() { return host.items[3].clickCollisionOffset > 1 })
        compare(host.items[0].clickCollisionOffset, 0)
        compare(host.items[4].clickCollisionOffset, 0)
        verify(host.items[3].clickCollisionOffset < host.collision.positiveReach)
        tryVerify(function() { return item.clickCollisionOffset < -1 })
        tryVerify(function() { return host.items[1].clickCollisionOffset < -1 })
        settled(host)
        let positivePeak = 0
        let negativePeak = 0
        let leftImpulse = 0
        let rightImpulse = 0
        let crossedToNegative = false
        for (const s of host.samples) {
            positivePeak = Math.max(positivePeak, s.origin)
            negativePeak = Math.min(negativePeak, s.origin)
            if (s.origin < -0.01) crossedToNegative = true
            if (crossedToNegative) verify(s.origin <= 0.01, "One impact per side must not oscillate again")
            verify(s.positive >= 0)
            verify(s.negative <= 0)
            rightImpulse = Math.max(rightImpulse, s.positive)
            leftImpulse = Math.min(leftImpulse, s.negative)
        }
        verify(positivePeak > item.iconSize * 0.15)
        verify(negativePeak < -item.iconSize * 0.15)
        verify(rightImpulse > 1 && rightImpulse < positivePeak)
        verify(leftImpulse < -1 && leftImpulse > negativePeak)
        for (let n = 0; n < host.items.length; n++) {
            const i = host.items[n]
            compare([i.x, i.y, i.width, i.height], originalGeometry[n])
        }
    }

    function test_edgesAndBoundaries() {
        const host = createHost()
        host.items[0].activateItem()
        compare(host.collision.negativeItem, null)
        compare(host.collision.positiveItem, host.items[1])
        settled(host)
        host.items[4].activateItem()
        compare(host.collision.positiveItem, null)
        compare(host.collision.negativeItem, host.items[3])
        settled(host)
        host.items[1].itemType = "separator"
        host.items[2].activateItem()
        compare(host.collision.negativeItem, null)
        settled(host)
        host.items[3].itemType = "spacer"
        host.items[2].activateItem()
        compare(host.collision.positiveItem, null)
        settled(host)
        host.items[1].itemType = "app"
        host.items[1].y = 180
        host.items[2].activateItem()
        compare(host.collision.negativeItem, host.items[0])
        settled(host)
    }

    function test_itemTypes_data() {
        return ["app", "folder", "trash", "calendar", "note", "punchimenu",
            "control-center", "command", "overflow"].map(function(type) {
                return {tag: type, type: type}
            })
    }

    function test_itemTypes(data) {
        const host = createHost()
        host.items[2].itemType = data.type
        mouseClick(host.items[2], 30, 30)
        compare(host.actionCount, 1)
        compare(host.collision.originItem, host.items[2])
        compare(host.collision.running, true)
        host.collision.reset()
    }

    function test_mediaActivation() {
        const host = createHost()
        const item = host.items[2]
        item.itemType = "media"
        item.width = 200
        // Match the layout's redistribution around an expanded media item.
        host.items[3].x = item.x + item.width + 4
        host.items[4].x = host.items[3].x + host.items[3].width + 4
        item.mediaLaunchAvailable = true
        item.mediaPlaybackLaunchRequested.connect(function() { host.actionCount++ })
        const button = findChild(item, "mediaPlayPauseButton")
        verify(button !== null)
        verify(button.enabled)
        mouseClick(button, button.width / 2, button.height / 2)
        compare(host.actionCount, 1)
        verify(host.collision.originItem === item, "Media activation must animate its own Dock item")
        host.collision.reset()
    }

    function test_differentCrossExtents_data() {
        return [{tag: "different-heights", vertical: false},
            {tag: "different-widths", vertical: true}]
    }

    function test_differentCrossExtents(data) {
        const host = createHost(data.vertical)
        const item = host.items[2]
        if (data.vertical) item.width = 90
        else item.height = 100
        item.activateItem()
        verify(host.collision.positiveItem === host.items[3], "Unequal sizes must keep the next neighbor")
        verify(host.collision.negativeItem === host.items[1], "Unequal sizes must keep the previous neighbor")
        host.collision.reset()
    }

    function test_isolatedAndUnavailableItems() {
        const host = createHost(false, false, 1)
        host.items[0].activateItem()
        compare(host.collision.positiveItem, null)
        compare(host.collision.negativeItem, null)
        settled(host)
        host.items[0].persistentReorderActive = true
        host.items[0].activateItem()
        compare(host.collision.running, false)
    }

    function test_actionsAreImmediateAndDoNotQueue() {
        const host = createHost()
        host.items[2].activateItem()
        tryVerify(function() { return host.collision.originOffset > 1 })
        const offset = host.collision.originOffset
        for (let n = 0; n < 12; n++) host.items[3].activateItem()
        compare(host.actionCount, 13)
        compare(host.collision.originItem, host.items[2])
        compare(host.collision.originOffset, offset)
        settled(host)
    }

    function test_cancelContinuesFromCurrentPosition() {
        const host = createHost()
        host.items[2].activateItem()
        tryVerify(function() { return host.collision.originOffset > 1 })
        const offset = host.collision.originOffset
        host.collision.cancel()
        fuzzyCompare(host.collision.originOffset, offset, 0.001)
        settled(host)
        host.items[2].activateItem()
        compare(host.collision.running, true)
        host.items[2].clickEffect = "bounce"
        settled(host)
    }

    function test_removalAndRecreation() {
        const host = createHost()
        host.items[2].activateItem()
        tryVerify(function() { return host.collision.originOffset > 1 })
        const removed = host.items[3]
        host.items[3] = null
        removed.destroy()
        wait(0)
        settled(host)
        host.items[3] = host.addItem(3)
        host.items[2].activateItem()
        compare(host.collision.positiveItem, host.items[3])
        settled(host)
    }

    function test_keyboardAndRightClick() {
        const host = createHost()
        const item = host.items[2]
        mouseClick(item, 30, 30, Qt.RightButton)
        compare(host.actionCount, 0)
        compare(host.collision.running, false)
        item.focusItem()
        tryVerify(function() { return host.activeFocusItem !== null })
        keyClick(Qt.Key_Return)
        compare(host.actionCount, 1)
        compare(host.collision.running, true)
        settled(host)
    }

    function test_hoverSizeAndLiveConfiguration() {
        const host = createHost()
        host.items[2].hoverAnimationMode = "wave"
        host.container.pointerPrimaryAxis = host.items[2].x + 30
        host.container.lastPointerPrimaryAxis = host.container.pointerPrimaryAxis
        host.container.wavePointerInsideLayout = true
        host.items[2].hoverZoomProgress = 1
        host.items[2].activateItem()
        verify(host.collision.positiveReach <= host.items[2].iconSize * 0.45)
        settled(host)
        host.collision.motionSpeedPercent = 100
        compare(host.collision.beat, Kirigami.Units.shortDuration)
        host.items[2].activateItem()
        host.collision.enabled = false
        settled(host)
        host.collision.enabled = true
        host.items[2].activateItem()
        compare(host.collision.running, true)
        settled(host)
        const config = createTemporaryObject(configComponent, testCase)
        verify(config !== null)
        verify(config.clickEffectOptions.some(function(option) { return option.value === "collision" }))
        compare(config.cfg_clickEffect, "bounce")
        config.cfg_clickEffect = "collision"
        compare(config.cfg_clickEffect, "collision")
    }

    function test_themeInstantProfile() {
        const host = createHost()
        host.items[2].activateItem()
        compare(host.actionCount, 1)
        compare(host.collision.motionEnabled, Kirigami.Units.longDuration > 1)
        compare(host.collision.running, host.collision.motionEnabled)
        if (!host.collision.motionEnabled) {
            settled(host)
            mousePress(host.items[2], 30, 30)
            const feedback = findChild(host.items[2], "dockItemClickFeedback")
            verify(feedback !== null)
            fuzzyCompare(feedback.visualOpacity, 0.72, 0.001)
            mouseRelease(host.items[2], 30, 30)
            compare(host.actionCount, 2)
            settled(host)
        } else {
            host.collision.reset()
        }
    }
}
