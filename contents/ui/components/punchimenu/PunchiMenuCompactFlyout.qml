// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
FocusScope {
    id: root

    property var applicationList: []
    property string categoryTitle: ""
    property bool motionEnabled: true
    property string hoverAnimation: "pulse"
    property int selectedItemIndex: -1
    property real backgroundOpacity: 0.85
    property bool backgroundBlurEnabled: true

    signal applicationActivated(string storageId)
    signal applicationContextRequested(var sourceItem, var application, real x, real y)
    signal returnToParentRequested()

    width: Math.round(Kirigami.Units.gridUnit * 20)
    implicitWidth: width
    implicitHeight: Math.round(Kirigami.Units.gridUnit * 27)

    readonly property real itemHeight: Math.round(Kirigami.Units.gridUnit * 2.1)
    readonly property real iconSize: Kirigami.Units.iconSizes.smallMedium

    function applicationStorageId(application) {
        if (!application) {
            return ""
        }
        return String(application.appStorageId || application.storageId || "")
    }

    function applicationName(application) {
        if (!application) {
            return i18nc("@label", "Application")
        }
        return String(application.appName || application.name
            || applicationStorageId(application)
            || i18nc("@label", "Application"))
    }

    function applicationIcon(application) {
        if (!application) {
            return "application-x-executable"
        }
        return String(application.appIcon || application.icon
            || "application-x-executable")
    }

    function selectFirstItem() {
        if (root.applicationList && root.applicationList.length > 0) {
            root.selectedItemIndex = 0
            appListView.currentIndex = 0
            root.forceActiveFocus()
        }
    }

    function selectPreviousItem() {
        if (!root.applicationList || root.applicationList.length === 0) {
            return
        }
        if (root.selectedItemIndex > 0) {
            root.selectedItemIndex--
        } else {
            root.selectedItemIndex = root.applicationList.length - 1
        }
        appListView.currentIndex = root.selectedItemIndex
    }

    function selectNextItem() {
        if (!root.applicationList || root.applicationList.length === 0) {
            return
        }
        if (root.selectedItemIndex < root.applicationList.length - 1) {
            root.selectedItemIndex++
        } else {
            root.selectedItemIndex = 0
        }
        appListView.currentIndex = root.selectedItemIndex
    }

    function activateSelectedItem() {
        if (root.selectedItemIndex >= 0
                && root.applicationList
                && root.selectedItemIndex < root.applicationList.length) {
            const app = root.applicationList[root.selectedItemIndex]
            const storageId = root.applicationStorageId(app)
            if (storageId.length > 0) {
                root.applicationActivated(storageId)
            }
        }
    }

    Keys.onUpPressed: function(event) {
        root.selectPreviousItem()
        event.accepted = true
    }

    Keys.onDownPressed: function(event) {
        root.selectNextItem()
        event.accepted = true
    }

    Keys.onLeftPressed: function(event) {
        root.returnToParentRequested()
        event.accepted = true
    }

    Keys.onReturnPressed: function(event) {
        root.activateSelectedItem()
        event.accepted = true
    }

    Keys.onEnterPressed: function(event) {
        root.activateSelectedItem()
        event.accepted = true
    }

    Keys.onEscapePressed: function(event) {
        root.returnToParentRequested()
        event.accepted = true
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Category Header Title
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.8)
            spacing: Kirigami.Units.smallSpacing
            visible: root.categoryTitle.length > 0

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 4
                text: root.categoryTitle
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                leftPadding: Kirigami.Units.smallSpacing
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            visible: root.categoryTitle.length > 0
        }

        // Applications List
        Controls.ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: appListView
                width: scrollView.availableWidth
                model: root.applicationList
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.selectedItemIndex

                delegate: Item {
                    id: appDelegate
                    required property int index
                    required property var modelData

                    readonly property var currentApp: modelData
                    readonly property string appStorageId: root.applicationStorageId(currentApp)
                    readonly property string appName: root.applicationName(currentApp)
                    readonly property string appIcon: root.applicationIcon(currentApp)
                    readonly property bool isSelected: root.selectedItemIndex === index

                    width: appListView.width
                    height: root.itemHeight

                    PunchiMenuItemHighlight {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        hovered: mouseArea.containsMouse
                        selected: appDelegate.isSelected
                        focused: appDelegate.isSelected && root.activeFocus
                        pressed: mouseArea.pressed
                        motionEnabled: root.motionEnabled
                        animationMode: root.hoverAnimation

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                            anchors.rightMargin: Kirigami.Units.smallSpacing * 2
                            spacing: Kirigami.Units.smallSpacing * 2

                            Kirigami.Icon {
                                Layout.preferredWidth: root.iconSize
                                Layout.preferredHeight: root.iconSize
                                source: appDelegate.appIcon
                                fallback: "application-x-executable"
                                smooth: true
                            }

                            Controls.Label {
                                Layout.fillWidth: true
                                text: appDelegate.appName
                                color: Kirigami.Theme.textColor
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onEntered: {
                            root.selectedItemIndex = appDelegate.index
                        }

                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                root.applicationContextRequested(
                                    appDelegate, appDelegate.currentApp,
                                    mouse.x, mouse.y)
                            } else {
                                if (appDelegate.appStorageId.length > 0) {
                                    root.applicationActivated(appDelegate.appStorageId)
                                }
                            }
                        }
                    }

                    Accessible.role: Accessible.MenuItem
                    Accessible.name: appDelegate.appName
                    Accessible.description: appDelegate.appStorageId
                }
            }
        }
    }
}
