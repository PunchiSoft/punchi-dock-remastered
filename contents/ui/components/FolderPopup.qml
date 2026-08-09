import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: folderRoot
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    implicitWidth: layoutMode === "grid"
        ? Math.min(desiredGridWidth + scrollBarGutter, safeMaximumWidth)
        : Math.min(Math.round(280 * effectiveScale), safeMaximumWidth)
    implicitHeight: classicPopupHeight
    width: implicitWidth
    height: implicitHeight

    // Properties injected by the main UI.
    property var folderItem: ({})
    property string layoutMode: "grid"
    property int profileIconSize: layoutMode === "grid" ? 36 : 32
    property int profileColumns: 3
    property int profileRows: 4
    property bool profileShowLabels: true
    property string profileFontFamily: ""
    property int profileFontSize: layoutMode === "grid" ? 9 : 10
    property real profileScale: 1.0
    property bool showHeaderLabel: true
    property bool textShadowsEnabled: false
    property int maximumAvailableWidth: 752
    property int maximumAvailableHeight: 640

    // Quick access entries.
    property var apps: folderItem.apps || []
    property int itemCount: apps.length
    readonly property real effectiveScale: Math.max(0.5, Math.min(3.0,
        Number(profileScale || 1.0)))
    readonly property int classicMargin: Math.round(12 * effectiveScale)
    readonly property int classicSpacing: Math.round(8 * effectiveScale)
    readonly property int effectiveIconSize: Math.max(16, Math.min(192,
        Math.round(Number(profileIconSize || (layoutMode === "grid" ? 36 : 32)) * effectiveScale)))
    readonly property int configuredColumnCount: Math.max(1, Math.min(8,
        Number(profileColumns || 3)))
    readonly property int configuredRowLimit: Math.max(1, Math.min(8,
        Number(profileRows || 4)))
    readonly property bool showItemLabels: profileShowLabels
    readonly property string effectiveFontFamily:
        String(profileFontFamily || "").length > 0
            ? String(profileFontFamily)
            : (layoutMode === "grid"
                ? Kirigami.Theme.smallFont.family
                : Kirigami.Theme.defaultFont.family)
    readonly property int effectiveFontSize: Math.max(6, Math.min(36,
        Math.round(Number(profileFontSize || (layoutMode === "grid" ? 9 : 10)) * effectiveScale)))
    readonly property int gridCellWidth: showItemLabels
        ? Math.max(Math.round(80 * effectiveScale), effectiveIconSize + Math.round(24 * effectiveScale))
        : effectiveIconSize + Math.round(16 * effectiveScale)
    readonly property int classicCellHeight: !showItemLabels
        ? effectiveIconSize + Math.round(8 * effectiveScale)
        : (layoutMode === "detailed"
            ? Math.max(Math.round(56 * effectiveScale), effectiveIconSize + effectiveFontSize + Math.round(8 * effectiveScale))
            : (layoutMode === "list"
                ? Math.max(Math.round(40 * effectiveScale), effectiveIconSize + Math.round(8 * effectiveScale))
                : effectiveIconSize + effectiveFontSize + Math.round(24 * effectiveScale)))
    readonly property int desiredGridWidth: classicMargin * 2
        + configuredColumnCount * gridCellWidth
    readonly property int safeMaximumWidth: Math.max(
        classicMargin * 2 + gridCellWidth,
        Number(maximumAvailableWidth || 752))
    readonly property int gridColumnsWithoutScrollBar: Math.max(1,
        Math.min(configuredColumnCount, Math.floor(
            (Math.min(desiredGridWidth, safeMaximumWidth)
                - classicMargin * 2) / gridCellWidth)))
    readonly property bool scrollRequired: layoutMode === "grid"
        ? itemCount > configuredRowLimit * gridColumnsWithoutScrollBar
        : itemCount > configuredRowLimit
    readonly property int scrollBarGutter: scrollRequired
        ? Math.ceil(verticalScrollBar.implicitWidth)
            + Kirigami.Units.smallSpacing
        : 0
    readonly property int classicContentWidth: implicitWidth
        - classicMargin * 2 - scrollBarGutter
    readonly property int gridColumnCount: layoutMode === "grid"
        ? Math.max(1, Math.min(configuredColumnCount,
            Math.floor(classicContentWidth / gridCellWidth)))
        : 1
    readonly property int classicRowCount: layoutMode === "grid"
        ? Math.ceil(itemCount / gridColumnCount)
        : itemCount
    readonly property int visibleClassicRows: Math.max(1,
        Math.min(classicRowCount, configuredRowLimit))
    readonly property int headerHeightEffect: showHeaderLabel ? (classicHeader.implicitHeight + classicSpacing) : 0
    readonly property int classicChromeHeight: classicMargin * 2 + headerHeightEffect
    readonly property int classicNaturalHeight: classicChromeHeight + visibleClassicRows * classicCellHeight
    readonly property int configuredMaximumHeight: Math.max(0, Number(folderItem.popupMaxHeight || 0))
    readonly property int effectiveMaximumHeight: configuredMaximumHeight > 0
        ? Math.min(maximumAvailableHeight, Math.max(classicChromeHeight + classicCellHeight, configuredMaximumHeight))
        : maximumAvailableHeight
    readonly property int classicPopupHeight: Math.min(classicNaturalHeight, effectiveMaximumHeight)

    // Signals for launching applications and closing the popup.
    signal appLaunched(var app)
    signal appContextMenuRequested(var app)
    signal closeRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: folderRoot.classicMargin
        spacing: folderRoot.classicSpacing

        // Folder title.
        RowLayout {
            id: classicHeader
            visible: folderRoot.showHeaderLabel
            Layout.fillWidth: true
            PlasmaExtras.ShadowedLabel {
                text: folderRoot.folderItem.name || i18n("Folder")
                color: Kirigami.Theme.textColor
                renderShadow: folderRoot.textShadowsEnabled
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Math.max(8, Math.min(36, Math.round(Kirigami.Theme.defaultFont.pointSize * folderRoot.effectiveScale)))
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            // Close button.
            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 10
                color: closeMouse.containsMouse || closeMouse.activeFocus ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.backgroundColor
                PlasmaComponents.Label { text: "×"; anchors.centerIn: parent; color: Kirigami.Theme.textColor }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent; hoverEnabled: true
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: i18n("Close")
                    onClicked: folderRoot.closeRequested()
                    Keys.onReturnPressed: folderRoot.closeRequested()
                    Keys.onSpacePressed: folderRoot.closeRequested()
                }
            }
        }

        // Grid or list view.
        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Keep cellWidth from producing scrollbars or horizontal clipping.
            cellWidth: folderRoot.layoutMode === "list"
                || folderRoot.layoutMode === "detailed"
                ? gridView.width - folderRoot.scrollBarGutter
                : folderRoot.gridCellWidth
            cellHeight: folderRoot.classicCellHeight
            model: folderRoot.apps
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                id: verticalScrollBar
                policy: folderRoot.scrollRequired
                    ? Controls.ScrollBar.AsNeeded
                    : Controls.ScrollBar.AlwaysOff
            }

            delegate: Item {
                width: gridView.cellWidth
                height: gridView.cellHeight

                // Interactive background.
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 8
                    color: itemMouse.containsMouse || itemMouse.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    opacity: itemMouse.containsMouse || itemMouse.activeFocus ? 0.2 : 1
                    border.width: itemMouse.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.highlightColor
                }

                // List and detail modes place the icon before the label.
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: folderRoot.layoutMode === "list"
                        || folderRoot.layoutMode === "detailed"
                    spacing: 8

                    Kirigami.Icon {
                        Layout.preferredWidth: folderRoot.effectiveIconSize
                        Layout.preferredHeight: folderRoot.effectiveIconSize
                        source: modelData.icon || "application-x-executable"
                    }
                    Column {
                        Layout.fillWidth: true
                        visible: folderRoot.showItemLabels
                        PlasmaExtras.ShadowedLabel {
                            text: modelData.name
                            color: Kirigami.Theme.textColor
                            renderShadow: folderRoot.textShadowsEnabled
                            font.family: folderRoot.effectiveFontFamily
                            font.pointSize: folderRoot.effectiveFontSize
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        PlasmaComponents.Label {
                            text: modelData.command || ""
                            font.family: folderRoot.effectiveFontFamily
                            font.pointSize: Math.max(8, folderRoot.effectiveFontSize - 1)
                            color: Kirigami.Theme.textColor
                            opacity: 0.6
                            elide: Text.ElideRight
                            width: parent.width
                            visible: folderRoot.layoutMode === "detailed"
                        }
                    }
                }

                // Standard grid mode places the icon above the label.
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: folderRoot.layoutMode === "grid"
                    spacing: folderRoot.showItemLabels ? 4 : 0

                    Kirigami.Icon {
                        Layout.preferredWidth: folderRoot.effectiveIconSize
                        Layout.preferredHeight: folderRoot.effectiveIconSize
                        Layout.alignment: Qt.AlignCenter
                        source: modelData.icon || "application-x-executable"
                    }
                    PlasmaExtras.ShadowedLabel {
                        visible: folderRoot.showItemLabels
                        text: modelData.name
                        color: Kirigami.Theme.textColor
                        renderShadow: folderRoot.textShadowsEnabled
                        font.family: folderRoot.effectiveFontFamily
                        font.pointSize: folderRoot.effectiveFontSize
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.name || i18n("Application")
                    // The delegate model and owning popup are provided by the
                    // GridView context and resolve correctly at runtime.
                    // qmllint disable unqualified
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            folderRoot.appContextMenuRequested(modelData)
                            return
                        }
                        folderRoot.appLaunched(modelData)
                    }
                    Keys.onReturnPressed: folderRoot.appLaunched(modelData)
                    Keys.onSpacePressed: folderRoot.appLaunched(modelData)
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Menu
                                || (event.key === Qt.Key_F10
                                    && (event.modifiers & Qt.ShiftModifier))) {
                            folderRoot.appContextMenuRequested(modelData)
                            event.accepted = true
                        }
                    }
                    // qmllint enable unqualified
                }
            }
        }
    }

}
