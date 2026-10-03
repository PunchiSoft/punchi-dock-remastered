// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "code/itemTypeCatalog.js" as ItemTypeCatalog
import "code/draftFormAdapter.js" as DraftFormAdapter

// Surface and lifecycle of the «Add item» dialog.
//
// This component owns the navigation, the focus, the Cancel path and the
// transactional contract; it does not own the draft. The draft lives in
// `ItemDraftController`, which is injected as `draftController` and announces the
// finished element through `itemAccepted(var item)`. Nothing is written to the
// dock item list or to `cfg_` values here: accepting only closes the dialog, and
// whoever injected the controller decides what to do with the element, so
// cancelling cannot leave a provisional item behind.
Controls.Dialog {
    id: root

    objectName: "itemConfigurationDialog"

    // Draft controller. The dialog works without it only to keep the component
    // instantiable on its own; a real use always injects one.
    property var draftController: null
    property var applicationLauncherDropValidator: null
    // Type the user asked for after editing the draft; while it is not empty the
    // dialog shows the confirmation instead of replacing the draft. The
    // confirmation is inline on purpose: a second Controls.Dialog must not be
    // loaded inside this one.
    property string pendingTypeChange: ""

    readonly property bool compactLayout: width > 0
        && width < Kirigami.Units.gridUnit * 34
    // Generation of the draft this surface opened. The close of a popup is
    // delivered after the call that closed it, so the guard keeps a late close
    // from discarding a draft that started meanwhile.
    property int openedGeneration: -1
    // True while the selected type has a form connected inside this dialog.
    readonly property bool formEditorVisible: root.draftAvailable
        && DraftFormAdapter.handlesType(root.draftController.draftType)
    // Editor key the catalogue names for the drafted type. This dialog is the only
    // place that turns that key into a component, so neither here nor in the
    // catalogue there is a second list of types.
    readonly property string editorKey: root.draftAvailable
        ? ItemTypeCatalog.editorFor(root.draftController.draftType) : ""
    // The drafted type is configured by an options panel extracted from its own
    // dialog.
    readonly property bool optionsPanelVisible: root.draftAvailable
        && root.componentForEditor(root.editorKey) !== null
    // The selector is now a compact drop-down above the form. The editor receives
    // the full dialog width and only stacks its own rows when the whole surface is
    // compact.
    readonly property bool narrowBody: root.compactLayout
    // The initial synchronization shows the draft in the panel. That is not an
    // edit of the user, so it is guarded and never marks the draft as edited.
    property bool syncingForm: false
    property string containerLoadStatusText: ""
    property int containerLoadStatusType: Kirigami.MessageType.Warning

    function clearContainerLoadStatus() {
        root.containerLoadStatusText = ""
    }

    function showContainerLoadStatus(message, type) {
        if (!root.visible || !root.draftAvailable
                || String(root.draftController.draftType) !== "folder") {
            return
        }
        root.containerLoadStatusType = type
        root.containerLoadStatusText = String(message || "")
    }

    // Input edits invalidate only content discovery, not shared icon/picker work.
    function invalidateContainerLoad() {
        root.clearContainerLoadStatus()
        if (root.draftController === null) {
            return
        }
        const operation = root.draftController.pendingExternalOperation
        if (operation !== null
                && (String(operation.kind) === "container-folder"
                    || String(operation.kind) === "container-applications")) {
            root.draftController.clearExternalOperation()
        }
    }

    // Mapping the catalogue key to the component that renders it.
    function componentForEditor(key) {
        if (String(key) === "punchimenu-options") {
            return punchiMenuOptionsComponent
        }
        if (String(key) === "control-center-options") {
            return controlCenterOptionsComponent
        }
        if (String(key) === "media-options") {
            return mediaOptionsComponent
        }
        if (String(key) === "trash-options") {
            return trashOptionsComponent
        }
        if (String(key) === "calendar-options") {
            return calendarOptionsComponent
        }
        return null
    }

    // Requests the dialog cannot serve on its own yet: they are announced so the
    // page can connect them when the dialog is wired, and they stay unconnected
    // while the dialog is not reachable.
    signal applicationSearchRequested(string text)
    signal iconPickerRequested(string target)
    signal folderPickerRequested()
    signal contentLoadRequested()
    signal applicationLauncherDropped(var urls)
    signal soundPickerRequested()
    signal soundPreviewRequested()
    signal colorPickerRequested(string target)

    // Applications the media panel can offer as a player. Whoever discovers them
    // fills this list when it arrives—asynchronously—and the panel rebuilds its
    // options from it without announcing a choice; this dialog does not discover
    // anything on its own.
    property var mediaApplications: []

    // Selection of the nested list. It is visual state only: the data lives in the
    // draft, so it is reset whenever the dialog opens, closes, changes type or
    // replaces its draft.
    property int selectedActionIndex: -1
    readonly property bool nestedEditorVisible: root.formEditorVisible
        && root.draftController.draftNestedEditable

    // The list is a projection of the draft: it is rebuilt after every change and
    // is never the authoritative state.
    ListModel {
        id: actionModel
    }
    readonly property bool draftAvailable: draftController !== null
        && draftController.draft !== null
    readonly property int selectorWidth: Kirigami.Units.gridUnit * 16
    readonly property string currentUnavailableReason: root.draftAvailable
        && !root.draftController.isTypeAvailable(root.draftController.draftType)
        ? String(root.draftController.unavailableReason(
            root.draftController.draftType)) : ""

    // The dialog re-emits nothing about the element: the controller's
    // `itemAccepted` is the single intention. `surfaceClosed` only tells the page
    // that the surface went away, so it can restore the focus it took.
    signal surfaceClosed()

    title: i18nc("@title:window", "Add item to Dock") // qmllint disable unqualified
    modal: true
    closePolicy: Controls.Popup.CloseOnEscape
    implicitWidth: Kirigami.Units.gridUnit * 40
    implicitHeight: Kirigami.Units.gridUnit * 26

    // Opens the dialog for a type. Returns the generation of the new draft so the
    // caller can drop the asynchronous answers that arrive after it closes.
    function openFor(type) {
        if (root.draftController === null) {
            return -1
        }
        root.pendingTypeChange = ""
        const generation = root.draftController.open(type)
        if (!root.draftAvailable) {
            return -1
        }
        root.openedGeneration = generation
        root.synchronizeForm()
        root.open()
        return generation
    }

    // Reads the form and writes it into the draft through the controller: the
    // only write path, and the only copy of the data.
    function formChanged() {
        if (root.syncingForm || !root.formEditorVisible) {
            return
        }
        const draft = root.draftController.draft
        const type = root.draftController.draftType
        root.draftController.setDraftValues(
            DraftFormAdapter.fieldsFor(draft, editorPanel, type))
        root.draftController.pruneDraft()
    }

    // Shows a fresh draft in the form without marking it as edited, and leaves no
    // state of the previous draft behind: the fields follow the new draft and the
    // nested list is rebuilt from it with no selection.
    function synchronizeForm() {
        root.clearContainerLoadStatus()
        root.syncingForm = true
        try {
            if (root.formEditorVisible) {
                DraftFormAdapter.applyToPanel(root.draftController.draft,
                    editorPanel, root.draftController.draftType)
            }
            root.resetNestedList()
            actionEditor.actionsEnabledChecked =
                DraftFormAdapter.actionsEnabledValue(root.draftController.draft)
            actionEditor.actionPopupLimitRowsChecked =
                DraftFormAdapter.actionPopupLimitEnabled(root.draftController.draft)
            actionEditor.actionPopupMaxVisibleRowsValue =
                DraftFormAdapter.actionPopupLimitValue(root.draftController.draft)
            root.rebuildNestedRows()
        } finally {
            root.syncingForm = false
        }
        root.draftController.refreshDraft()
    }

    // External pickers and discovery results update the draft through the
    // controller. Discovery replaces container contents, so its callers also
    // rebuild the list projection and clear the previous content's selection.
    // Other pickers leave the nested selection alone. Extracted option panels
    // already follow draftRevision reactively.
    function refreshEditorFields(refreshNestedContent) {
        if (!root.formEditorVisible || !root.draftAvailable) {
            return
        }
        root.syncingForm = true
        try {
            DraftFormAdapter.applyToPanel(root.draftController.draft,
                editorPanel, root.draftController.draftType)
        } finally {
            root.syncingForm = false
        }
        if (refreshNestedContent === true) {
            root.clearContainerLoadStatus()
            root.resetNestedList()
            root.rebuildNestedRows()
        }
    }

    function applyPickedIcon(operation, iconName) {
        if (!operation || !root.draftAvailable) {
            return false
        }
        const details = operation.details || {}
        const selection = root.draftController.applyExternalIcon(
            Number(operation.generation), String(operation.target),
            Number(details.nestedIndex === undefined
                ? root.selectedActionIndex : details.nestedIndex), iconName)
        if (String(operation.target) === "action") {
            if (selection < 0) {
                return false
            }
            root.nestedListChanged(selection)
            actionEditor.actionIconText = String(iconName)
            return true
        }
        root.refreshEditorFields()
        return true
    }

    function showApplicationDropResult(message, isError) {
        actionEditor.applicationLauncherDropMessage = String(message || "")
        actionEditor.applicationLauncherDropMessageIsError = Boolean(isError)
    }

    function rebuildNestedRows() {
        actionModel.clear()
        if (!root.nestedEditorVisible) {
            return
        }
        const rows = DraftFormAdapter.actionRows(root.draftController.draft,
            root.draftController.draftType)
        for (let index = 0; index < rows.length; index++) {
            actionModel.append(rows[index])
        }
    }

    // The projection is dropped with its selection, and the selection goes first so
    // the list never keeps a current index while it is being emptied.
    function resetNestedList() {
        root.selectedActionIndex = -1
        actionModel.clear()
        actionEditor.actionNameText = ""
        actionEditor.actionIconText = ""
        actionEditor.actionCommandText = ""
    }

    function showSelectedNestedEntry() {
        const rows = root.draftAvailable
            ? root.draftController.draftArray(
                root.draftController.nestedArrayName()) : []
        const index = root.selectedActionIndex
        const row = index >= 0 && index < rows.length ? rows[index] : null
        actionEditor.actionNameText = row ? String(row.name || "") : ""
        actionEditor.actionIconText = row ? String(row.icon || "") : ""
        actionEditor.actionCommandText = row ? String(row.command || "") : ""
    }

    // The draft changed through an operation of the controller: the projection is
    // rebuilt from it and the selection follows what the controller proposes. No
    // pruning happens here: the shared helpers already leave the entry canonical,
    // and pruning again would re-seed the suggested actions of the application.
    function nestedListChanged(selection) {
        root.rebuildNestedRows()
        const proposed = Number(selection)
        root.selectedActionIndex = proposed >= 0 && proposed < actionModel.count
            ? proposed : -1
        root.showSelectedNestedEntry()
    }

    function applySelectedNestedEntry() {
        if (root.selectedActionIndex < 0) {
            return
        }
        root.nestedListChanged(root.draftController.applyNestedEntry(
            root.selectedActionIndex, actionEditor.actionNameText,
            actionEditor.actionIconText, actionEditor.actionCommandText))
    }

    function requestType(type) {
        if (!root.draftAvailable) {
            return
        }
        if (root.draftController.requestType(type)) {
            // A clean draft is replaced immediately. Rebuild every visible
            // field and nested projection now; the confirmation path performs
            // the same synchronization after the user approves discarding.
            root.synchronizeForm()
        } else {
            root.pendingTypeChange = String(type)
        }
    }

    function confirmTypeChange() {
        if (root.pendingTypeChange.length === 0 || !root.draftAvailable) {
            return
        }
        const wanted = root.pendingTypeChange
        root.pendingTypeChange = ""
        root.draftController.confirmTypeChange(wanted)
        root.synchronizeForm()
    }

    function keepCurrentDraft() {
        root.pendingTypeChange = ""
    }

    // Cancel path shared by the button, Escape and the window close button:
    // discards the draft, so no item, no selection and no cfg_ value changes.
    function cancelDraft() {
        root.pendingTypeChange = ""
        root.resetNestedList()
        if (root.draftAvailable) {
            root.draftController.cancel()
        }
        root.close()
    }

    function acceptDraft() {
        if (!root.draftAvailable) {
            return false
        }
        if (!root.draftController.accept()) {
            return false
        }
        root.resetNestedList()
        root.close()
        return true
    }

    onOpened: {
        // The rows are recomputed on open, so a singleton the dock gained while
        // the dialog was closed shows its entry as unavailable again.
        selector.refresh()
        selector.focusFirstAvailable()
    }
    onAboutToHide: root.clearContainerLoadStatus()
    // Escape, the close button and the Cancel button all end here. `accept()`
    // leaves the controller without a draft, so this guard cannot cancel twice.
    onClosed: {
        root.clearContainerLoadStatus()
        if (root.draftAvailable
                && root.draftController.generation === root.openedGeneration) {
            root.draftController.cancel()
        }
        root.resetNestedList()
        root.surfaceClosed()
    }

    // Options panels of the extracted types. Each one receives the values of the
    // draft through the adapter and announces what the user asked for; the write
    // goes to the controller, which keeps the only copy of the data. The request
    // for an icon stays an announcement that the owning page routes to the shared
    // picker.
    Component {
        id: punchiMenuOptionsComponent

        PunchiMenuOptionsPanel {
            objectName: "itemConfigurationPunchiMenuPanel"

            compactLayout: root.narrowBody
            selectorWidth: root.selectorWidth
            // The revision of the draft is read on purpose: a plain JavaScript
            // object does not notify its changes, and this is what makes a value
            // written from any other path reach the control.
            readonly property var draftOptions: {
                root.draftController.draftRevision
                return DraftFormAdapter.punchiMenuOptions(
                    root.draftController.draft)
            }
            menuMode: draftOptions.menuMode
            iconName: draftOptions.icon
            onMenuModeSelected: function(mode) {
                root.draftController.setDraftValues({"menuMode": String(mode)})
            }
            onIconPickerRequested: root.iconPickerRequested("punchimenu")
        }
    }

    Component {
        id: controlCenterOptionsComponent

        ControlCenterOptionsPanel {
            objectName: "itemConfigurationControlCenterPanel"

            compactLayout: root.narrowBody
            selectorWidth: root.selectorWidth
            readonly property var draftOptions: {
                root.draftController.draftRevision
                return DraftFormAdapter.controlCenterOptions(
                    root.draftController.draft)
            }
            controlCenterMode: draftOptions.controlCenterMode
            onControlCenterModeSelected: function(mode) {
                root.draftController.setDraftValues(
                    {"controlCenterMode": String(mode)})
            }
        }
    }

    // Options panels of the media player and of the trash. The media panel receives
    // the list of applications from outside and shows it as soon as it arrives; both
    // write the draft only through the controller, which applies the canonical rules
    // of `configItems.js` with `pruneDraft()`.
    Component {
        id: mediaOptionsComponent

        MediaPlayerOptionsPanel {
            id: mediaPanel

            objectName: "itemConfigurationMediaPanel"

            applications: root.mediaApplications
            selectorWidth: root.selectorWidth
            // The revision of the draft is read on purpose: a plain JavaScript
            // object does not notify its changes, so this is what makes a value
            // written from any other path reach the controls.
            readonly property var draftOptions: {
                root.draftController.draftRevision
                return DraftFormAdapter.mediaOptions(root.draftController.draft)
            }
            selectedStorageId: draftOptions.selectedStorageId
            mediaTextMode: draftOptions.mediaTextMode
            mediaDisplayMode: draftOptions.mediaDisplayMode
            openPlayerMinimized: draftOptions.openPlayerMinimized
            autoCollapseDelaySeconds: draftOptions.autoCollapseDelaySeconds
            onPlayerSelected: function(application) {
                root.draftController.setDraftValues(
                    DraftFormAdapter.mediaPlayerFields(application))
                root.draftController.pruneDraft()
            }
            onMediaTextModeSelected: function(mode) {
                root.draftController.setDraftValues(
                    {"mediaTextMode": String(mode)})
                root.draftController.pruneDraft()
            }
            onMediaDisplayModeSelected: function(mode) {
                root.draftController.setDraftValues(
                    {"mediaDisplayMode": String(mode)})
                root.draftController.pruneDraft()
            }
            onOpenPlayerMinimizedSelected: function(enabled) {
                root.draftController.setDraftValues(
                    {"openPlayerMinimized": Boolean(enabled)})
                root.draftController.pruneDraft()
            }
            onAutoCollapseDelaySecondsSelected: function(seconds) {
                root.draftController.setDraftValues(
                    {"mediaAutoCollapseDelaySeconds": Number(seconds)})
                root.draftController.pruneDraft()
            }
        }
    }

    Component {
        id: trashOptionsComponent

        TrashOptionsPanel {
            id: trashPanel

            objectName: "itemConfigurationTrashPanel"

            editable: root.draftAvailable
            compactLayout: root.narrowBody
            readonly property var draftOptions: {
                root.draftController.draftRevision
                return DraftFormAdapter.trashOptions(root.draftController.draft,
                    root.draftController.defaultTrashEmptySound)
            }
            nameText: draftOptions.name
            emptyIconText: draftOptions.icon
            fullIconText: draftOptions.fullIcon
            showStateChecked: draftOptions.showState
            acceptDropsChecked: draftOptions.acceptDrops
            soundPath: draftOptions.soundPath
            soundFileName: DraftFormAdapter.soundFileName(soundPath)
            defaultSoundFileName: DraftFormAdapter.soundFileName(
                root.draftController.defaultTrashEmptySound)
            onFormChanged: {
                root.draftController.setDraftValues(
                    DraftFormAdapter.trashFields(trashPanel))
                root.draftController.pruneDraft()
            }
            // The default sound is written into the draft, which is the only copy of
            // the data: the panel then shows it again through its value.
            onSoundResetRequested: {
                root.draftController.setDraftValues(
                    {"emptySound": String(root.draftController.defaultTrashEmptySound)})
                root.draftController.pruneDraft()
            }
            onEmptyIconPickerRequested: root.iconPickerRequested("trash")
            onFullIconPickerRequested: root.iconPickerRequested("trashFull")
            onSoundPickerRequested: root.soundPickerRequested()
            onSoundPreviewRequested: root.soundPreviewRequested()
        }
    }

    // Options of a calendar. Only the calendar is offered here: the type selector has
    // no clock entry, and the clock keeps being configured from the dialog of an
    // existing element. The panel writes the draft only through the controller, which
    // applies the canonical rules of `configItems.js` with `pruneDraft()`, and the
    // colour request stays an announcement.
    Component {
        id: calendarOptionsComponent

        TimedOptionsPanel {
            id: calendarPanel

            objectName: "itemConfigurationCalendarPanel"

            selectedItemType: "calendar"
            editable: root.draftAvailable
            compactLayout: root.narrowBody
            // The revision of the draft is read on purpose: a plain JavaScript object
            // does not notify its changes, and this is what makes a value written
            // from any other path reach the controls. The values are pushed into the
            // controls without announcing anything.
            readonly property var draftOptions: {
                root.draftController.draftRevision
                return DraftFormAdapter.calendarOptions(root.draftController.draft)
            }
            onDraftOptionsChanged: calendarPanel.synchronizeValues(draftOptions)
            onFormChanged: {
                root.draftController.setDraftValues(
                    DraftFormAdapter.calendarFields(calendarPanel))
                root.draftController.pruneDraft()
            }
            onColorRequested: function(target) {
                root.colorPickerRequested(String(target))
            }
        }
    }

    contentItem: GridLayout {
        columns: 1
        columnSpacing: 0
        rowSpacing: Kirigami.Units.smallSpacing

        // The drop-down carries the label the fields below already carry, so the row
        // reads like the rest of the form and the reader knows what the list
        // chooses. The selector keeps its own width, model and signal.
        RowLayout {
            objectName: "itemConfigurationTypeRow"

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            spacing: Kirigami.Units.smallSpacing

            Controls.Label {
                objectName: "itemConfigurationTypeLabel"

                // qmllint disable unqualified
                // The same short label the form below uses: it names the list
                // without stealing the row from it.
                text: i18n("Type:")
                // qmllint enable unqualified
                // The column stays as wide as the labels of the fields below, so
                // the form keeps one alignment. The wording is short on purpose:
                // a longer sentence would widen this cell and push the list right.
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                opacity: 0.75
            }

            ItemTypeSelector {
                id: selector

                objectName: "itemConfigurationTypeSelector"

                draftController: root.draftController
                Layout.fillWidth: true
                Layout.preferredWidth: root.selectorWidth
                Layout.maximumWidth: root.compactLayout
                    ? Number.POSITIVE_INFINITY : root.selectorWidth
                onTypeRequested: function(type) {
                    root.requestType(type)
                }
            }
        }

        // Configuration area. It scrolls on its own, so the buttons of the footer
        // never leave the screen.
        Controls.ScrollView {
            id: bodyScroll

            objectName: "itemConfigurationDraftArea"

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 6
            // The content fills the viewport horizontally: the form only scrolls
            // vertically, and no width is derived from the implicit sizes of the
            // delegates of the nested list.
            contentWidth: availableWidth

            Item {
                id: draftState

                objectName: "itemConfigurationDraftContent"

                // Definite width: the content follows the viewport, so the size of
                // the nested list never depends on the size of its own delegates.
                width: bodyScroll.availableWidth
                height: draftColumn.implicitHeight

                ColumnLayout {
                    id: draftColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: Kirigami.Units.smallSpacing

                    // Form of the types this dialog already edits. The type comes
                    // from the drop-down above, so the panel hides its own selector
                    // and the flow never shows two of them. Every write goes back
                    // to the draft through the controller; the form is never asked
                    // to save anything by itself.
                    ItemEditorPanel {
                        id: editorPanel

                        objectName: "itemConfigurationEditorPanel"

                        Layout.fillWidth: true
                        visible: root.formEditorVisible
                        showTypeSelector: false
                        containerLoadStatusText: root.containerLoadStatusText
                        containerLoadStatusType: root.containerLoadStatusType
                        // qmllint disable unqualified
                        nameLabel: i18n("Name:")
                        aliasLabel: i18n("Alias:")
                        aliasPlaceholder: i18n("Type name or alias... then search")
                        descLabel: i18n("Description:")
                        itemTypeLabel: i18n("Type:")
                        launchAppText: i18n("Launch app")
                        containerText: i18n("Container")
                        viewLabel: i18n("View:")
                        gridText: i18n("Grid")
                        listText: i18n("List")
                        detailedText: i18n("Detailed")
                        fanText: i18nc("@item:inlistbox Folder popup layout", "Fan")
                        noteText: i18n("Note")
                        separatorText: i18n("Separator")
                        spacerText: i18n("Spacer")
                        containerSourceLabel: i18n("Content:")
                        manualContainerText: i18n("Manual")
                        folderContainerText: i18n("Folder")
                        categoryContainerText: i18n("Application category")
                        folderPathLabel: i18n("Folder:")
                        categoryLabel: i18n("Category:")
                        refreshContentText: i18n("Load content")
                        iconLabel: i18n("Icon:")
                        commandLabel: i18n("Command:")
                        spacerSizeLabel: i18n("Spacer size:")
                        chooseIconText: i18n("Choose icon")
                        // qmllint enable unqualified

                        onFormChanged: root.formChanged()
                        onItemModeChanged: root.formChanged()
                        onContainerLayoutChanged: root.formChanged()
                        onContainerSourceChanged: {
                            root.invalidateContainerLoad()
                            root.formChanged()
                        }
                        onContainerCategoryChanged: {
                            root.invalidateContainerLoad()
                            root.formChanged()
                        }
                        onContainerPathEdited: root.invalidateContainerLoad()
                        onAppCommandEdited: root.formChanged()
                        // The dialog announces requests that the owning page routes
                        // to shared services and pickers.
                        onIconPickerRequested: function(target) {
                            root.iconPickerRequested(String(target))
                        }
                        onAutofillRequested: function(alias) {
                            root.applicationSearchRequested(String(alias))
                        }
                        onFolderPickerRequested: root.folderPickerRequested()
                        onContainerRefreshRequested: {
                            root.clearContainerLoadStatus()
                            root.formChanged()
                            root.contentLoadRequested()
                        }
                    }

                    // Options of a type whose configuration was extracted from its
                    // own dialog: the panel is loaded from the key the catalogue
                    // names for the drafted type and is dropped when the type
                    // changes, so nothing of the previous type survives here.
                    Loader {
                        id: optionsPanelLoader

                        objectName: "itemConfigurationOptionsPanel"

                        Layout.fillWidth: true
                        visible: root.optionsPanelVisible
                        active: root.optionsPanelVisible
                        sourceComponent: root.optionsPanelVisible
                            ? root.componentForEditor(root.editorKey) : null
                    }

                    // Nested list of the draft: context actions of an application
                    // or applications of a container. Every operation goes to the
                    // controller, which reuses the rules of `configItems.js`; the
                    // list model is only the projection it is redrawn from.
                    ItemActionEditor {
                        id: actionEditor

                        objectName: "itemConfigurationActionEditor"

                        Layout.fillWidth: true
                        // The layout must not ask the editor for its implicit width:
                        // its delegates size themselves from the list, and that
                        // chain would close a cycle on implicitWidth.
                        Layout.preferredWidth: 0
                        visible: root.nestedEditorVisible
                        actionModel: actionModel
                        editableItemAvailable: root.draftAvailable
                        applicationLauncherDropEnabled: {
                            if (!root.draftAvailable) {
                                return false
                            }
                            root.draftController.draftRevision
                            return String(root.draftController.draftType) === "folder"
                                && String(root.draftController.draft.sourceType
                                    || "manual") === "manual"
                        }
                        applicationLauncherDropValidator:
                            root.applicationLauncherDropValidator
                        selectedActionIndex: root.selectedActionIndex
                        selectedItemType: root.draftAvailable
                            ? String(root.draftController.draftType) : "app"
                        itemModeValue: editorPanel.itemModeValue
                        appIconText: editorPanel.appIconText
                        // qmllint disable unqualified
                        rightClickCommandsText: i18n("Right-click commands")
                        containerApplicationsText: i18n("Container applications")
                        enableRightClickMenuText: i18n("Enable right-click menu")
                        limitContextMenuRowsText: i18n("Limit menu rows")
                        rowsText: i18n("rows")
                        rowsValueText: i18n("%1 rows")
                        actionNameLabel: i18n("Action name:")
                        actionIconLabel: i18n("Action icon:")
                        actionCommandLabel: i18n("Action command:")
                        chooseIconText: i18n("Choose icon")
                        dropApplicationsHereText:
                            i18nc("@info:placeholder", "Drop applications here")
                        addApplicationText:
                            i18nc("@action:button", "Add application")
                        addActionText: i18nc("@action:button", "Add action")
                        // qmllint enable unqualified

                        onActionsEnabledToggled: function(checked) {
                            root.draftController.setActionsEnabled(Boolean(checked))
                            root.nestedListChanged(root.selectedActionIndex)
                        }
                        onActionPopupSettingsChanged: {
                            root.draftController.setActionPopupLimitRows(
                                actionEditor.actionPopupLimitRowsChecked,
                                actionEditor.actionPopupMaxVisibleRowsValue)
                        }
                        onActionSelected: function(index) {
                            root.selectedActionIndex = Number(index)
                            root.showSelectedNestedEntry()
                        }
                        onAddActionRequested: {
                            root.nestedListChanged(
                                root.draftController.addNestedEntry())
                        }
                        onMoveActionRequested: function(delta) {
                            root.nestedListChanged(root.draftController.moveNestedEntry(
                                root.selectedActionIndex, Number(delta)))
                        }
                        onRemoveActionRequested: {
                            root.nestedListChanged(
                                root.draftController.removeNestedEntry(
                                    root.selectedActionIndex))
                        }
                        onActionFormChanged: root.applySelectedNestedEntry()
                        onIconPickerRequested: function(target) {
                            root.iconPickerRequested(String(target))
                        }
                        onApplicationLauncherDropped: function(urls) {
                            root.applicationLauncherDropped(urls)
                        }
                    }


                    Kirigami.InlineMessage {
                        objectName: "itemConfigurationUnavailableMessage"

                        Layout.fillWidth: true
                        visible: root.currentUnavailableReason.length > 0
                        text: root.currentUnavailableReason
                        type: Kirigami.MessageType.Warning
                    }

                    // Inline confirmation: changing the type with an edited draft
                    // discards what the user already set, so it is asked here,
                    // inside the same surface.
                    ColumnLayout {
                        objectName: "itemConfigurationTypeChangePrompt"

                        visible: root.pendingTypeChange.length > 0
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Controls.Label {
                            Layout.fillWidth: true
                            // qmllint disable unqualified
                            text: i18nc("@info", "Changing the type discards what you already set.")
                            // qmllint enable unqualified
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Controls.Button {
                                objectName: "itemConfigurationDiscardButton"

                                // qmllint disable unqualified
                                text: i18nc("@action:button", "Discard changes")
                                // qmllint enable unqualified
                                onClicked: root.confirmTypeChange()
                            }

                            Controls.Button {
                                objectName: "itemConfigurationKeepButton"

                                // qmllint disable unqualified
                                text: i18nc("@action:button", "Keep editing")
                                // qmllint enable unqualified
                                onClicked: root.keepCurrentDraft()
                            }
                        }
                    }
                }
            }
        }
    }

    footer: Controls.DialogButtonBox {
        id: buttonBox

        Controls.Button {
            objectName: "itemConfigurationCancelButton"

            // qmllint disable unqualified
            text: i18nc("@action:button", "Cancel")
            // qmllint enable unqualified
            Controls.DialogButtonBox.buttonRole: Controls.DialogButtonBox.RejectRole
            onClicked: root.cancelDraft()
        }

        Controls.Button {
            objectName: "itemConfigurationAddButton"

            // qmllint disable unqualified
            text: i18nc("@action:button", "Add")
            // qmllint enable unqualified
            Controls.DialogButtonBox.buttonRole: Controls.DialogButtonBox.AcceptRole
            enabled: root.draftAvailable
                && root.draftController.draftValid
                && root.draftController.isTypeAvailable(
                    root.draftController.draftType)
            onClicked: root.acceptDraft()
        }
    }
}
