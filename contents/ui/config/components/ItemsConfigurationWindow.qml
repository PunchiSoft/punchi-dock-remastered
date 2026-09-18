// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore

// Translation helpers are supplied by the plasmoid configuration context.
// qmllint disable unqualified
PlasmaCore.Dialog {
    id: root

    objectName: "itemsConfigurationWindow"

    property var ownerWindow: null
    property string sourceJson: ""
    property bool surfaceOpen: false
    property bool committing: false
    property string commitErrorCode: ""
    property string conflictingRaw: ""
    property bool motionEnabled: Kirigami.Units.longDuration > 0
    property int openDuration: motionEnabled
        ? Math.max(160, Math.min(240, Kirigami.Units.longDuration)) : 1
    property int closeDuration: motionEnabled
        ? Math.max(120, Math.min(180, Kirigami.Units.shortDuration * 2)) : 1
    readonly property real availableWidth:
        Math.max(1, Number(Screen.desktopAvailableWidth || Screen.width || 1))
    readonly property real availableHeight:
        Math.max(1, Number(Screen.desktopAvailableHeight || Screen.height || 1))
    readonly property real screenOriginX:
        Number.isFinite(Number(Screen.virtualX)) ? Number(Screen.virtualX) : 0
    readonly property real screenOriginY:
        Number.isFinite(Number(Screen.virtualY)) ? Number(Screen.virtualY) : 0
    readonly property real screenMargin: Kirigami.Units.gridUnit * 2
    // Inner padding between the themed frame and the content. The tested theme
    // publishes a small inset for solid/dialogs/background, so the surface adds
    // a theme-derived grid margin on top of the frame margins instead of
    // relying on them alone.
    readonly property real contentMargin:
        Math.round(Kirigami.Units.gridUnit * 1.5)
    readonly property real preferredContentWidth:
        Math.round(availableWidth * 0.68)
    readonly property real minimumContentWidth: Kirigami.Units.gridUnit * 42
    readonly property real minimumContentHeight: Kirigami.Units.gridUnit * 12
    readonly property real maximumContentHeight:
        Math.max(1, availableHeight - screenMargin * 2)
    readonly property real desiredContentWidth: Math.max(1,
        Math.min(Math.max(minimumContentWidth, preferredContentWidth),
            Math.max(1, availableWidth - screenMargin * 2)))
    // The surface grows with its own content: the themed frame inset, the inner
    // padding and the header, body and footer declared by the surface. The
    // screen only limits the maximum, never inflates the window.
    readonly property real desiredContentHeight: Math.max(1,
        Math.min(Math.max(minimumContentHeight,
            configurationSurface.contentImplicitHeight),
        maximumContentHeight))
    readonly property bool hasPendingChanges: draftController.dirty
    readonly property var draftItems: draftController.draftItems
    readonly property bool selectedItemRemovable:
        draftController.selectedItemRemovable
    readonly property var catalogEntries: catalogSource.entries

    signal concealed()
    signal commitRequested(string expectedRaw, string nextRaw,
        bool closeAfterCommit)

    title: i18nc("@title:window", "Punchi Dock Items Configuration")
    transientParent: ownerWindow
    visualParent: null
    location: PlasmaCore.Types.Floating
    type: PlasmaCore.Dialog.Normal
    flags: Qt.Dialog | Qt.FramelessWindowHint
    backgroundHints: PlasmaCore.Dialog.NoBackground
    hideOnWindowDeactivate: false
    visible: false

    function positionAtScreenCenter() {
        x = Math.round(screenOriginX + (availableWidth - width) / 2)
        y = Math.round(screenOriginY + (availableHeight - height) / 2)
    }

    function finishOpening() {
        if (!visible || closeTimer.running) {
            return
        }
        positionAtScreenCenter()
        surfaceOpen = true
        requestActivate()
        Qt.callLater(function() {
            if (root.visible) {
                configurationSurface.forceActiveFocus(Qt.PopupFocusReason)
                if (!workspace.focusInitialControl(Qt.PopupFocusReason)) {
                    closeButton.forceActiveFocus(Qt.PopupFocusReason)
                }
            }
        })
    }

    function openWithReveal() {
        closeTimer.stop()
        committing = false
        commitErrorCode = ""
        conflictingRaw = ""
        draftController.load(sourceJson)
        surfaceOpen = false
        positionAtScreenCenter()
        visible = true
        Qt.callLater(finishOpening)
    }

    function cancelDraft() {
        if (committing) {
            return
        }
        closeWithFade()
    }

    function addDraftItem(type, insertionIndex) {
        if (draftController.addItem(type, insertionIndex)) {
            commitErrorCode = ""
            return true
        }
        commitErrorCode = draftController.errorCode
        return false
    }

    function removeDraftItem(index) {
        if (draftController.removeItem(index)) {
            commitErrorCode = ""
            return true
        }
        commitErrorCode = draftController.errorCode
        return false
    }

    function moveDraftItem(index, targetIndex) {
        return draftController.moveItem(index, targetIndex)
    }

    function moveDraftItemToInsertion(index, insertionIndex) {
        return draftController.moveItemToInsertion(index, insertionIndex)
    }

    function requestCommit(closeAfterCommit) {
        if (committing || !draftController.loaded) {
            return
        }
        if (!draftController.dirty) {
            if (closeAfterCommit) {
                closeWithFade()
            }
            return
        }
        committing = true
        commitErrorCode = ""
        conflictingRaw = ""
        commitRequested(draftController.expectedRaw,
            draftController.serializedDraft(), closeAfterCommit)
    }

    function confirmCommit(committedRaw, closeAfterCommit) {
        committing = false
        commitErrorCode = ""
        conflictingRaw = ""
        draftController.confirmCommitted(committedRaw)
        if (closeAfterCommit) {
            closeWithFade()
        }
    }

    function rejectCommit(errorCode, currentRaw) {
        committing = false
        commitErrorCode = String(errorCode || "persistence-failed")
        conflictingRaw = String(currentRaw || "")
    }

    function errorMessage() {
        if (commitErrorCode === "" && draftController.errorCode === "") {
            return ""
        }
        const code = commitErrorCode || draftController.errorCode
        if (code === "conflict") {
            return i18nc("@info", "The dock configuration changed elsewhere. Close and reopen this window before applying again.")
        }
        if (code === "array" || code === "invalid-json") {
            return i18nc("@info", "The existing dock configuration could not be read. No changes were made.")
        }
        if (code === "maximum-item-count") {
            return i18nc("@info", "The dock has reached the maximum number of supported elements.")
        }
        if (code === "requires-legacy-editor") {
            return i18nc("@info", "Open applications must still be removed from the existing Items page during this development phase.")
        }
        if (code === "duplicate-singleton-item") {
            return i18nc("@info", "The dock supports only one element of this type.")
        }
        return i18nc("@info", "The dock configuration could not be saved. No existing changes were overwritten.")
    }

    function closeWithFade() {
        if (!visible || closeTimer.running) {
            return
        }
        surfaceOpen = false
        closeTimer.restart()
    }

    function closeImmediately() {
        closeTimer.stop()
        committing = false
        surfaceOpen = false
        visible = false
    }

    onWidthChanged: {
        if (visible) {
            positionAtScreenCenter()
        }
    }
    onHeightChanged: {
        if (visible) {
            positionAtScreenCenter()
        }
    }
    onVisibleChanged: {
        if (!visible) {
            closeTimer.stop()
            surfaceOpen = false
            concealed()
        }
    }

    readonly property Timer closeTimer: Timer {
        id: closeTimer

        interval: root.closeDuration
        repeat: false
        onTriggered: root.closeImmediately()
    }

    readonly property ItemsConfigurationDraftController draftController:
        ItemsConfigurationDraftController {
        objectName: "itemsConfigurationDraftController"
    }

    readonly property ItemsConfigurationCatalog catalogSource:
        ItemsConfigurationCatalog {
        objectName: "itemsConfigurationCatalogSource"
    }

    mainItem: FocusScope {
        id: configurationSurface

        objectName: "itemsConfigurationSurface"
        width: root.desiredContentWidth
        height: root.desiredContentHeight
        implicitWidth: root.desiredContentWidth
        implicitHeight: root.desiredContentHeight
        // Reported to the dialog so the height follows the content, including
        // the themed frame inset and the inner padding around the column.
        readonly property real contentChromeHeight:
            opaqueBackground.margins.top + opaqueBackground.margins.bottom
            + root.contentMargin * 2
        readonly property real contentImplicitHeight:
            contentColumn.implicitHeight + contentChromeHeight
        // Inner width available to the content column, excluding the themed
        // frame margins and the surface padding.
        readonly property real contentImplicitWidth:
            width - opaqueBackground.margins.left
            - opaqueBackground.margins.right - root.contentMargin * 2
        opacity: root.surfaceOpen ? 1.0 : 0.0
        scale: root.motionEnabled
            ? (root.surfaceOpen ? 1.0 : 0.96) : 1.0
        transformOrigin: Item.Center
        Accessible.role: Accessible.Dialog
        Accessible.name: root.title
        Keys.priority: Keys.BeforeItem
        Keys.onEscapePressed: function(event) {
            root.cancelDraft()
            event.accepted = true
        }

        Behavior on opacity {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: root.surfaceOpen
                    ? root.openDuration : root.closeDuration
                easing.type: root.surfaceOpen
                    ? Easing.OutCubic : Easing.InCubic
            }
        }

        Behavior on scale {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: root.surfaceOpen
                    ? root.openDuration : root.closeDuration
                easing.type: root.surfaceOpen
                    ? Easing.OutCubic : Easing.InCubic
            }
        }

        KSvg.FrameSvgItem {
            id: opaqueBackground

            objectName: "itemsConfigurationOpaqueBackground"
            anchors.fill: parent
            imagePath: "solid/dialogs/background"
            opacity: 1.0
            Accessible.ignored: true
        }

        ColumnLayout {
            id: contentColumn

            anchors.fill: parent
            anchors.leftMargin: opaqueBackground.margins.left
                + root.contentMargin
            anchors.topMargin: opaqueBackground.margins.top
                + root.contentMargin
            anchors.rightMargin: opaqueBackground.margins.right
                + root.contentMargin
            anchors.bottomMargin: opaqueBackground.margins.bottom
                + root.contentMargin
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.mediumSpacing

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 1
                    text: root.title
                    elide: Text.ElideRight
                    Accessible.role: Accessible.Heading
                }

                Controls.ToolButton {
                    id: closeButton

                    objectName: "itemsConfigurationCloseButton"
                    text: i18nc("@action:button", "Close")
                    icon.name: "window-close"
                    display: Controls.AbstractButton.IconOnly
                    Accessible.name: text
                    onClicked: root.cancelDraft()

                    PlasmaCore.ToolTipArea {
                        objectName: "itemsConfigurationCloseToolTip"
                        anchors.fill: parent
                        active: closeButton.enabled
                        mainText: closeButton.text
                    }
                }
            }

            ItemsConfigurationWorkspace {
                id: workspace

                Layout.fillWidth: true
                Layout.fillHeight: true
                catalogEntries: root.catalogEntries
                surfaceContentWidth: configurationSurface.contentImplicitWidth
                items: draftController.draftItems
                selectedIndex: draftController.selectedIndex
                selectedItemRemovable: root.selectedItemRemovable
                loaded: draftController.loaded
                dirty: draftController.dirty
                committing: root.committing
                errorText: root.errorMessage()
                onAddRequested: function(itemType, insertionIndex) {
                    root.addDraftItem(itemType, insertionIndex)
                }
                onSelected: function(index) {
                    draftController.select(index)
                }
                onMoveRequested: function(sourceIndex, targetIndex) {
                    root.moveDraftItem(sourceIndex, targetIndex)
                }
                onMoveToInsertionRequested: function(sourceIndex,
                        insertionIndex) {
                    root.moveDraftItemToInsertion(sourceIndex, insertionIndex)
                }
                onRemoveRequested: function(index) {
                    root.removeDraftItem(index)
                }
                onCancelRequested: root.cancelDraft()
                onApplyRequested: root.requestCommit(false)
                onAcceptRequested: root.requestCommit(true)
            }
        }
    }
}
// qmllint enable unqualified
