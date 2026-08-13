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
    property string hoverAnimation: "pulse"
    property real requestedIconSize: Kirigami.Units.iconSizes.huge
    readonly property alias hovered: pointer.containsMouse

    readonly property int previewSize: iconMetrics.effectiveSize
    readonly property int previewInset: Math.max(Kirigami.Units.smallSpacing,
        Math.round(previewSize * 0.18))
    readonly property string effectiveLabel: folderLabel.length > 0
        ? folderLabel
        : i18nc("@label", "Applications folder")
    readonly property string memberSummary: i18np("%1 application",
        "%1 applications", Math.max(0, memberCount))

    signal activated()
    signal contextRequested(var sourceItem, real x, real y)
    signal renameRequested()

    implicitWidth: Math.max(Kirigami.Units.gridUnit * 5.5,
        requestedIconSize + Kirigami.Units.largeSpacing * 2)
    implicitHeight: requestedIconSize + Kirigami.Units.gridUnit * 2.8
    activeFocusOnTab: true
    scale: root.motionEnabled && pointer.pressed
        && root.hoverAnimation !== "none"
        ? 0.97 : itemHighlight.visualScale

    Accessible.role: Accessible.Button
    Accessible.name: i18nc("@info:accessible", "%1, %2",
        effectiveLabel, memberSummary)
    Accessible.description: i18nc("@info:accessible",
        "Open this application folder")
    Accessible.focused: selected || activeFocus
    Accessible.onPressAction: root.activated()

    PunchiMenuIconMetrics {
        id: iconMetrics
        requestedScale: 1.0
        minimumScale: 1.0
        maximumScale: 1.0
        baseSize: root.requestedIconSize
        minimumSize: Kirigami.Units.iconSizes.medium
        availableWidth: root.width > 0
            ? root.width - Kirigami.Units.largeSpacing * 2 : -1
        availableHeight: root.height > 0
            ? root.height - Kirigami.Units.gridUnit * 2.8 : -1
    }

    PunchiMenuItemHighlight {
        id: itemHighlight
        anchors.fill: parent
        hovered: pointer.containsMouse
        selected: root.selected
        focused: root.activeFocus
        pressed: pointer.pressed
        motionEnabled: root.motionEnabled
        animationMode: root.hoverAnimation
        transformSelf: false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Item {
            Layout.preferredWidth: root.previewSize
            Layout.preferredHeight: root.previewSize
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                id: folderPlaque
                anchors.fill: parent
                radius: Kirigami.Units.cornerRadius * 2
                color: Kirigami.Theme.alternateBackgroundColor
                border.width: 1
                border.color: Qt.alpha(Kirigami.Theme.textColor,
                    Kirigami.Theme.lightFrameContrast)
                Accessible.ignored: true
            }

            Grid {
                id: previewGrid
                anchors.fill: parent
                anchors.margins: root.previewInset
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

}
// qmllint enable unqualified
