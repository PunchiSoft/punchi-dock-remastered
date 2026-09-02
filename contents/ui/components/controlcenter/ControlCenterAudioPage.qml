// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras

FocusScope {
    id: root

    required property var adapter
    property bool showVirtualDevices: false

    readonly property int outputDeviceCount:
        modelCount(adapter.outputDevicesModel)
    readonly property int inputDeviceCount:
        modelCount(adapter.inputDevicesModel)
    readonly property int playbackStreamCount:
        modelCount(adapter.playbackStreamsModel)
    readonly property int recordingStreamCount:
        modelCount(adapter.recordingStreamsModel)
    readonly property int deviceCount:
        outputDeviceCount + inputDeviceCount
    readonly property int applicationCount:
        playbackStreamCount + recordingStreamCount
    readonly property bool deviceSectionsVisible:
        outputDeviceCount > 1 || inputDeviceCount > 1
    readonly property bool applicationSectionsVisible:
        playbackStreamCount > 1 || recordingStreamCount > 1

    signal backRequested()
    signal settingsRequested(string section)
    signal showVirtualDevicesToggled(bool enabled)

    function modelCount(model) {
        return model && Number.isFinite(Number(model.count))
            ? Number(model.count) : 0
    }

    function deviceLabel(model) {
        const description = String(model.Description || "")
        if (description.length > 0) {
            return description
        }
        const name = String(model.Name || "")
        return name.length > 0
            ? name : i18nc("@info", "Unnamed audio device") // qmllint disable unqualified
    }

    function streamLabel(model) {
        const parts = []
        const client = model.Client
        if (client && client.name
                && client.name !== "pipewire-media-session") {
            parts.push(String(client.name))
        } else if (model.Name) {
            parts.push(String(model.Name))
        }
        const properties = model.Properties || {}
        const mediaName = String(properties["media.name"] || "")
        if (mediaName.length > 0
                && !/playback|audio|stream|alsa|pulse|pipewire/i.test(
                    mediaName)) {
            parts.push(mediaName)
        }
        return parts.length > 0
            ? parts.join(" — ")
            : i18nc("@info", "Unknown audio stream") // qmllint disable unqualified
    }

    function focusFirstControl() {
        backButton.forceActiveFocus(Qt.PopupFocusReason)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.mediumSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.mediumSpacing

            PlasmaComponents.ToolButton {
                id: backButton

                objectName: "controlCenterAudioBackButton"
                icon.name: Application.layoutDirection === Qt.RightToLeft
                    ? "go-next" : "go-previous"
                text: i18nc("@action:button", "Back to Control Center") // qmllint disable unqualified
                display: PlasmaComponents.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: root.backRequested()
            }

            Controls.Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: i18nc("@title", "Sound Volume") // qmllint disable unqualified
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.25
                font.bold: true
                elide: Text.ElideRight
            }

            PlasmaComponents.ToolButton {
                id: globalOptionsButton

                objectName: "controlCenterAudioGlobalOptionsButton"
                icon.name: "overflow-menu"
                text: i18nc("@action:button", "Global sound options") // qmllint disable unqualified
                display: PlasmaComponents.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: {
                    globalOptionsMenu.x = 0
                    globalOptionsMenu.y = height
                    globalOptionsMenu.open()
                }
            }

            PlasmaComponents.ToolButton {
                id: settingsButton

                objectName: "controlCenterAudioSettingsButton"
                icon.name: "configure"
                text: i18nc("@action:button", "Open sound settings") // qmllint disable unqualified
                display: PlasmaComponents.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: root.settingsRequested("sound")
            }
        }

        Controls.Menu {
            id: globalOptionsMenu

            parent: globalOptionsButton

            Controls.MenuItem {
                text: i18nc("@option:check", "Force mute all playback devices") // qmllint disable unqualified
                checkable: true
                checked: root.adapter.globalMuteSinks
                onTriggered: root.adapter.toggleGlobalMuteSinks()
            }

            Controls.MenuItem {
                text: i18nc("@option:check", "Force mute all input devices") // qmllint disable unqualified
                checkable: true
                checked: root.adapter.globalMuteSources
                onTriggered: root.adapter.toggleGlobalMuteSources()
            }

            Controls.MenuSeparator {}

            Controls.MenuItem {
                text: i18nc("@option:check", "Show virtual devices") // qmllint disable unqualified
                checkable: true
                checked: root.showVirtualDevices
                onTriggered: root.showVirtualDevicesToggled(checked)
            }
        }

        Controls.TabBar {
            id: tabBar

            objectName: "controlCenterAudioTabBar"
            Layout.fillWidth: true

            Controls.TabButton {
                objectName: "controlCenterAudioDevicesTab"
                text: i18nc("@title:tab", "Devices") // qmllint disable unqualified
                onClicked: tabBar.currentIndex = 0
            }

            Controls.TabButton {
                objectName: "controlCenterAudioApplicationsTab"
                text: i18nc("@title:tab", "Applications") // qmllint disable unqualified
                onClicked: tabBar.currentIndex = 1
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Kirigami.Units.cornerRadius * 2.5
            color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.78)
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.16)

            StackLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.mediumSpacing
                currentIndex: tabBar.currentIndex

                Controls.ScrollView {
                    id: devicesScroll

                    objectName: "controlCenterAudioDevicesView"
                    clip: true
                    contentWidth: availableWidth
                    Accessible.role: Accessible.List
                    // qmllint disable unqualified
                    Accessible.name: i18nc(
                        "@info:accessibility", "Audio devices")
                    // qmllint enable unqualified

                    ColumnLayout {
                        width: devicesScroll.availableWidth
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaExtras.ListSectionHeader {
                            Layout.fillWidth: true
                            visible: root.outputDeviceCount > 0
                                && root.deviceSectionsVisible
                            text: i18nc("@title:group", "Output Devices") // qmllint disable unqualified
                        }

                        Repeater {
                            model: root.adapter.outputDevicesModel

                            delegate: ControlCenterAudioItem {
                                required property var model

                                Layout.fillWidth: true
                                adapter: root.adapter
                                audioObject: model.PulseObject
                                itemType: root.adapter.sinkItemType
                                label: root.deviceLabel(model)
                                iconName: String(model.IconName || "audio-volume-high")
                                description: defaultDevice
                                    ? i18nc("@info:status", "Default output") // qmllint disable unqualified
                                    : ""
                                routingModel:
                                    root.adapter.outputDevicesModel
                                defaultSelectorVisible:
                                    root.deviceSectionsVisible
                            }
                        }

                        PlasmaExtras.ListSectionHeader {
                            Layout.fillWidth: true
                            visible: root.inputDeviceCount > 0
                                && root.deviceSectionsVisible
                            text: i18nc("@title:group", "Input Devices") // qmllint disable unqualified
                        }

                        Repeater {
                            model: root.adapter.inputDevicesModel

                            delegate: ControlCenterAudioItem {
                                required property var model

                                Layout.fillWidth: true
                                adapter: root.adapter
                                audioObject: model.PulseObject
                                itemType: root.adapter.sourceItemType
                                label: root.deviceLabel(model)
                                iconName: String(model.IconName
                                    || "audio-input-microphone")
                                description: defaultDevice
                                    ? i18nc("@info:status", "Default input") // qmllint disable unqualified
                                    : ""
                                routingModel:
                                    root.adapter.inputDevicesModel
                                defaultSelectorVisible:
                                    root.deviceSectionsVisible
                            }
                        }

                        PlasmaExtras.PlaceholderMessage {
                            Layout.fillWidth: true
                            Layout.preferredHeight:
                                Kirigami.Units.gridUnit * 12
                            visible: root.deviceCount === 0
                            iconName: "audio-volume-muted"
                            text: i18nc("@info", "No audio devices available") // qmllint disable unqualified
                            // qmllint disable unqualified
                            explanation: i18nc(
                                "@info",
                                "Connect a device or open Sound Settings for details.")
                            // qmllint enable unqualified
                        }
                    }
                }

                Controls.ScrollView {
                    id: applicationsScroll

                    objectName: "controlCenterAudioApplicationsView"
                    clip: true
                    contentWidth: availableWidth
                    Accessible.role: Accessible.List
                    // qmllint disable unqualified
                    Accessible.name: i18nc(
                        "@info:accessibility", "Application audio streams")
                    // qmllint enable unqualified

                    ColumnLayout {
                        width: applicationsScroll.availableWidth
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaExtras.ListSectionHeader {
                            Layout.fillWidth: true
                            visible: root.playbackStreamCount > 0
                                && root.applicationSectionsVisible
                            text: i18nc("@title:group", "Playing Audio") // qmllint disable unqualified
                        }

                        Repeater {
                            model: root.adapter.playbackStreamsModel

                            delegate: ControlCenterAudioItem {
                                required property var model

                                Layout.fillWidth: true
                                adapter: root.adapter
                                audioObject: model.PulseObject
                                itemType: root.adapter.sinkInputItemType
                                label: root.streamLabel(model)
                                iconName: String(model.IconName
                                    || "audio-volume-high")
                                routingModel:
                                    root.adapter.outputDevicesModel
                            }
                        }

                        PlasmaExtras.ListSectionHeader {
                            Layout.fillWidth: true
                            visible: root.recordingStreamCount > 0
                                && root.applicationSectionsVisible
                            text: i18nc("@title:group", "Recording Audio") // qmllint disable unqualified
                        }

                        Repeater {
                            model: root.adapter.recordingStreamsModel

                            delegate: ControlCenterAudioItem {
                                required property var model

                                Layout.fillWidth: true
                                adapter: root.adapter
                                audioObject: model.PulseObject
                                itemType: root.adapter.sourceOutputItemType
                                label: root.streamLabel(model)
                                iconName: String(model.IconName
                                    || "audio-input-microphone")
                                routingModel:
                                    root.adapter.inputDevicesModel
                            }
                        }

                        PlasmaExtras.PlaceholderMessage {
                            Layout.fillWidth: true
                            Layout.preferredHeight:
                                Kirigami.Units.gridUnit * 12
                            visible: root.applicationCount === 0
                            iconName: "application-x-executable"
                            text: i18nc("@info", "No applications are playing or recording audio") // qmllint disable unqualified
                            // qmllint disable unqualified
                            explanation: i18nc(
                                "@info",
                                "Applications appear here while they use an audio stream.")
                            // qmllint enable unqualified
                        }
                    }
                }
            }
        }

        PlasmaComponents.CheckBox {
            id: raiseMaximumCheckBox

            objectName: "controlCenterRaiseMaximumVolumeCheckBox"
            Layout.fillWidth: true
            text: i18nc("@option:check", "Raise maximum volume") // qmllint disable unqualified
            checked: root.adapter.raiseMaximumVolume
            enabled: root.adapter.raiseMaximumVolumeWritable
            Accessible.description: checked
                ? i18nc("@info:accessibility", "Volumes can be raised above 100 percent") // qmllint disable unqualified
                : i18nc("@info:accessibility", "Volumes are limited to 100 percent") // qmllint disable unqualified
            onClicked: root.adapter.setRaiseMaximumVolume(checked)
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: raiseMaximumCheckBox.checked
            type: Kirigami.MessageType.Warning
            // qmllint disable unqualified
            text: i18nc(
                "@info",
                "Volumes above 100% can reduce audio quality and cause distortion.")
            // qmllint enable unqualified
        }
    }
}
