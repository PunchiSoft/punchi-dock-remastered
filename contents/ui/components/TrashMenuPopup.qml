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

    implicitWidth: 300
    implicitHeight: actionColumn.implicitHeight

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
                    anchors.leftMargin: openOption.leftPadding
                    anchors.rightMargin: openOption.rightPadding
                    anchors.topMargin: openOption.topPadding
                    anchors.bottomMargin: openOption.bottomPadding
                    hovered: openOption.hovered
                    focused: openOption.visualFocus
                    pressed: openOption.down
                    visualRadius: height / 2
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
                    anchors.leftMargin: emptyOption.leftPadding
                    anchors.rightMargin: emptyOption.rightPadding
                    anchors.topMargin: emptyOption.topPadding
                    anchors.bottomMargin: emptyOption.bottomPadding
                    hovered: emptyOption.hovered
                    focused: emptyOption.visualFocus
                    pressed: emptyOption.down
                    visualRadius: height / 2
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
