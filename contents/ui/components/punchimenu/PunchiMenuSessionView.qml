import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
FocusScope {
    id: root

    required property string userName
    required property url userAvatar
    required property bool canLogout
    required property bool canRestart
    required property bool canShutdown

    readonly property int avatarSize: Kirigami.Units.gridUnit * 9

    signal logoutRequested()
    signal restartRequested()
    signal shutdownRequested()

    function focusInitialAction() {
        if (logoutButton.enabled) {
            logoutButton.forceActiveFocus()
        } else if (restartButton.enabled) {
            restartButton.forceActiveFocus()
        } else if (shutdownButton.enabled) {
            shutdownButton.forceActiveFocus()
        } else {
            root.forceActiveFocus()
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2,
            Kirigami.Units.gridUnit * 34)
        spacing: Kirigami.Units.gridUnit * 1.5

        PunchiMenuUserAvatar {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.avatarSize
            Layout.preferredHeight: width
            source: root.userAvatar
        }

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            text: root.userName
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            Accessible.role: Accessible.Heading
            Accessible.name: text
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.largeSpacing

            PlasmaComponents.Button {
                id: logoutButton
                readonly property bool highlightedContent: enabled
                    && (hovered || down || activeFocus)
                readonly property color foregroundColor: highlightedContent
                    ? root.Kirigami.Theme.highlightedTextColor
                    : root.Kirigami.Theme.textColor
                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                icon.name: "system-log-out"
                icon.color: foregroundColor
                Kirigami.Theme.textColor: foregroundColor
                text: i18nc("@action:button", "Log Out")
                display: PlasmaComponents.AbstractButton.TextUnderIcon
                enabled: root.canLogout
                hoverEnabled: true
                flat: false
                Accessible.name: text
                KeyNavigation.right: restartButton.enabled
                    ? restartButton : shutdownButton
                onClicked: root.logoutRequested()

                background: PunchiMenuActionBackground {
                    highlighted: logoutButton.highlightedContent
                    showBaseSurface: true
                }

                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: width
                        Layout.alignment: Qt.AlignHCenter
                        source: logoutButton.icon.name
                        color: logoutButton.foregroundColor
                        Accessible.ignored: true
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: logoutButton.text
                        textFormat: Text.PlainText
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        color: logoutButton.foregroundColor
                        Accessible.ignored: true
                    }
                }

                HoverHandler {
                    enabled: logoutButton.enabled
                    cursorShape: Qt.PointingHandCursor
                }
            }

            PlasmaComponents.Button {
                id: restartButton
                readonly property bool highlightedContent: enabled
                    && (hovered || down || activeFocus)
                readonly property color foregroundColor: highlightedContent
                    ? root.Kirigami.Theme.highlightedTextColor
                    : root.Kirigami.Theme.textColor
                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                icon.name: "system-reboot"
                icon.color: foregroundColor
                Kirigami.Theme.textColor: foregroundColor
                text: i18nc("@action:button", "Restart")
                display: PlasmaComponents.AbstractButton.TextUnderIcon
                enabled: root.canRestart
                hoverEnabled: true
                flat: false
                Accessible.name: text
                KeyNavigation.left: logoutButton.enabled
                    ? logoutButton : null
                KeyNavigation.right: shutdownButton.enabled
                    ? shutdownButton : null
                onClicked: root.restartRequested()

                background: PunchiMenuActionBackground {
                    highlighted: restartButton.highlightedContent
                    showBaseSurface: true
                }

                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: width
                        Layout.alignment: Qt.AlignHCenter
                        source: restartButton.icon.name
                        color: restartButton.foregroundColor
                        Accessible.ignored: true
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: restartButton.text
                        textFormat: Text.PlainText
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        color: restartButton.foregroundColor
                        Accessible.ignored: true
                    }
                }

                HoverHandler {
                    enabled: restartButton.enabled
                    cursorShape: Qt.PointingHandCursor
                }
            }

            PlasmaComponents.Button {
                id: shutdownButton
                readonly property bool highlightedContent: enabled
                    && (hovered || down || activeFocus)
                readonly property color foregroundColor: highlightedContent
                    ? root.Kirigami.Theme.highlightedTextColor
                    : root.Kirigami.Theme.textColor
                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                icon.name: "system-shutdown"
                icon.color: foregroundColor
                Kirigami.Theme.textColor: foregroundColor
                text: i18nc("@action:button", "Shut Down")
                display: PlasmaComponents.AbstractButton.TextUnderIcon
                enabled: root.canShutdown
                hoverEnabled: true
                flat: false
                Accessible.name: text
                KeyNavigation.left: restartButton.enabled
                    ? restartButton : logoutButton
                onClicked: root.shutdownRequested()

                background: PunchiMenuActionBackground {
                    highlighted: shutdownButton.highlightedContent
                    showBaseSurface: true
                }

                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: width
                        Layout.alignment: Qt.AlignHCenter
                        source: shutdownButton.icon.name
                        color: shutdownButton.foregroundColor
                        Accessible.ignored: true
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: shutdownButton.text
                        textFormat: Text.PlainText
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        color: shutdownButton.foregroundColor
                        Accessible.ignored: true
                    }
                }

                HoverHandler {
                    enabled: shutdownButton.enabled
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
// qmllint enable unqualified
