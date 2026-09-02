// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterAudioPage"
    when: windowShown
    property var hostWindowUnderTest: null

    SignalSpy {
        id: backSpy
        signalName: "backRequested"
    }

    SignalSpy {
        id: settingsSpy
        signalName: "settingsRequested"
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 640
            height: 700
            visible: true

            property alias page: audioPage
            property alias fakeAdapter: adapter

            QtObject {
                id: adapter

                property var outputDevicesModel: ListModel {}
                property var inputDevicesModel: ListModel {}
                property var playbackStreamsModel: ListModel {}
                property var recordingStreamsModel: ListModel {}
                property bool globalMuteSinks: false
                property bool globalMuteSources: false
                property bool raiseMaximumVolume: false
                property bool raiseMaximumVolumeWritable: true
                property int maximumPercentage: 100
                property int sinkItemType: 1
                property int sinkInputItemType: 2
                property int sourceItemType: 3
                property int sourceOutputItemType: 4
                property int raiseMaximumChanges: 0

                function percentageFor(audioObject) { return 50 }
                function setObjectValue(audioObject, value) { return true }
                function toggleObjectMuted(audioObject) { return true }
                function setDefaultDevice(audioObject) { return true }
                function openItemOptions(audioObject, itemType,
                        routingModel, visualParent) { return true }
                function toggleGlobalMuteSinks() {}
                function toggleGlobalMuteSources() {}
                function setRaiseMaximumVolume(enabled) {
                    raiseMaximumChanges++
                    raiseMaximumVolume = enabled
                    return true
                }
            }

            ControlCenter.ControlCenterAudioPage {
                id: audioPage
                anchors.fill: parent
                adapter: adapter
            }
        }
    }

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
        backSpy.clear()
        settingsSpy.clear()
    }

    function cleanup() {
        backSpy.target = null
        settingsSpy.target = null
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
    }

    function test_tabsNavigationAndHeaderActions() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const page = hostWindow.page
        const tabBar = findChild(page, "controlCenterAudioTabBar")
        const applicationsTab = findChild(
            page, "controlCenterAudioApplicationsTab")
        const devicesView = findChild(page, "controlCenterAudioDevicesView")
        const applicationsView = findChild(
            page, "controlCenterAudioApplicationsView")
        const backButton = findChild(page, "controlCenterAudioBackButton")
        const settingsButton = findChild(
            page, "controlCenterAudioSettingsButton")

        verify(tabBar !== null)
        verify(applicationsTab !== null)
        verify(devicesView !== null)
        verify(applicationsView !== null)
        verify(backButton !== null)
        verify(settingsButton !== null)
        compare(tabBar.currentIndex, 0)
        compare(devicesView.visible, true)
        compare(applicationsView.visible, false)

        applicationsTab.clicked()
        tryCompare(tabBar, "currentIndex", 1)
        compare(devicesView.visible, false)
        compare(applicationsView.visible, true)

        backSpy.target = page
        mouseClick(backButton, backButton.width / 2, backButton.height / 2)
        compare(backSpy.count, 1)

        settingsSpy.target = page
        mouseClick(settingsButton,
            settingsButton.width / 2, settingsButton.height / 2)
        compare(settingsSpy.count, 1)
        compare(settingsSpy.signalArguments[0][0], "sound")
    }

    function test_raiseMaximumIsExplicitAndReactive() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const checkBox = findChild(
            hostWindow.page, "controlCenterRaiseMaximumVolumeCheckBox")
        verify(checkBox !== null)
        compare(checkBox.checked, false)
        mouseClick(checkBox, checkBox.width / 2, checkBox.height / 2)
        tryCompare(hostWindow.fakeAdapter, "raiseMaximumChanges", 1)
        compare(hostWindow.fakeAdapter.raiseMaximumVolume, true)
        compare(checkBox.checked, true)
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
