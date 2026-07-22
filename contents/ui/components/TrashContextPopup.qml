import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Plasma injects translation functions into the applet context.
// qmllint disable unqualified
Item {
    id: root

    property string operationState: "idle"
    property int progressPercent: -1
    property bool progressDeterminate: false
    property int processedItems: 0
    property int totalItems: 0
    property string errorMessage: ""
    property int transitionSpeedPercent: 100
    property int menuWidth: 360
    property int menuRowHeight: 46
    property int menuIconSize: 26
    property int maximumAvailableWidth: 752
    property int maximumAvailableHeight: 640
    property bool menuTextShadowsEnabled: true
    property bool confirmationVisible: false
    property real pageTransitionProgress: confirmationVisible ? 1 : 0
    property real surfaceWidth: targetSurfaceWidth
    property real surfaceHeight: targetSurfaceHeight
    readonly property int effectiveRowHeight: Math.max(32, Math.min(64,
        Number(menuRowHeight || 46)))
    readonly property int effectiveIconSize: Math.max(16, Math.min(40,
        Number(menuIconSize || 26)))
    readonly property int pagePadding: Math.max(12,
        Kirigami.Units.largeSpacing * 2)
    readonly property int sectionSpacing: Kirigami.Units.largeSpacing
    readonly property int headerHeight: Math.max(44, effectiveRowHeight)
    readonly property int transitionDuration: Kirigami.Units.longDuration > 1
        ? Math.round(Kirigami.Units.longDuration * 100
            / Math.max(10, Math.min(200, transitionSpeedPercent)))
        : 0
    readonly property real targetSurfaceWidth: Math.max(240,
        Math.min(520, Number(maximumAvailableWidth || 752),
            Math.max(300, Number(menuWidth || 360))))
    readonly property real bodyWidth: Math.max(1,
        targetSurfaceWidth - (pagePadding * 2))
    readonly property real targetBodyHeight: confirmationVisible
        ? confirmationPage.implicitHeight
        : menuPage.implicitHeight
    readonly property real desiredSurfaceHeight: pagePadding + headerHeight
        + sectionSpacing + separator.implicitHeight + sectionSpacing
        + targetBodyHeight + pagePadding
    readonly property real targetSurfaceHeight: Math.max(headerHeight,
        Math.min(Number(maximumAvailableHeight || 640), desiredSurfaceHeight))
    readonly property bool emptying: operationState === "emptying"
    readonly property string headerTitle: confirmationVisible
        ? i18n("Empty Trash")
        : i18n("Trash")

    implicitWidth: surfaceWidth
    implicitHeight: surfaceHeight
    width: implicitWidth
    height: implicitHeight
    clip: true

    signal openTrashRequested()
    signal emptyTrashRequested()
    signal closeRequested()

    function showMenu(focusFirstAction) {
        if (operationState === "emptying") {
            return
        }
        confirmationVisible = false
        if (focusFirstAction === undefined || focusFirstAction) {
            Qt.callLater(menuPage.focusFirstAction)
        } else {
            Qt.callLater(menuPage.clearActionFocus)
        }
    }

    function showConfirmation() {
        confirmationVisible = true
        Qt.callLater(confirmationPage.focusPrimaryAction)
    }

    Behavior on surfaceWidth {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on surfaceHeight {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on pageTransitionProgress {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.InOutCubic
        }
    }

    RowLayout {
        id: header
        x: root.pagePadding
        y: root.pagePadding
        width: root.width - (root.pagePadding * 2)
        height: root.headerHeight
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: root.emptying ? "user-trash-full" : "user-trash"
            color: Kirigami.Theme.textColor
            Layout.preferredWidth: root.effectiveIconSize
            Layout.preferredHeight: root.effectiveIconSize
        }

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 3
            elide: Text.ElideRight
            text: root.headerTitle
        }

        Controls.ToolButton {
            visible: !root.emptying
            enabled: visible
            display: Controls.AbstractButton.IconOnly
            icon.name: "window-close"
            Accessible.name: i18n("Close")
            Controls.ToolTip.visible: hovered || activeFocus
            Controls.ToolTip.text: Accessible.name
            Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
            onClicked: root.closeRequested()
        }
    }

    Kirigami.Separator {
        id: separator
        x: root.pagePadding
        y: header.y + header.height + root.sectionSpacing
        width: root.width - (root.pagePadding * 2)
    }

    Item {
        id: pageViewport
        x: root.pagePadding
        y: separator.y + separator.height + root.sectionSpacing
        width: root.width - (root.pagePadding * 2)
        height: Math.max(0, root.height - y - root.pagePadding)
        clip: true

        Item {
            id: pageStrip
            width: pageViewport.width * 2
            height: pageViewport.height
            x: -pageViewport.width * root.pageTransitionProgress

            TrashMenuPopup {
                id: menuPage
                x: 0
                width: pageViewport.width
                height: pageViewport.height
                enabled: !root.confirmationVisible
                visible: !root.confirmationVisible
                    || pageStrip.x > -pageViewport.width
                rowHeight: root.effectiveRowHeight
                iconSize: root.effectiveIconSize
                textShadowsEnabled: root.menuTextShadowsEnabled

                onOpenTrashClicked: root.openTrashRequested()
                onEmptyTrashClicked: root.showConfirmation()
            }

            ConfirmTrashEmptyPopup {
                id: confirmationPage
                x: pageViewport.width
                width: pageViewport.width
                height: pageViewport.height
                enabled: root.confirmationVisible
                visible: root.confirmationVisible || pageStrip.x < 0
                operationState: root.operationState
                progressPercent: root.progressPercent
                progressDeterminate: root.progressDeterminate
                processedItems: root.processedItems
                totalItems: root.totalItems
                errorMessage: root.errorMessage
                rowHeight: root.effectiveRowHeight
                iconSize: root.effectiveIconSize

                onConfirmRequested: root.emptyTrashRequested()
                onCancelRequested: root.showMenu()
                onDismissRequested: root.closeRequested()
            }
        }
    }
}
// qmllint enable unqualified
