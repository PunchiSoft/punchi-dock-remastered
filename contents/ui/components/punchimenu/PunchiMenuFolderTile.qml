import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
FocusScope {
    id: root

    property string folderId: ""
    property string folderLabel: ""
    property var previewIcons: []
    property int memberCount: 0
    property bool selected: false
    property bool motionEnabled: true
    property real iconScale: 1.0
    readonly property alias hovered: pointer.containsMouse

    readonly property real effectiveIconScale: Math.max(0.5,
        Math.min(2.0, Number(iconScale || 1.0)))
    readonly property int previewSize: Math.round(
        Kirigami.Units.gridUnit * 3.7 * effectiveIconScale)
    readonly property string effectiveLabel: folderLabel.length > 0
        ? folderLabel
        : i18nc("@label", "Applications folder")
    readonly property string memberSummary: i18np("%1 application",
        "%1 applications", Math.max(0, memberCount))

    signal activated()
    signal contextRequested(var sourceItem, real x, real y)
    signal renameRequested()

    implicitWidth: Math.max(Kirigami.Units.gridUnit * 5.5,
        previewSize + Kirigami.Units.largeSpacing * 2)
    implicitHeight: previewSize + Kirigami.Units.gridUnit * 2.8
    activeFocusOnTab: true
    scale: pointer.pressed ? 0.97
        : pointer.containsMouse || activeFocus ? 1.015 : 1.0

    Accessible.role: Accessible.Button
    Accessible.name: i18nc("@info:accessible", "%1, %2",
        effectiveLabel, memberSummary)
    Accessible.description: i18nc("@info:accessible",
        "Open this application folder")
    Accessible.focused: selected || activeFocus
    Accessible.onPressAction: root.activated()

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius
        color: root.selected || root.activeFocus
            ? Qt.alpha(Kirigami.Theme.highlightColor, 0.30)
            : pointer.containsMouse
                ? Qt.alpha(Kirigami.Theme.textColor, 0.09)
                : "transparent"
        border.width: root.activeFocus ? 2 : root.selected ? 1 : 0
        border.color: Kirigami.Theme.highlightColor

        Behavior on color {
            enabled: root.motionEnabled
            ColorAnimation {
                duration: Math.max(90,
                    Math.min(150, Kirigami.Units.shortDuration))
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Item {
            Layout.preferredWidth: root.previewSize
            Layout.preferredHeight: root.previewSize
            Layout.alignment: Qt.AlignHCenter

            Kirigami.Icon {
                anchors.fill: parent
                source: "folder"
                opacity: 0.92
                Accessible.ignored: true
            }

            Grid {
                id: previewGrid
                anchors.centerIn: parent
                width: parent.width * 0.63
                height: width
                columns: 2
                rows: 2
                spacing: Math.max(1, Math.round(width * 0.06))

                Repeater {
                    model: Math.min(4,
                        root.previewIcons ? root.previewIcons.length : 0)

                    delegate: Kirigami.Icon {
                        required property int index
                        width: (previewGrid.width - previewGrid.spacing) / 2
                        height: width
                        source: root.previewIcons[index]
                            || "application-x-executable"
                        Accessible.ignored: true
                    }
                }
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: root.effectiveLabel
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 2
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            Accessible.ignored: true
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            root.forceActiveFocus()
            if (mouse.button === Qt.RightButton) {
                root.contextRequested(root, mouse.x, mouse.y)
                return
            }
            root.activated()
        }
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.activated()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Menu
                || (event.key === Qt.Key_F10
                    && (event.modifiers & Qt.ShiftModifier))) {
            root.contextRequested(root, root.width / 2, root.height / 2)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_F2) {
            root.renameRequested()
            event.accepted = true
        }
    }

    Behavior on scale {
        enabled: root.motionEnabled
        NumberAnimation {
            duration: Math.max(90,
                Math.min(140, Kirigami.Units.shortDuration))
            easing.type: Easing.OutCubic
        }
    }
}
// qmllint enable unqualified
