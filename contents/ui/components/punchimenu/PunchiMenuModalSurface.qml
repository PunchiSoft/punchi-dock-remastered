import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

FocusScope {
    id: root

    default property alias contentData: contentHost.data
    property bool active: false
    property bool motionEnabled: true
    property string accessibleName: ""
    property real preferredWidth: Kirigami.Units.gridUnit * 34
    property real preferredHeight: Kirigami.Units.gridUnit * 28
    property real maximumWidth: width - Kirigami.Units.largeSpacing * 2
    property real maximumHeight: height - Kirigami.Units.largeSpacing * 2
    property var allowedExternalFocusItems: []
    readonly property alias contentItem: contentHost

    signal dismissed()
    signal concealed()

    visible: active || opacity > 0.001
    enabled: active
    opacity: active ? 1.0 : 0.0
    activeFocusOnTab: false

    Accessible.role: Accessible.Dialog
    Accessible.name: accessibleName

    function containsFocusItem(item) {
        let candidate = item
        for (let depth = 0; candidate && depth < 128; depth++) {
            if (candidate === root) {
                return true
            }
            candidate = candidate.parent
        }
        return false
    }

    function containsAllowedExternalFocusItem(item) {
        const allowedItems = root.allowedExternalFocusItems || []
        let candidate = item
        for (let depth = 0; candidate && depth < 128; depth++) {
            for (let index = 0; index < allowedItems.length; index++) {
                if (allowedItems[index] && candidate === allowedItems[index]) {
                    return true
                }
            }
            candidate = candidate.parent
        }
        return false
    }

    function acceptsFocusItem(item) {
        return containsFocusItem(item)
            || containsAllowedExternalFocusItem(item)
    }

    function moveFocusWithinSurface(forward) {
        const startItem = root.Window.activeFocusItem || root
        let candidate = startItem
        for (let step = 0; step < 512; step++) {
            candidate = candidate.nextItemInFocusChain(forward)
            if (!candidate || candidate === startItem) {
                break
            }
            if (candidate !== root && root.acceptsFocusItem(candidate)) {
                candidate.forceActiveFocus(forward
                    ? Qt.TabFocusReason : Qt.BacktabFocusReason)
                return true
            }
        }
        root.forceActiveFocus(forward
            ? Qt.TabFocusReason : Qt.BacktabFocusReason)
        return false
    }

    onActiveChanged: {
        if (active) {
            forceActiveFocus()
        }
    }
    onVisibleChanged: {
        if (!visible) {
            concealed()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.64)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onClicked: root.dismissed()
            onWheel: function(wheel) {
                wheel.accepted = true
            }
        }
    }

    Item {
        id: panel
        anchors.centerIn: parent
        width: Math.max(0, Math.min(root.preferredWidth,
            root.maximumWidth))
        height: Math.max(0, Math.min(root.preferredHeight,
            root.maximumHeight))
        scale: root.active ? 1.0 : 0.985

        KSvg.FrameSvgItem {
            id: background
            anchors.fill: parent
            imagePath: "dialogs/background"
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onClicked: function(mouse) {
                mouse.accepted = true
            }
            onWheel: function(wheel) {
                wheel.accepted = true
            }
        }

        Item {
            id: contentHost
            anchors.fill: parent
            anchors.leftMargin: background.margins.left
                + Kirigami.Units.largeSpacing
            anchors.rightMargin: background.margins.right
                + Kirigami.Units.largeSpacing
            anchors.topMargin: background.margins.top
                + Kirigami.Units.largeSpacing
            anchors.bottomMargin: background.margins.bottom
                + Kirigami.Units.largeSpacing
        }

        Behavior on scale {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: Math.max(120,
                    Math.min(200, Kirigami.Units.shortDuration * 2))
                easing.type: root.active ? Easing.OutCubic : Easing.InCubic
            }
        }
    }

    Keys.onEscapePressed: function(event) {
        root.dismissed()
        event.accepted = true
    }
    Keys.priority: Keys.BeforeItem
    Keys.onTabPressed: function(event) {
        root.moveFocusWithinSurface(true)
        event.accepted = true
    }
    Keys.onBacktabPressed: function(event) {
        root.moveFocusWithinSurface(false)
        event.accepted = true
    }

    Connections {
        target: root.Window
        enabled: root.active

        function onActiveFocusItemChanged() {
            const focusedItem = root.Window.activeFocusItem
            if (!root.active || !focusedItem
                    || root.acceptsFocusItem(focusedItem)) {
                return
            }
            Qt.callLater(function() {
                const currentItem = root.Window.activeFocusItem
                if (root.active && (!currentItem
                        || !root.acceptsFocusItem(currentItem))) {
                    root.moveFocusWithinSurface(true)
                }
            })
        }
    }

    Behavior on opacity {
        enabled: root.motionEnabled
        NumberAnimation {
            duration: Math.max(120,
                Math.min(200, Kirigami.Units.shortDuration * 2))
            easing.type: root.active ? Easing.OutCubic : Easing.InCubic
        }
    }
}
