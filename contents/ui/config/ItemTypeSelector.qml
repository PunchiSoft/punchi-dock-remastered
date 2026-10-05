// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQml.Models
import org.kde.kirigami as Kirigami
import "code/itemTypeCatalog.js" as ItemTypeCatalog

// Drop-down selector for the type the «Add item» dialog will build.
//
// The catalogue remains the only source of type metadata. The closed control
// shows the current draft type; opening it reveals the available types with
// their icon and description. An unavailable singleton stays visible with its
// reason, but cannot be activated.
//
// The draft is authoritative. Activating a row only emits `typeRequested`; the
// control then synchronizes back from `draftType`, so an edited draft that still
// awaits discard confirmation never appears to have changed type prematurely.
Controls.ComboBox {
    id: root

    objectName: "itemTypeSelector"

    property var draftController: null
    property int revision: 0

    readonly property var entries: ItemTypeCatalog.types()
    readonly property var rows: {
        root.revision
        const result = []
        for (let index = 0; index < root.entries.length; index++) {
            const descriptor = root.entries[index]
            const available = root.draftController
                ? root.draftController.isTypeAvailable(descriptor.type) : true
            result.push({
                "type": String(descriptor.type),
                "icon": String(descriptor.icon),
                "title": String(descriptor.title),
                "description": String(descriptor.description),
                "available": available,
                "detail": available
                    ? String(descriptor.description)
                    : String(root.draftController
                        ? root.draftController.unavailableReason(descriptor.type)
                        : "")
            })
        }
        return result
    }
    readonly property string selectedType: draftController
        ? String(draftController.draftType) : ""
    readonly property int entryHeight: Kirigami.Units.gridUnit * 3.2
    readonly property int maximumVisibleEntries: 6
    readonly property real maximumPopupHeight: entryHeight
        * maximumVisibleEntries + popup.topPadding + popup.bottomPadding
    // Recent KDE styles expose a ListView; older styles wrap it in a ScrollView.
    // Keep the native viewport unless its public list operations are absent.
    readonly property var popupViewport: popup.contentItem
    property bool usingPopupViewportFallback: false
    readonly property var selectedRow: currentIndex >= 0
        && currentIndex < rows.length ? rows[currentIndex] : null
    readonly property string selectedIconName: selectedRow
        ? String(selectedRow.icon) : ""
    readonly property var nativeIconHints: root.createNativeIconHints()
    readonly property bool usingIconFallback: nativeIconHints === null

    signal typeRequested(string type)

    implicitWidth: Kirigami.Units.gridUnit * 16
    model: rows
    textRole: "title"
    displayText: selectedRow ? String(selectedRow.title) : ""
    Accessible.name: i18nc("@info:accessibility", "Element type") // qmllint disable unqualified
    Accessible.description: selectedRow ? String(selectedRow.detail) : ""

    function createNativeIconHints() {
        // Compile the optional attached type separately: even an inactive
        // inline Component would prevent this selector loading on older KF6.
        // The source is fixed, and its creation context and lifetime belong to
        // this selector. The binding continues to track the selected row.
        try {
            return Qt.createQmlObject(`
                import QtQml
                import org.kde.kirigami as Kirigami
                QtObject {
                    Kirigami.StyleHints.iconName: ""
                    property Binding iconBinding: Binding {
                        target: root.Kirigami.StyleHints
                        property: "iconName"
                        value: root.selectedIconName
                    }
                }
            `, root, "ItemTypeSelectorStyleHints")
        } catch (error) {
            return null
        }
    }

    Binding {
        target: root.contentItem
        property: "visible"
        when: root.usingIconFallback
        value: false
    }

    // Older qqc2-desktop-style paints non-editable text in its StyleItem.
    // Suppress only that text; retain the native background and arrow.
    Binding {
        target: root.background
        property: "text"
        when: root.usingIconFallback && root.background !== null
            && "text" in root.background
        value: ""
    }

    RowLayout {
        id: fallbackContent

        objectName: "itemTypeFallbackContent"
        // Keep the style's TextField alive: older desktop styles also use it
        // for their mobile cursor helpers, even when the control is read-only.
        anchors.fill: root.contentItem
        anchors.leftMargin: root.mirrored && root.background !== null
            && "text" in root.background ? Kirigami.Units.iconSizes.small : 0
        anchors.rightMargin: !root.mirrored && root.background !== null
            && "text" in root.background ? Kirigami.Units.iconSizes.small : 0
        visible: root.usingIconFallback
        layoutDirection: root.mirrored ? Qt.RightToLeft : Qt.LeftToRight
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            objectName: "itemTypeFallbackIcon"
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Layout.preferredWidth
            source: root.selectedIconName
            isMask: root.selectedIconName.indexOf("-symbolic") >= 0
            enabled: root.enabled
            Accessible.ignored: true
        }

        Controls.Label {
            Layout.fillWidth: true
            text: root.displayText
            font: root.font
            color: root.enabled ? root.palette.buttonText
                : Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: root.mirrored ? Text.AlignRight : Text.AlignLeft
            Accessible.ignored: true
        }
    }

    // KDE's native ComboBox popup uses the complete catalogue as its implicit
    // height. Keep that native surface and scrollbar, but give the list a real
    // viewport so a long catalogue cannot take over the configuration window.
    popup.height: Math.min(popup.implicitHeight, root.maximumPopupHeight)

    Binding {
        target: root.popup
        property: "contentItem"
        when: root.usingPopupViewportFallback
        value: fallbackViewport
        restoreMode: Binding.RestoreNone
    }

    DelegateModel {
        id: fallbackDelegateModel

        model: root.usingPopupViewportFallback ? root.rows : null
        delegate: root.delegate
    }

    ListView {
        id: fallbackViewport

        implicitHeight: contentHeight
        visible: root.usingPopupViewportFallback
        clip: true
        model: fallbackDelegateModel
        currentIndex: root.highlightedIndex
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 0
        boundsBehavior: Flickable.StopAtBounds
        LayoutMirroring.enabled: root.mirrored
        LayoutMirroring.childrenInherit: true
        Controls.ScrollBar.vertical: Controls.ScrollBar {
            policy: Controls.ScrollBar.AsNeeded
        }
    }

    Binding {
        target: root.popupViewport
        property: "interactive"
        when: root.popupViewport !== null && "interactive" in root.popupViewport
        value: root.popupViewport
            && root.popupViewport.contentHeight > root.popupViewport.height
    }

    Connections {
        target: root.draftController
        enabled: root.draftController !== null

        function onItemsChanged() {
            root.refresh()
        }

        function onDraftTypeChanged() {
            root.synchronizeSelection()
        }
    }

    Connections {
        target: root.popup

        function onOpened() {
            const index = root.highlightedIndex >= 0
                ? root.highlightedIndex : root.currentIndex
            const viewport = root.popupViewport
            if (index >= 0 && viewport) {
                viewport.positionViewAtIndex(index, ListView.Contain)
            }
        }
    }

    function typeAt(index) {
        return index >= 0 && index < root.rows.length
            ? String(root.rows[index].type) : ""
    }

    function isEntryAvailable(index) {
        return index >= 0 && index < root.rows.length
            && Boolean(root.rows[index].available)
    }

    function indexOfType(type) {
        const wanted = String(type)
        for (let index = 0; index < root.rows.length; index++) {
            if (String(root.rows[index].type) === wanted) {
                return index
            }
        }
        return -1
    }

    function synchronizeSelection() {
        const selectedIndex = root.indexOfType(root.selectedType)
        if (root.currentIndex !== selectedIndex) {
            root.currentIndex = selectedIndex
        }
    }

    function refresh() {
        root.revision += 1
        root.synchronizeSelection()
    }

    function focusFirstAvailable() {
        root.synchronizeSelection()
        root.forceActiveFocus()
    }

    function requestIndex(index) {
        if (!root.isEntryAvailable(index)) {
            root.synchronizeSelection()
            return false
        }
        root.typeRequested(root.typeAt(index))
        root.synchronizeSelection()
        return true
    }

    onActivated: function(index) {
        root.requestIndex(index)
    }

    onRowsChanged: root.synchronizeSelection()
    Component.onCompleted: {
        root.usingPopupViewportFallback = root.popupViewport !== null
            && !("positionViewAtIndex" in root.popupViewport)
        root.synchronizeSelection()
    }

    delegate: Controls.ItemDelegate {
        id: entryDelegate

        required property int index
        // Qt Quick Controls exposes ComboBox roles through `model`; this is also
        // the contract used by KDE's own ComboBox delegates. `modelData` is not
        // the row object here and made every availability lookup undefined.
        required property var model

        objectName: "itemTypeEntry-" + String(model.type)

        width: ListView.view ? ListView.view.width : root.width
        height: root.entryHeight
        enabled: Boolean(model.available)
        highlighted: root.highlightedIndex === entryDelegate.index
        Accessible.name: String(model.title)
        Accessible.description: String(model.detail)

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                objectName: "itemTypeEntryIcon-"
                    + String(entryDelegate.model.type)
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Layout.preferredWidth
                source: String(entryDelegate.model.icon)
                isMask: String(entryDelegate.model.icon)
                    .indexOf("-symbolic") >= 0
                Accessible.ignored: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Controls.Label {
                    Layout.fillWidth: true
                    text: String(entryDelegate.model.title)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Controls.Label {
                    objectName: "itemTypeEntryDetail-"
                        + String(entryDelegate.model.type)
                    Layout.fillWidth: true
                    text: String(entryDelegate.model.detail)
                    opacity: Boolean(entryDelegate.model.available) ? 0.7 : 1
                    color: Boolean(entryDelegate.model.available)
                        ? Kirigami.Theme.textColor
                        : Kirigami.Theme.negativeTextColor
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
    }
}
