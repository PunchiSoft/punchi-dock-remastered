import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Internal visual transport for PunchiMenu layout nodes. It intentionally
// carries no MIME data or URLs; drop targets validate the source object.
Item {
    id: root

    property bool active: false
    property bool folder: false
    property string nodeId: ""
    property string storageId: ""
    property string label: ""
    property string iconName: "application-x-executable"
    property point pointerPosition: Qt.point(0, 0)
    property size sourceSize: Qt.size(1, 1)
    property bool motionEnabled: true

    readonly property alias dragSource: dragProxy
    readonly property string dragKey: "punchi-internal-layout-node"

    function begin(payload, position, size) {
        if (active || !payload || String(payload.nodeId || "").length === 0) {
            return false
        }
        folder = String(payload.nodeType || "") === "folder"
        nodeId = String(payload.nodeId || "")
        storageId = folder ? "" : String(payload.appStorageId || "")
        label = folder ? String(payload.folderLabel || "")
            : String(payload.appName || "")
        iconName = folder ? "folder"
            : String(payload.appIcon || "application-x-executable")
        sourceSize = Qt.size(Math.max(1, Number(size.width || 1)),
            Math.max(1, Number(size.height || 1)))
        pointerPosition = position
        active = true
        return true
    }

    function move(position) {
        if (active) {
            pointerPosition = position
        }
    }

    function drop() {
        if (!active) {
            return Qt.IgnoreAction
        }
        const action = dragProxy.Drag.drop()
        reset()
        return action
    }

    function cancel() {
        if (!active) {
            return
        }
        dragProxy.Drag.cancel()
        reset()
    }

    function reset() {
        active = false
        folder = false
        nodeId = ""
        storageId = ""
        label = ""
        iconName = "application-x-executable"
    }

    visible: active

    Item {
        id: dragProxy

        x: root.pointerPosition.x - width / 2
        y: root.pointerPosition.y - height / 2
        width: Math.max(Kirigami.Units.gridUnit * 5,
            Math.min(root.sourceSize.width, Kirigami.Units.gridUnit * 8))
        height: Math.max(Kirigami.Units.gridUnit * 5,
            Math.min(root.sourceSize.height, Kirigami.Units.gridUnit * 8))
        opacity: root.active ? 0.94 : 0.0
        scale: root.active && root.motionEnabled ? 1.04 : 1.0

        Drag.active: root.active
        Drag.source: dragProxy
        Drag.keys: [root.dragKey]
        Drag.supportedActions: Qt.MoveAction
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.cornerRadius * 2
            color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.96)
            border.width: 2
            border.color: Kirigami.Theme.highlightColor
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(parent.width,
                    Kirigami.Units.iconSizes.large)
                Layout.preferredHeight: Layout.preferredWidth
                source: root.iconName
                Accessible.ignored: true
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.label
                textFormat: Text.PlainText
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 2
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                font: Kirigami.Theme.smallFont
                Accessible.ignored: true
            }
        }

        Behavior on scale {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
