import QtQuick
import QtQuick.Layouts
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

Item {
    id: root

    property int rowHeight: 46
    property int iconSize: 26
    property bool textShadowsEnabled: false
    property bool canEmptyTrash: false
    readonly property int effectiveRowHeight: Math.max(32, Math.min(64,
        Number(rowHeight || 46)))
    readonly property int effectiveIconSize: Math.max(16, Math.min(40,
        Number(iconSize || 26)))
    // Matches the app context menu: the selection hugs the row bounds while
    // the row padding still follows the theme for the content.
    readonly property int actionHighlightInset: Math.max(1,
        Math.round(Kirigami.Units.smallSpacing / 2))

    // Natural width of the widest action row, measured with the same font and
    // padding the rows use. TrashContextPopup consumes it only in automatic
    // mode; manual mode keeps the configured target width.
    readonly property real naturalWidth: {
        const padding = menuItemPaddingMetrics.margins.left
            + menuItemPaddingMetrics.margins.right
        const labelWidth = Math.max(openLabelMetrics.advanceWidth,
            emptyLabelMetrics.advanceWidth)
        return Math.ceil(Kirigami.Units.smallSpacing * 2
            + root.effectiveIconSize + labelWidth + padding)
    }
    implicitWidth: naturalWidth
    implicitHeight: actionColumn.implicitHeight

    TextMetrics {
        id: openLabelMetrics
        font: Kirigami.Theme.defaultFont
        text: openOption.text
    }

    TextMetrics {
        id: emptyLabelMetrics
        font: Kirigami.Theme.defaultFont
        text: emptyOption.text
    }

    signal openTrashClicked()
    signal emptyTrashClicked()

    function focusFirstAction() {
        openOption.forceActiveFocus(Qt.TabFocusReason)
    }

    function clearActionFocus() {
        root.forceActiveFocus(Qt.MouseFocusReason)
    }

    ColumnLayout {
        id: actionColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.MenuItem {
            id: openOption
            Layout.fillWidth: true
            Layout.preferredHeight: root.effectiveRowHeight
            text: i18n("Open trash") // qmllint disable unqualified
            icon.name: "folder-open"
            icon.width: root.effectiveIconSize
            icon.height: root.effectiveIconSize
            Accessible.description: i18n("Open the trash folder in the file manager") // qmllint disable unqualified
            leftPadding: menuItemPaddingMetrics.margins.left
            rightPadding: menuItemPaddingMetrics.margins.right
            topPadding: menuItemPaddingMetrics.margins.top
            bottomPadding: menuItemPaddingMetrics.margins.bottom
            onClicked: root.openTrashClicked()

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.preferredWidth: Kirigami.Units.smallSpacing
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }

                Kirigami.Icon {
                    Layout.preferredWidth: root.effectiveIconSize
                    Layout.preferredHeight: root.effectiveIconSize
                    source: openOption.icon.name
                }

                PlasmaExtras.ShadowedLabel {
                    Layout.fillWidth: true
                    text: openOption.text
                    color: Kirigami.Theme.textColor
                    renderShadow: root.textShadowsEnabled
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
            }

            background: Item {
                InteractiveActionBackground {
                    anchors.fill: parent
                    anchors.margins: root.actionHighlightInset
                    hovered: openOption.hovered
                    focused: openOption.visualFocus
                    pressed: openOption.down
                }
            }
        }

        PlasmaComponents.MenuItem {
            id: emptyOption
            Layout.fillWidth: true
            Layout.preferredHeight: root.effectiveRowHeight
            text: i18n("Empty trash") // qmllint disable unqualified
            enabled: root.canEmptyTrash
            opacity: emptyOption.enabled ? 1.0 : 0.5
            icon.name: "edit-delete"
            icon.width: root.effectiveIconSize
            icon.height: root.effectiveIconSize
            icon.color: Kirigami.Theme.negativeTextColor
            Accessible.description: i18n("Permanently remove all items from the trash") // qmllint disable unqualified
            leftPadding: menuItemPaddingMetrics.margins.left
            rightPadding: menuItemPaddingMetrics.margins.right
            topPadding: menuItemPaddingMetrics.margins.top
            bottomPadding: menuItemPaddingMetrics.margins.bottom
            onClicked: root.emptyTrashClicked()

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.preferredWidth: Kirigami.Units.smallSpacing
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }

                Kirigami.Icon {
                    Layout.preferredWidth: root.effectiveIconSize
                    Layout.preferredHeight: root.effectiveIconSize
                    source: emptyOption.icon.name
                    color: Kirigami.Theme.negativeTextColor
                }

                PlasmaExtras.ShadowedLabel {
                    Layout.fillWidth: true
                    text: emptyOption.text
                    color: Kirigami.Theme.textColor
                    renderShadow: root.textShadowsEnabled
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
            }

            background: Item {
                InteractiveActionBackground {
                    anchors.fill: parent
                    anchors.margins: root.actionHighlightInset
                    hovered: emptyOption.hovered
                    focused: emptyOption.visualFocus
                    pressed: emptyOption.down
                }
            }
        }
    }

    KSvg.FrameSvgItem {
        id: menuItemPaddingMetrics
        imagePath: "widgets/viewitem"
        prefix: "hover"
        width: 0
        height: 0
        visible: false
        Accessible.ignored: true
    }
}
