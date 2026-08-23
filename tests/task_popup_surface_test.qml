pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "TaskPopupSurface"
    when: windowShown
    readonly property var surface: surfaceLoader.item

    QtObject {
        id: fakeMediaController

        property string applicationId: "org.mozilla.firefox"
        property bool resolving: false
        property bool available: true
        property string artUrl: ""
        property string track: "Test track"
        property string identity: "Test player"
        property string artist: "Test artist"
        property double lengthUs: 240000000
        property double positionUs: 60000000
        property bool playing: true
        property bool volumeAvailable: true
        property real volume: 0.7
        property bool canControl: true
        property bool shuffleAvailable: true
        property bool shuffle: false
        property bool canGoPrevious: true
        property bool canPause: true
        property bool canPlay: true
        property bool canGoNext: true
        property string loopStatus: "None"

        signal stateChanged()

        function setShuffle(value) {}
        function previous() {}
        function togglePlaying() {}
        function next() {}
        function cycleLoopStatus() {}
        function toggleMute() {}
        function setVolume(value) {}
    }

    Components.TaskPopupPresentationController {
        id: presentationController

        mediaEnabled: true
        mediaMode: "card"
        mediaControllerRef: fakeMediaController
    }

    Component {
        id: testBackgroundComponent

        Rectangle {
            color: "transparent"

            property QtObject margins: QtObject {
                readonly property real left: 11
                readonly property real top: 13
                readonly property real right: 17
                readonly property real bottom: 19
            }
        }
    }

    Component {
        id: testMediaProfileComponent

        Item {
            function focusFirstControl() {
                return true
            }
        }
    }

    Loader {
        id: surfaceLoader
        active: false

        sourceComponent: Component {
            Components.TaskPopupSurface {
                presentationMode: "none"
                mediaController: null
                contentFramePaddingPercent: 2
                minimumSurfaceWidth: 1
                minimumSurfaceHeight: 1
                backgroundComponent: testBackgroundComponent
                replacementProfileComponentOverride: testMediaProfileComponent
                replacementHeaderControlsEnabled: false

                Item {
                    implicitWidth: 220
                    implicitHeight: 140
                }
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        surfaceLoader.active = true
        verify(surface !== null)
        fakeMediaController.applicationId = "org.mozilla.firefox"
        fakeMediaController.resolving = false
        fakeMediaController.available = true
        fakeMediaController.artUrl = ""
        presentationController.mediaEnabled = true
        presentationController.mediaMode = "card"
    }

    function cleanup() {
        surfaceLoader.active = false
    }

    function prepareSurface(presentation) {
        surface.mediaController = fakeMediaController
        surface.presentationMode = presentation
        surface.mediaActionsComposed = false
        wait(0)
    }

    function test_00_surfaceLoadsWithoutPresentation() {
        compare(surface.presentationMode, "none")
        verify(!surface.geometryReady)
    }

    function test_01_previewLoadsTheSingleBackground() {
        surface.presentationMode = "preview"
        wait(0)
        verify(surface.geometryReady)
    }

    function test_02_cardReservesGeometryButWaitsForControllerData() {
        surface.mediaController = fakeMediaController
        fakeMediaController.available = false
        surface.presentationMode = "card"
        wait(0)

        verify(surface.implicitWidth > 0)
        verify(surface.implicitHeight > 0)
        verify(!surface.geometryReady)

        fakeMediaController.available = true
        fakeMediaController.stateChanged()
        wait(0)
        verify(surface.geometryReady)
    }

    function test_presentationMatrixIsExclusive() {
        compare(presentationController.resolve("org.mozilla.firefox", true),
            "card")

        presentationController.mediaMode = "fullCard"
        compare(presentationController.resolve("org.mozilla.firefox", true),
            "fullCard")

        fakeMediaController.available = false
        fakeMediaController.resolving = true
        compare(presentationController.resolve("org.mozilla.firefox", true),
            "waiting")

        fakeMediaController.resolving = false
        compare(presentationController.resolve("org.mozilla.firefox", true),
            "preview")
        compare(presentationController.resolve("org.mozilla.firefox", false),
            "none")

        presentationController.mediaMode = "overlay"
        compare(presentationController.resolve("org.mozilla.firefox", true),
            "overlay")
        compare(presentationController.resolve("org.mozilla.firefox", false),
            "none")
    }

    function test_cardGeometryDoesNotDependOnArtworkReadiness() {
        prepareSurface("card")
        verify(surface.geometryReady)
        const initialWidth = surface.implicitWidth
        const initialHeight = surface.implicitHeight

        fakeMediaController.artUrl =
            "file:///this/path/intentionally/does/not/exist.png"
        fakeMediaController.stateChanged()
        wait(50)

        compare(surface.implicitWidth, initialWidth)
        compare(surface.implicitHeight, initialHeight)
        verify(surface.geometryReady)
    }

    function test_profilesHaveIndependentStableMetrics() {
        prepareSurface("card")
        const cardHeight = surface.implicitHeight

        surface.presentationMode = "fullCard"
        wait(0)
        const fullCardHeight = surface.implicitHeight

        verify(cardHeight > fullCardHeight)
        compare(cardHeight,
            surface.containedCardHeight + surface.contentPaddingTop
                + surface.contentPaddingBottom)
        compare(fullCardHeight,
            surface.fullCoverCardHeight + surface.contentPaddingTop
                + surface.contentPaddingBottom)
        verify(surface.geometryReady)
    }

    function test_thinFrameAvoidsASecondThemeMarginGutter() {
        prepareSurface("card")

        compare(surface.contentPaddingLeft, surface.contentFramePadding)
        compare(surface.contentPaddingTop, surface.contentFramePadding)
        compare(surface.contentPaddingRight, surface.contentFramePadding)
        compare(surface.contentPaddingBottom, surface.contentFramePadding)
        verify(surface.contentFramePadding < 11)
        compare(surface.implicitWidth,
            surface.internalWidth + surface.contentFramePadding * 2)
        compare(surface.implicitHeight,
            surface.internalHeight + surface.contentFramePadding * 2)
    }

    function test_actionsSelectCompactProfileWithoutChangingPresentation() {
        prepareSurface("card")
        surface.mediaActionsComposed = true
        wait(0)

        verify(surface.compactMediaPresentation)
        compare(surface.presentationMode, "card")
        compare(surface.internalHeight, surface.compactCardHeight
            + surface.contentGap + surface.contentImplicitHeight)
        verify(surface.geometryReady)
    }

    function test_actionsReserveHeightInsideAvailableSurface() {
        prepareSurface("card")
        surface.maximumSurfaceHeight = 500
        surface.mediaActionsComposed = true
        wait(0)

        compare(surface.maximumContentHeight,
            500 - surface.maximumVerticalFramePaddingReservation
                - surface.compactCardHeight - surface.contentGap)
        verify(surface.maximumContentHeight < surface.maximumSurfaceHeight)
    }
}
