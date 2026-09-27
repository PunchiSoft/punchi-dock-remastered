// SPDX-License-Identifier: GPL-2.0-or-later

// Integration tests for the plasma-pa volume adapter.
//
// This file runs in its own process and loads the real audio stack, so the host
// audio server takes part in the result. `tests/CMakeLists.txt` silences the
// org.kde.pulseaudio category for this test only: plasma-pa warns while it
// registers the default source, and that warning depends on the host (it
// appears when the default source is the sink monitor, for example after a
// Bluetooth headset disconnects). The project cannot fix a foreign library
// message, and ctest also treats a QWARN line as a failure.
//
// Interface behaviour with a simulated adapter lives in
// control_center_audio_page_test.qml and must not be added here.

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterAudioBackend"
    when: windowShown
    property var hostWindowUnderTest: null

    Component {
        id: realAdapterComponent

        ControlCenter.ControlCenterVolumeAdapter {}
    }

    Component {
        id: realAudioPageWindowComponent

        Window {
            id: realHostWindow
            width: 640
            height: 700
            visible: true

            property alias page: realAudioPage

            ControlCenter.ControlCenterVolumeAdapter {
                id: realAdapter
            }

            ControlCenter.ControlCenterAudioPage {
                id: realAudioPage
                anchors.fill: parent
                adapter: realAdapter
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

    function test_privatePlasmaPaTypesInstantiateWhenAvailable() {
        const adapter = createTemporaryObject(realAdapterComponent, testCase)
        verify(adapter !== null)
        verify(adapter.normalVolume > 0)
        verify(adapter.outputDevicesModel !== null)
        verify(adapter.inputDevicesModel !== null)
        verify(adapter.playbackStreamsModel !== null)
        verify(adapter.recordingStreamsModel !== null)
        verify(adapter.cardModel !== null)
        verify(adapter.sinkItemType !== adapter.sourceItemType)
        verify(adapter.maximumPercentage >= 100)
        adapter.destroy()
    }

    function test_realPlasmaPaModelsPopulateThePage() {
        const hostWindow = createTemporaryObject(
            realAudioPageWindowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        verify(hostWindow.page.deviceCount >= 0)
        verify(hostWindow.page.applicationCount >= 0)
        if (hostWindow.page.deviceCount > 0) {
            verify(findChild(
                hostWindow.page, "controlCenterAudioItem") !== null)
        }
    }
}
