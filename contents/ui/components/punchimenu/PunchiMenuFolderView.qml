import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
FocusScope {
    id: root

    property string folderId: ""
    property string folderLabel: ""
    property var members: []
    property bool motionEnabled: true
    property real iconScale: 1.0
    property int maximumColumnCount: 5
    property int maximumRowCount: 5
    property bool detailedApplicationFeedback: false

    readonly property real effectiveIconScale: Math.max(0.75,
        Math.min(1.5, Number(iconScale || 1.0)))
    readonly property int iconSize: iconMetrics.effectiveSize
    readonly property int targetCellWidth: Math.round(
        Kirigami.Units.gridUnit * 7.5)
    readonly property real gridScrollBarReserve:
        applicationScrollBar.implicitWidth + Kirigami.Units.smallSpacing
    readonly property real availableGridWidth: Math.max(1,
        applicationGrid.width - gridScrollBarReserve)
    readonly property int safeMaximumColumnCount: {
        const requestedCount = Number(maximumColumnCount)
        return Number.isFinite(requestedCount)
            ? Math.max(1, Math.min(5, Math.round(requestedCount)))
            : 5
    }
    readonly property int geometricColumnCapacity: Math.max(1,
        Math.floor(availableGridWidth / targetCellWidth))
    readonly property int columnCount: Math.min(
        safeMaximumColumnCount, geometricColumnCapacity)
    readonly property int effectiveCellWidth: availableGridWidth > 0
        ? Math.floor(availableGridWidth / columnCount)
        : targetCellWidth
    readonly property int maximumApplicationLabelHeight: Math.ceil(
        applicationLabelFontMetrics.height * 2)
    readonly property int cellHeight: Math.ceil(iconSize
        + maximumApplicationLabelHeight
        + Kirigami.Units.smallSpacing * 5)
    readonly property int rowCount: Math.max(1, Math.ceil(
        Math.max(1, (members || []).length) / columnCount))
    readonly property int safeMaximumRowCount: {
        const requestedCount = Number(maximumRowCount)
        return Number.isFinite(requestedCount)
            ? Math.max(1, Math.min(5, Math.round(requestedCount)))
            : 5
    }
    readonly property int visibleRowCount: Math.min(
        safeMaximumRowCount, rowCount)
    readonly property real preferredContentHeight:
        folderHeader.implicitHeight + folderLayout.spacing
        + visibleRowCount * cellHeight
    readonly property string effectiveLabel: folderLabel.length > 0
        ? folderLabel
        : i18nc("@label", "Applications folder")

    PunchiMenuIconMetrics {
        id: iconMetrics
        requestedScale: root.effectiveIconScale
        minimumScale: 0.75
        maximumScale: 1.5
        baseSize: Kirigami.Units.gridUnit * 3.2
        minimumSize: Kirigami.Units.iconSizes.medium
        availableWidth: Math.max(0, root.effectiveCellWidth
            - Kirigami.Units.gridUnit * 2.5)
    }

    FontMetrics {
        id: applicationLabelFontMetrics
        font: Kirigami.Theme.defaultFont
    }

    signal launchRequested(string storageId)
    signal applicationContextRequested(var sourceItem, var application,
        string folderId, real x, real y)
    signal closeRequested()
    signal renameRequested(string folderId)

    function applicationStorageId(application) {
        if (!application) {
            return ""
        }
        return String(application.appStorageId
            || application.storageId || "")
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
        return application.appIcon || application.icon
            || "application-x-executable"
    }

    function focusCurrentItem() {
        if (applicationGrid.count <= 0) {
            closeButton.forceActiveFocus()
            return
        }
        if (applicationGrid.currentIndex < 0) {
            applicationGrid.currentIndex = 0
        }
        applicationGrid.positionViewAtIndex(applicationGrid.currentIndex,
            GridView.Contain)
        if (applicationGrid.currentItem) {
            applicationGrid.currentItem.forceActiveFocus()
        }
    }

    function focusInitial() {
        applicationGrid.currentIndex = applicationGrid.count > 0 ? 0 : -1
        Qt.callLater(focusCurrentItem)
    }

    function focusIndex(index) {
        if (applicationGrid.count <= 0) {
            return
        }
        applicationGrid.currentIndex = Math.max(0,
            Math.min(applicationGrid.count - 1, index))
        Qt.callLater(focusCurrentItem)
    }

    function reset() {
        applicationGrid.currentIndex = -1
        applicationGrid.contentY = 0
    }

    Accessible.role: Accessible.Grouping
    Accessible.name: i18nc("@info:accessible",
        "Contents of the %1 folder", effectiveLabel)

    ColumnLayout {
        id: folderLayout
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            id: folderHeader
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.ToolButton {
                id: closeButton
                icon.name: LayoutMirroring.enabled
                    ? "go-next" : "go-previous"
                text: i18nc("@action:button", "Back")
                display: PlasmaComponents.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: root.closeRequested()

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.effectiveLabel
                textFormat: Text.PlainText
                font.weight: Font.DemiBold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
                elide: Text.ElideRight
                Accessible.role: Accessible.Heading
                Accessible.name: text
            }

            PlasmaComponents.ToolButton {
                id: renameButton
                icon.name: "edit-rename"
                text: i18nc("@action:button", "Rename folder")
                display: PlasmaComponents.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: root.renameRequested(root.folderId)

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }

            PlasmaComponents.ToolButton {
                id: dismissButton
                readonly property bool highlightedContent: enabled
                    && (hovered || down)
                icon.name: "window-close"
                icon.color: highlightedContent
                    ? Kirigami.Theme.highlightedTextColor
                    : Kirigami.Theme.textColor
                text: i18nc("@action:button", "Close")
                display: PlasmaComponents.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: root.closeRequested()

                PlasmaCore.ToolTipArea {
                    id: dismissToolTip
                    anchors.fill: parent
                    active: dismissButton.enabled && dismissButton.visible
                    mainText: dismissButton.text
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                onActiveFocusChanged: {
                    if (activeFocus) {
                        dismissToolTip.showToolTip()
                    } else if (!dismissToolTip.containsMouse) {
                        dismissToolTip.hideImmediately()
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: applicationGrid
                anchors.fill: parent
                model: root.members || []
                cellWidth: root.effectiveCellWidth
                cellHeight: root.cellHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: -1
                keyNavigationEnabled: false
                activeFocusOnTab: false

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    id: applicationScrollBar
                    policy: applicationGrid.contentHeight
                        > applicationGrid.height
                            ? Controls.ScrollBar.AsNeeded
                            : Controls.ScrollBar.AlwaysOff
                }

                delegate: FocusScope {
                    id: applicationDelegate

                    required property int index
                    required property var modelData

                    readonly property bool isHiddenApplication: Boolean(
                        modelData && modelData.appHidden)
                    readonly property bool highlighted: activeFocus
                        || appPointer.containsMouse
                    readonly property bool outlined: activeFocus
                        || (root.detailedApplicationFeedback
                            && appPointer.containsMouse)

                    width: applicationGrid.cellWidth
                    height: applicationGrid.cellHeight
                    activeFocusOnTab: true
                    opacity: isHiddenApplication ? 0.58 : 1.0

                    Accessible.role: Accessible.Button
                    Accessible.name: root.applicationName(modelData)
                    Accessible.description: isHiddenApplication
                        ? i18nc("@info:accessibility",
                            "Hidden from the application listing")
                        : i18nc("@info:accessible",
                            "Launch this application")
                    Accessible.onPressAction: launchApplication()

                    function launchApplication() {
                        const storageId = root.applicationStorageId(modelData)
                        if (storageId.length > 0) {
                            root.launchRequested(storageId)
                        }
                    }

                    PunchiMenuItemHighlight {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        hovered: appPointer.containsMouse
                        selected: applicationDelegate.outlined
                        focused: applicationDelegate.activeFocus
                        pressed: appPointer.pressed
                        motionEnabled: root.motionEnabled
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing * 2
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: root.iconSize
                            Layout.preferredHeight: root.iconSize
                            Layout.alignment: Qt.AlignHCenter
                            source: root.applicationIcon(
                                applicationDelegate.modelData)
                            Accessible.ignored: true
                        }

                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: root.applicationName(
                                applicationDelegate.modelData)
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignHCenter
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            font: applicationLabelFontMetrics.font
                            Accessible.ignored: true
                        }
                    }

                    Kirigami.Icon {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: Kirigami.Units.smallSpacing * 2
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        source: "view-hidden-symbolic"
                        visible: root.detailedApplicationFeedback
                            && applicationDelegate.isHiddenApplication
                        Accessible.ignored: true
                    }

                    MouseArea {
                        id: appPointer
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: function(mouse) {
                            applicationGrid.currentIndex
                                = applicationDelegate.index
                            applicationDelegate.forceActiveFocus()
                            if (mouse.button === Qt.RightButton) {
                                root.applicationContextRequested(
                                    applicationDelegate,
                                    applicationDelegate.modelData,
                                    root.folderId,
                                    mouse.x,
                                    mouse.y)
                                return
                            }
                            applicationDelegate.launchApplication()
                        }
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return
                                || event.key === Qt.Key_Enter
                                || event.key === Qt.Key_Space) {
                            applicationDelegate.launchApplication()
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_Menu
                                || (event.key === Qt.Key_F10
                                    && (event.modifiers
                                        & Qt.ShiftModifier))) {
                            root.applicationContextRequested(
                                applicationDelegate,
                                applicationDelegate.modelData,
                                root.folderId,
                                applicationDelegate.width / 2,
                                applicationDelegate.height / 2)
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_F2) {
                            root.renameRequested(root.folderId)
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_Left) {
                            root.focusIndex(applicationDelegate.index - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Right) {
                            root.focusIndex(applicationDelegate.index + 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            root.focusIndex(applicationDelegate.index
                                - root.columnCount)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            root.focusIndex(applicationDelegate.index
                                + root.columnCount)
                            event.accepted = true
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width,
                    Kirigami.Units.gridUnit * 20)
                visible: applicationGrid.count === 0
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                    Layout.preferredHeight: width
                    Layout.alignment: Qt.AlignHCenter
                    source: "folder-open"
                    opacity: 0.72
                    Accessible.ignored: true
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: i18nc("@info", "This folder is empty")
                    textFormat: Text.PlainText
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    Keys.onEscapePressed: function(event) {
        root.closeRequested()
        event.accepted = true
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_F2) {
            root.renameRequested(root.folderId)
            event.accepted = true
        }
    }
}
// qmllint enable unqualified
