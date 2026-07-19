import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Dialogs as QtDialogs
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "../org/punchi/dock" as Punchi
import "components"

KCM.SimpleKCM {
    id: page
    implicitWidth: layoutMetrics.pageImplicitWidth

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    property alias cfg_showLabels: showLabelsCheck.checked
    property alias cfg_showItemHoverBackground: showItemHoverBackgroundCheck.checked
    property alias cfg_iconReflectionsEnabled: iconReflectionsCheck.checked
    property alias cfg_iconReflectionOpacity: iconReflectionOpacitySlider.value
    property string cfg_indicatorType: "line"
    property string cfg_indicatorPosition: "bottom"
    property alias cfg_indicatorOpacity: indicatorOpacitySlider.value
    property alias cfg_indicatorThickness: indicatorThicknessSlider.value
    property string cfg_dockThemeMode: "plasma"
    property string cfg_dockThemeCustomId: ""
    property alias cfg_windowPreviewStyle: popupAppearancePage.cfg_windowPreviewStyle
    property alias cfg_windowPreviewScale: popupAppearancePage.cfg_windowPreviewScale
    property alias cfg_mediaControlsOnHover: popupAppearancePage.cfg_mediaControlsOnHover
    property alias cfg_taskPopupRadiusAuto: popupAppearancePage.cfg_taskPopupRadiusAuto
    property alias cfg_taskPopupRadius: popupAppearancePage.cfg_taskPopupRadius
    property alias cfg_maxPopupRows: popupAppearancePage.cfg_maxPopupRows
    property alias cfg_popupAnimation: popupAppearancePage.cfg_popupAnimation
    property alias cfg_popupAnimationSpeed: popupAppearancePage.cfg_popupAnimationSpeed
    property alias cfg_popupAnimationSpeedPercent: popupAppearancePage.cfg_popupAnimationSpeedPercent
    property alias cfg_popupAnimationIntensity: popupAppearancePage.cfg_popupAnimationIntensity
    property alias cfg_contextMenuTransitionSpeed: menuAppearancePage.cfg_contextMenuTransitionSpeed
    property alias cfg_audioSpectrumEnabled: audioVisualizerPage.cfg_audioSpectrumEnabled
    property alias cfg_audioSpectrumIntensity: audioVisualizerPage.cfg_audioSpectrumIntensity
    property alias cfg_audioSpectrumUsePlasmaTheme: audioVisualizerPage.cfg_audioSpectrumUsePlasmaTheme
    property alias cfg_audioSpectrumBarCount: audioVisualizerPage.cfg_audioSpectrumBarCount
    property alias cfg_audioSpectrumStyle: audioVisualizerPage.cfg_audioSpectrumStyle
    property alias cfg_audioSpectrumBackgroundMode: audioVisualizerPage.cfg_audioSpectrumBackgroundMode
    property alias cfg_audioSpectrumOrigin: audioVisualizerPage.cfg_audioSpectrumOrigin
    property alias cfg_audioSpectrumFlow: audioVisualizerPage.cfg_audioSpectrumFlow
    property var lastThemeDirectoryImport: ({})
    property string pendingThemeRemovalId: ""
    property string pendingThemeRemovalName: ""
    property int pendingThemeRemovalIndex: -1
    property string themeRemovalMessage: ""

    readonly property bool interactiveCursorEnabled: !!Plasmoid.configuration.globalMouseCursor
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool horizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool iconReflectionsSupported: !inPanel || horizontalPanel
    readonly property bool indicatorPositionApplicable: cfg_indicatorType !== "ring"
        && cfg_indicatorType !== "none"
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    readonly property var indicatorTypeOptions: [
        { "text": i18n("Line"), "value": "line" },
        { "text": i18n("Dot"), "value": "dot" },
        { "text": i18n("Ring"), "value": "ring" },
        { "text": i18n("Rounded square"), "value": "square" },
        { "text": i18n("None"), "value": "none" }
    ]
    readonly property var indicatorPositionOptions: [
        { "text": i18n("Bottom"), "value": "bottom" },
        { "text": i18n("Top"), "value": "top" }
    ]

    // qmllint disable unqualified
    header: Controls.TabBar {
        id: appearanceTabs
        Accessible.name: i18n("Appearance sections")

        Controls.TabButton {
            text: i18n("Dock")
        }

        Controls.TabButton {
            text: i18n("Window previews")
        }

        Controls.TabButton {
            text: i18n("Popups")
        }

        Controls.TabButton {
            text: i18n("Menus")
        }

        Controls.TabButton {
            text: i18n("Audio visualizer")
        }
    }
    // qmllint enable unqualified
    // qmllint disable unqualified
    readonly property var dockThemeModeOptions: [
        { "text": i18n("Plasma theme"), "value": "plasma" },
        { "text": i18n("External JSON theme"), "value": "custom" }
    ]
    // qmllint enable unqualified

    component SectionTitle: Kirigami.Heading {
        Layout.fillWidth: true
        level: 3
        leftPadding: 0
    }

    function syncComboValue(combo, value) {
        if (!combo) {
            return
        }

        const resolvedIndex = Math.max(0, combo.indexOfValue(value))
        if (combo.currentIndex !== resolvedIndex) {
            combo.currentIndex = resolvedIndex
        }
    }

    function syncIndicatorSelectors() {
        syncComboValue(indicatorTypeCombo, page.cfg_indicatorType)
        syncComboValue(indicatorPositionCombo, page.cfg_indicatorPosition)
    }

    function syncDockThemeSelector() {
        syncComboValue(dockThemeModeCombo, page.cfg_dockThemeMode)
    }

    function syncThemeLibrarySelector() {
        if (!dockThemeLibraryCombo) {
            return
        }

        const resolvedIndex = dockThemeLibraryCombo.indexOfValue(
            page.cfg_dockThemeCustomId)
        if (dockThemeLibraryCombo.currentIndex !== resolvedIndex) {
            dockThemeLibraryCombo.currentIndex = resolvedIndex
        }
    }

    function requestSelectedThemeRemoval() {
        const selectedThemeId = String(
            dockThemeLibraryCombo.currentValue || "")
        const selectedThemeIndex = dockThemeLibraryCombo.currentIndex
        if (dockThemeLibraryCombo.currentIndex < 0
            || selectedThemeId.length === 0
            || selectedThemeIndex >= dockThemeRepository.availableThemes.length) {
            return
        }

        const selectedTheme =
            dockThemeRepository.availableThemes[selectedThemeIndex] || ({})
        page.pendingThemeRemovalId = selectedThemeId
        page.pendingThemeRemovalName =
            String(selectedTheme.name || dockThemeLibraryCombo.currentText || "")
        page.pendingThemeRemovalIndex = selectedThemeIndex
        removeThemeDialog.open()
    }

    function removePendingTheme() {
        const removedThemeId = page.pendingThemeRemovalId
        const removedThemeName = page.pendingThemeRemovalName
        const previousIndex = page.pendingThemeRemovalIndex
        if (removedThemeId.length === 0
            || !dockThemeRepository.removeTheme(removedThemeId)) {
            return
        }

        page.lastThemeDirectoryImport = ({})
        // qmllint disable unqualified
        page.themeRemovalMessage = i18n("Theme “%1” was deleted.", removedThemeName)
        // qmllint enable unqualified

        if (dockThemeRepository.availableThemes.length === 0) {
            page.cfg_dockThemeCustomId = ""
            page.cfg_dockThemeMode = "plasma"
        } else if (page.cfg_dockThemeCustomId === removedThemeId) {
            const fallbackIndex = Math.min(
                Math.max(0, previousIndex),
                dockThemeRepository.availableThemes.length - 1)
            const fallbackTheme =
                dockThemeRepository.availableThemes[fallbackIndex] || ({})
            page.cfg_dockThemeCustomId = String(fallbackTheme.id || "")
            if (page.cfg_dockThemeCustomId.length === 0) {
                page.cfg_dockThemeMode = "plasma"
            }
        }

        page.pendingThemeRemovalId = ""
        page.pendingThemeRemovalName = ""
        page.pendingThemeRemovalIndex = -1
        page.syncThemeLibrarySelector()
    }

    // qmllint disable unqualified
    function dockThemeErrorText(errorCode) {
        switch (errorCode) {
        case "invalidSource":
            return i18n("Choose a local JSON file.")
        case "unreadableFile":
            return i18n("The selected theme file could not be read.")
        case "emptyFile":
            return i18n("The selected theme file is empty.")
        case "fileTooLarge":
            return i18n("The selected theme is larger than the 64 KiB limit.")
        case "invalidJson":
            return i18n("The selected file does not contain valid JSON.")
        case "unsupportedSchema":
            return i18n("The selected theme uses an unsupported schema version.")
        case "unsupportedRenderer":
            return i18n("This version of Punchi Dock does not support the renderer requested by the theme.")
        case "themeNotFound":
            return i18n("The configured external theme is unavailable. The Plasma background will be used.")
        case "storageUnavailable":
        case "writeFailed":
            return i18n("Punchi Dock could not store the imported theme.")
        case "invalidDirectory":
            return i18n("Choose a local folder containing JSON themes.")
        case "unreadableDirectory":
            return i18n("The selected theme folder could not be read.")
        case "invalidThemeId":
            return i18n("The selected installed theme has an invalid identifier.")
        case "removeFailed":
            return i18n("Punchi Dock could not delete the selected theme.")
        default:
            return i18n("The selected file is not a supported Punchi Dock theme.")
        }
    }

    function themeDirectoryImportText(result) {
        if (!result || result.candidateCount === undefined) {
            return ""
        }
        if (result.candidateCount === 0) {
            return i18n("The selected folder and its subfolders do not contain JSON theme files.")
        }

        if (result.truncatedCount > 0) {
            return i18n("Folder import finished — added: %1, already installed: %2, rejected: %3, not processed because of the 256-theme limit: %4.",
                result.importedCount, result.duplicateCount,
                result.rejectedCount, result.truncatedCount)
        }
        return i18n("Folder import finished — added: %1, already installed: %2, rejected: %3.",
            result.importedCount, result.duplicateCount, result.rejectedCount)
    }
    // qmllint enable unqualified

    onCfg_indicatorTypeChanged: syncIndicatorSelectors()
    onCfg_indicatorPositionChanged: syncIndicatorSelectors()
    onCfg_dockThemeModeChanged: syncDockThemeSelector()
    onCfg_dockThemeCustomIdChanged: syncThemeLibrarySelector()
    Component.onCompleted: {
        syncIndicatorSelectors()
        syncDockThemeSelector()
        dockThemeRepository.refreshThemes()
        syncThemeLibrarySelector()
    }

    Punchi.DockThemeRepository {
        id: dockThemeRepository
        themeId: page.inPanel ? "" : page.cfg_dockThemeCustomId

        onThemesChanged: page.syncThemeLibrarySelector()
    }

    // qmllint disable unqualified
    QtDialogs.FileDialog {
        id: dockThemeFileDialog
        title: i18n("Import Punchi Dock Theme")
        fileMode: QtDialogs.FileDialog.OpenFile
        nameFilters: [i18n("JSON theme files") + " (*.json)", i18n("All files") + " (*)"]

        onAccepted: {
            page.themeRemovalMessage = ""
            const importedThemeId = dockThemeRepository.importTheme(selectedFile)
            if (importedThemeId.length === 0) {
                return
            }
            page.cfg_dockThemeCustomId = importedThemeId
            page.cfg_dockThemeMode = "custom"
            page.syncThemeLibrarySelector()
        }
    }

    QtDialogs.FolderDialog {
        id: dockThemeFolderDialog
        title: i18n("Import Punchi Dock Theme Folder")

        onAccepted: {
            page.themeRemovalMessage = ""
            page.lastThemeDirectoryImport =
                dockThemeRepository.importThemeDirectory(selectedFolder)
            const selectedThemeId =
                page.lastThemeDirectoryImport.selectedThemeId || ""
            if (selectedThemeId.length > 0) {
                page.cfg_dockThemeCustomId = selectedThemeId
                page.cfg_dockThemeMode = "custom"
                page.syncThemeLibrarySelector()
            }
        }
    }

    Controls.Menu {
        id: importThemeMenu

        Controls.MenuItem {
            text: i18n("Import file…")
            icon.name: "document-import"
            Accessible.name: i18n("Import one Punchi Dock JSON theme")
            onTriggered: {
                page.lastThemeDirectoryImport = ({})
                dockThemeRepository.clearError()
                dockThemeFileDialog.open()
            }
        }

        Controls.MenuItem {
            text: i18n("Import folder…")
            icon.name: "folder-open"
            Accessible.name: i18n("Import all Punchi Dock JSON themes from a folder and its subfolders")
            onTriggered: {
                page.lastThemeDirectoryImport = ({})
                dockThemeRepository.clearError()
                dockThemeFolderDialog.open()
            }
        }
    }

    Kirigami.PromptDialog {
        id: removeThemeDialog
        parent: page
        title: i18nc("@title:window", "Delete Installed Theme?")
        subtitle: i18n("Delete “%1” permanently from the Punchi Dock Remastered theme library?",
            page.pendingThemeRemovalName)
        dialogType: Kirigami.PromptDialog.Warning
        standardButtons: Kirigami.Dialog.NoButton
        customFooterActions: [
            Kirigami.Action {
                text: i18nc("@action:button", "Delete Theme")
                icon.name: "edit-delete"
                onTriggered: removeThemeDialog.accept()
            },
            Kirigami.Action {
                text: i18nc("@action:button", "Cancel")
                icon.name: "dialog-cancel"
                onTriggered: removeThemeDialog.reject()
            }
        ]
        onAccepted: page.removePendingTheme()
        onRejected: {
            page.pendingThemeRemovalId = ""
            page.pendingThemeRemovalName = ""
            page.pendingThemeRemovalIndex = -1
        }
    }
    // qmllint enable unqualified

    StackLayout {
        id: appearanceStack
        width: page.width
        currentIndex: appearanceTabs.currentIndex
        implicitHeight: currentIndex === 0
            ? dockAppearanceForm.implicitHeight
            : (currentIndex === 1
                ? popupAppearancePage.implicitHeight
                : (currentIndex === 2
                    ? folderPopupPage.implicitHeight
                    : (currentIndex === 3
                        ? menuAppearancePage.implicitHeight
                        : audioVisualizerPage.implicitHeight)))

        Kirigami.FormLayout {
            id: dockAppearanceForm
            Layout.fillWidth: true

        // qmllint disable unqualified
        SectionTitle {
            Kirigami.FormData.isSection: true
            visible: !page.inPanel
            text: i18n("Dock background theme")
        }

        Kirigami.InlineMessage {
            visible: !page.inPanel
            type: Kirigami.MessageType.Information
            text: i18n("Imported themes are stored in the Punchi Dock Remastered user library and currently apply only to a floating dock. Plasma panels keep their native background.")
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background:")
            Layout.maximumWidth: page.contentWidthHint
            visible: !page.inPanel

            Controls.ComboBox {
                id: dockThemeModeCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.dockThemeModeOptions
                onActivated: {
                    if (page.cfg_dockThemeMode !== currentValue) {
                        page.cfg_dockThemeMode = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Installed theme:")
            Layout.maximumWidth: page.contentWidthHint
            visible: !page.inPanel && page.cfg_dockThemeMode === "custom"

            Controls.ComboBox {
                id: dockThemeLibraryCombo
                Layout.preferredWidth: Math.max(160,
                    page.selectorWidthHint - importThemeButton.implicitWidth
                    - removeThemeButton.implicitWidth
                    - (Kirigami.Units.smallSpacing * 2)
                )
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "displayName"
                valueRole: "id"
                model: dockThemeRepository.availableThemes
                enabled: count > 0
                displayText: currentIndex >= 0
                    ? currentText
                    : count > 0
                        ? i18n("Select a theme")
                        : i18n("No imported themes")
                Accessible.name: i18n("Installed Punchi Dock theme")
                onActivated: {
                    if (page.cfg_dockThemeCustomId !== currentValue) {
                        page.cfg_dockThemeCustomId = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }

            Controls.Button {
                id: importThemeButton
                text: i18n("Import…")
                icon.name: "list-add"
                Accessible.name: i18n("Import Punchi Dock JSON themes")
                Accessible.description: i18n("Choose whether to import one JSON theme or all JSON themes from a folder.")
                onClicked: importThemeMenu.popup(
                    importThemeButton, 0, importThemeButton.height)

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }

            Controls.Button {
                id: removeThemeButton
                text: i18nc("@action:button", "Delete")
                icon.name: "edit-delete-symbolic"
                display: Controls.AbstractButton.IconOnly
                enabled: dockThemeLibraryCombo.currentIndex >= 0
                    && String(dockThemeLibraryCombo.currentValue || "").length > 0
                Accessible.name: i18n("Delete the selected installed Punchi Dock theme")
                onClicked: page.requestSelectedThemeRemoval()

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: text

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            visible: !page.inPanel
                && page.cfg_dockThemeMode === "custom"
                && dockThemeRepository.availableThemes.length === 0
            text: i18n("Import a JSON theme to add it to your Punchi Dock Remastered library.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        Kirigami.InlineMessage {
            visible: !page.inPanel
                && page.cfg_dockThemeMode === "custom"
                && dockThemeRepository.errorCode.length > 0
            type: Kirigami.MessageType.Error
            text: page.dockThemeErrorText(dockThemeRepository.errorCode)
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
        }

        Kirigami.InlineMessage {
            visible: !page.inPanel
                && page.cfg_dockThemeMode === "custom"
                && page.lastThemeDirectoryImport.candidateCount !== undefined
            type: page.lastThemeDirectoryImport.candidateCount === 0
                ? Kirigami.MessageType.Information
                : (page.lastThemeDirectoryImport.rejectedCount > 0
                    || page.lastThemeDirectoryImport.truncatedCount > 0)
                    ? Kirigami.MessageType.Warning
                    : Kirigami.MessageType.Positive
            text: page.themeDirectoryImportText(page.lastThemeDirectoryImport)
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
        }

        Kirigami.InlineMessage {
            visible: !page.inPanel
                && page.themeRemovalMessage.length > 0
            type: Kirigami.MessageType.Positive
            text: page.themeRemovalMessage
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
        }
        // qmllint enable unqualified

        // qmllint disable unqualified
        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Item highlight")
        }

        Controls.CheckBox {
            id: showItemHoverBackgroundCheck
            Kirigami.FormData.label: i18n("Hover background:")
            text: i18n("Show a themed background behind items")
            Accessible.description: i18n("Shows the Plasma highlight background when an item is hovered or its application is active.")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: i18n("Window indicators remain visible when the item background is hidden.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }
        // qmllint enable unqualified

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Labels")
        }

        Controls.CheckBox {
            id: showLabelsCheck
            Kirigami.FormData.label: i18n("Labels:")
            text: i18n("Show item names in the dock")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: i18n("Labels use a compact single-line style so the dock can remain readable without turning every item into a large card.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Icon reflections")
        }

        Controls.CheckBox {
            id: iconReflectionsCheck
            enabled: page.iconReflectionsSupported && !showLabelsCheck.checked
            Kirigami.FormData.label: i18n("Reflection:")
            text: i18n("Show reflections below dock items")
            // qmllint disable unqualified
            Accessible.description: !page.iconReflectionsSupported
                ? i18n("Icon reflections are unavailable in vertical panels.")
                : (page.inPanel
                    ? i18n("Adds an adaptive decorative reflection below icons in a horizontal panel.")
                    : i18n("Adds a short decorative reflection below icons in a floating dock."))
            // qmllint enable unqualified

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        // qmllint disable unqualified
        RowLayout {
            enabled: iconReflectionsCheck.checked
                && page.iconReflectionsSupported
                && !showLabelsCheck.checked
            Kirigami.FormData.label: i18n("Reflection opacity:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: iconReflectionOpacitySlider
                from: 5
                to: 50
                stepSize: 1
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Reflection opacity")
                Accessible.description: i18n("Adjusts how strongly icon reflections appear.")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: Math.round(iconReflectionOpacitySlider.value) + "%"
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }
        // qmllint enable unqualified

        Controls.Label {
            // qmllint disable unqualified
            text: page.inPanel && !page.horizontalPanel
                ? i18n("Icon reflections are not available in vertical panels.")
                : (showLabelsCheck.checked
                    ? i18n("Hide item names to use icon reflections.")
                    : (page.inPanel
                        ? i18n("The reflection adapts to the available panel thickness and is hidden when there is not enough space.")
                        : i18n("The reflection is decorative and does not change the size or interaction area of dock items.")))
            // qmllint enable unqualified
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Indicator")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator shape:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: indicatorTypeCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.indicatorTypeOptions
                onActivated: {
                    if (page.cfg_indicatorType !== currentValue) {
                        page.cfg_indicatorType = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            text: page.cfg_indicatorType === "none"
                ? i18n("Disables the active-window indicator entirely.")
                : page.cfg_indicatorType === "ring"
                    ? i18n("The ring surrounds the icon, so it does not use a top or bottom position.")
                    : i18n("Line, dot and rounded square can be placed at the top or bottom edge of the icon.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator position:")
            Layout.maximumWidth: page.contentWidthHint
            visible: page.indicatorPositionApplicable

            Controls.ComboBox {
                id: indicatorPositionCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.indicatorPositionOptions
                onActivated: {
                    if (page.cfg_indicatorPosition !== currentValue) {
                        page.cfg_indicatorPosition = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            visible: !page.indicatorPositionApplicable
            text: i18n("Position is not used with the current indicator shape.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator opacity:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: indicatorOpacitySlider
                from: 0
                to: 100
                stepSize: 5
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: Math.round(indicatorOpacitySlider.value) + "%"
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator size:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: indicatorThicknessSlider
                from: 2
                to: 10
                stepSize: 1
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: Math.round(indicatorThicknessSlider.value) + " px"
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }
        }

        ConfigPopups {
            id: popupAppearancePage
            Layout.fillWidth: true
        }

        ConfigFolderPopups {
            id: folderPopupPage
            Layout.fillWidth: true
        }

        ConfigMenus {
            id: menuAppearancePage
            Layout.fillWidth: true
        }

        ConfigAudioVisualizer {
            id: audioVisualizerPage
            Layout.fillWidth: true
        }
    }
}
