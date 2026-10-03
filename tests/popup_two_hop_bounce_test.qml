import QtQuick
import QtTest
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "PopupTwoHopBounce"
    when: windowShown
    visible: true
    width: 700
    height: 500

    Component {
        id: popupComponent
        Components.PopupAnimatedContent {
            id: fixture
            spatialBounceEnabled: true
            animationStyle: "bounce"
            animationSpeedPercent: 50
            property int activationCount: 0
            property alias panel: panel
            property var samples: []
            Connections {
                target: fixture.bounceMotion
                function onProgressChanged() {
                    fixture.samples.push(fixture.bounceMotion.progress)
                }
            }
            Rectangle {
                id: panel
                implicitWidth: 280
                implicitHeight: 180
                focus: true
                Keys.onReturnPressed: fixture.activationCount++
                MouseArea {
                    anchors.fill: parent
                    onClicked: fixture.activationCount++
                }
            }
        }
    }

    Component {
        id: geometryComponent
        Components.DockGeometryState {}
    }

    Component {
        id: coordinatorComponent
        Components.PopupCoordinator {}
    }

    Component {
        id: anchorComponent
        Item {
            width: 48
            height: 48
            property real centerX: 0
            property real centerY: 0
            function mapToGlobal(_point) { return Qt.point(centerX, centerY) }
        }
    }

    Component {
        id: spyComponent
        SignalSpy { signalName: "closeAnimationFinished" }
    }

    function init() { failOnWarning(/.?/) }

    function createPopup(edge) {
        const popup = createTemporaryObject(popupComponent, testCase)
        verify(popup !== null)
        popup.popupDirection = edge === undefined ? Qt.BottomEdge : edge
        return popup
    }

    function open(popup) {
        popup.popupVisible = true
        popup.beginOpening()
        tryVerify(function() { return popup.bounceMotion.running })
    }

    function checkBounds(popup) {
        const surface = popup.transformSurfaceItem
        const topLeft = surface.mapToItem(popup, 0, 0)
        verify(topLeft.x >= -0.01, "The surface must stay inside the left edge")
        verify(topLeft.y >= -0.01, "The surface must stay inside the top edge")
        verify(topLeft.x + surface.width <= popup.width + 0.01,
            "The surface must stay inside the right edge")
        verify(topLeft.y + surface.height <= popup.height + 0.01,
            "The surface must stay inside the bottom edge")
        fuzzyCompare(surface.scale, 1, 0.001)
        compare(surface.width, 280)
        compare(surface.height, 180)
    }

    function test_singleHopStaysInsideWindow_data() {
        const edges = [
            {tag: "bottom-dock", dockEdge: PlasmaCore.Types.BottomEdge,
                edge: Qt.TopEdge, vertical: true, sign: -1, x: 400, y: 616},
            {tag: "top-dock", dockEdge: PlasmaCore.Types.TopEdge,
                edge: Qt.BottomEdge, vertical: true, sign: 1, x: 400, y: 24},
            {tag: "left-dock", dockEdge: PlasmaCore.Types.LeftEdge,
                edge: Qt.RightEdge, vertical: false, sign: 1, x: 24, y: 320},
            {tag: "right-dock", dockEdge: PlasmaCore.Types.RightEdge,
                edge: Qt.LeftEdge, vertical: false, sign: -1, x: 776, y: 320}
        ]
        const cases = []
        for (const edge of edges) {
            for (const floating of [false, true]) {
                cases.push(Object.assign({}, edge, {
                    tag: edge.tag + (floating ? "-floating" : "-panel"),
                    floating: floating
                }))
            }
        }
        return cases
    }

    function checkSettledDockEdge(popup, direction) {
        const surface = popup.transformSurfaceItem
        const origin = surface.mapToItem(popup, 0, 0)
        if (direction === Qt.TopEdge) {
            fuzzyCompare(origin.y + surface.height, popup.height, 0.001)
        } else if (direction === Qt.BottomEdge) {
            fuzzyCompare(origin.y, 0, 0.001)
        } else if (direction === Qt.LeftEdge) {
            fuzzyCompare(origin.x + surface.width, popup.width, 0.001)
        } else {
            fuzzyCompare(origin.x, 0, 0.001)
        }
    }

    function test_singleHopStaysInsideWindow(data) {
        const geometry = createTemporaryObject(geometryComponent, testCase, {
            inPanel: !data.floating,
            panelLocation: data.dockEdge,
            verticalPanel: !data.vertical,
            horizontalPanel: data.vertical,
            availableScreenRect: Qt.rect(0, 0, 800, 640)
        })
        verify(geometry !== null)
        const coordinator = createTemporaryObject(coordinatorComponent, testCase, {
            inPanel: !data.floating,
            panelPopupDirection: geometry.popupDirection,
            availableScreenRect: Qt.rect(0, 0, 800, 640),
            geometryStateRef: geometry
        })
        verify(coordinator !== null)
        const anchor = createTemporaryObject(anchorComponent, testCase, {
            centerX: data.x, centerY: data.y
        })
        verify(anchor !== null)
        coordinator.preparePopupAnchor(anchor)
        compare(geometry.effectivePanelLocation, data.dockEdge)
        compare(coordinator.popupDirection, data.edge)
        const popup = createPopup(coordinator.popupDirection)
        popup.animationIntensityPercent = 200
        const width = popup.width
        const height = popup.height
        open(popup)
        tryVerify(function() { return popup.bounceMotion.progress > 0.6 })
        verify((data.vertical ? popup.contentTranslationY : popup.contentTranslationX)
            * data.sign > 1)
        checkBounds(popup)
        const deadline = Date.now() + popup.animationDuration * 3 + 500
        while (popup.bounceMotion.running && Date.now() < deadline) {
            checkBounds(popup)
            compare(popup.width, width)
            compare(popup.height, height)
            wait(16)
        }
        compare(popup.bounceMotion.running, false)
        compare(popup.bounceMotion.progress, 0)
        const peaks = []
        for (let i = 1; i < popup.samples.length - 1; ++i) {
            if (popup.samples[i] > popup.samples[i - 1]
                    && popup.samples[i] > popup.samples[i + 1]) {
                peaks.push(popup.samples[i])
            }
        }
        compare(peaks.length, 1)
        fuzzyCompare(peaks[0], 1, 0.001)
        checkBounds(popup)
        checkSettledDockEdge(popup, coordinator.popupDirection)
    }

    function test_closeInterruptsWithoutJump() {
        const popup = createPopup()
        const spy = createTemporaryObject(spyComponent, testCase, {target: popup})
        open(popup)
        tryVerify(function() { return popup.bounceMotion.progress > 0.6 })
        const offset = popup.contentTranslationY
        popup.beginClosing()
        fuzzyCompare(popup.contentTranslationY, offset, 0.001)
        compare(spy.count, 0)
        tryCompare(spy, "count", 1)
        compare(popup.openingProgress, 0)
        compare(popup.bounceMotion.progress, 0)
        compare(popup.closing, false)
        checkBounds(popup)
    }

    function test_cancelClosingPreservesCurrentGeometry() {
        const popup = createPopup()
        const spy = createTemporaryObject(spyComponent, testCase, {target: popup})
        open(popup)
        tryVerify(function() { return popup.bounceMotion.progress > 0.6 })
        popup.beginClosing()
        const offset = popup.contentTranslationY
        popup.cancelClosing()
        fuzzyCompare(popup.contentTranslationY, offset, 0.001)
        tryCompare(popup, "openingProgress", 1)
        tryCompare(popup.bounceMotion, "running", false)
        compare(spy.count, 0)
        checkBounds(popup)
    }

    function test_effectChangeRemovesMovementReservation() {
        const popup = createPopup()
        open(popup)
        tryVerify(function() { return popup.bounceMotion.progress > 0.2 })
        popup.animationStyle = "fade"
        compare(popup.bounceMotion.running, false)
        compare(popup.bounceHorizontalMargin, 0)
        compare(popup.bounceVerticalMargin, 0)
        compare(popup.width, 280)
        compare(popup.height, 180)
        compare(popup.contentTranslationX, 0)
        compare(popup.contentTranslationY, 0)
    }

    function test_hiddenPopupResetsMovement() {
        const popup = createPopup()
        open(popup)
        tryVerify(function() { return popup.bounceMotion.progress > 0.2 })
        popup.popupVisible = false
        compare(popup.bounceMotion.running, false)
        compare(popup.bounceMotion.progress, 0)
        compare(popup.openingProgress, 0)
    }

    function test_controlsRemainInteractiveAfterOpening() {
        const popup = createPopup()
        open(popup)
        tryCompare(popup.bounceMotion, "running", false)
        mouseClick(popup.panel, 30, 30)
        compare(popup.activationCount, 1)
        popup.panel.forceActiveFocus()
        tryCompare(popup.panel, "activeFocus", true)
        keyClick(Qt.Key_Return)
        compare(popup.activationCount, 2)
    }

    function test_speedIntensityAndLegacyProfile() {
        const popup = createPopup()
        const distance = popup.bounceDistance
        const duration = popup.animationDuration
        popup.animationIntensityPercent = 200
        compare(popup.bounceDistance, distance * 2)
        popup.animationSpeedPercent = 100
        compare(popup.animationDuration, Math.round(duration / 2))
        popup.spatialBounceEnabled = false
        compare(popup.bounceVerticalMargin, 0)
        compare(popup.bounceHorizontalMargin, 0)
        compare(popup.height, 180)
        verify(popup.transformSurfaceItem.scale < 1,
            "Other consumers must retain the existing scale bounce")
    }

    function test_themeInstantProfile() {
        const popup = createPopup()
        const spy = createTemporaryObject(spyComponent, testCase, {target: popup})
        popup.popupVisible = true
        if (Kirigami.Units.longDuration <= 1) {
            compare(popup.spatialBounceActive, false)
            compare(popup.bounceVerticalMargin, 0)
            compare(popup.openingPending, false)
            compare(popup.openingProgress, 1)
            compare(popup.transformSurfaceItem.scale, 1)
            compare(popup.bounceMotion.running, false)
            popup.beginClosing()
            tryCompare(spy, "count", 1)
        } else {
            verify(popup.spatialBounceActive)
            popup.popupVisible = false
        }
    }
}
