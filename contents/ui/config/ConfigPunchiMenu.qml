import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.config as KConfig
import org.kde.iconthemes as KIconThemes
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import org.kde.plasma.plasmoid
import "code/configItems.js" as ConfigItemsJS
import "code/items.js" as ItemsJS
import "components"

// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
KCM.SimpleKCM {
    id: page

    title: i18n("PunchiMenu")
    implicitWidth: layoutMetrics.pageImplicitWidth
    implicitHeight: contentColumn.implicitHeight

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    property string cfg_dockItemsJson: ""
    property string cfg_punchiMenuShortcut: ""

    property bool updatingDockItemsJson: false
    property bool updatingShortcut: false
    property int punchiMenuIndex: -1
    property string menuMode: "normal"
    property string normalPlacementMode: "anchored"
    property int gridIconScalePercent: 100
    property int favoriteIconScalePercent: 100
    property int normalFolderMaximumColumns: 3
    property int normalFolderMaximumRows: 3
    property int fullScreenFolderMaximumColumns: 5
    property int fullScreenFolderMaximumRows: 5
    property bool showDistributionName: true
    property bool showPageNavigationArrows: true
    property bool sortApplicationsAlphabetically: false
    property string fullScreenCloseButtonPosition: "right"
    property bool fullScreenBlurEnabled: true
    property int fullScreenBackgroundOpacityPercent: 50
    property bool normalBlurEnabled: true
    property int normalBackgroundOpacityPercent: 75
    property int normalWidthPercent: 55
    property int normalHeightPercent: 65
    property int normalPanelGap: 8
    property string iconName: "start-here-kde"

    readonly property bool hasPunchiMenu: punchiMenuIndex >= 0
    readonly property bool normalModeSelected: menuMode === "normal"
    readonly property bool anchoredNormalModeSelected:
        normalModeSelected && normalPlacementMode === "anchored"
    readonly property bool selectedBlurEnabled: normalModeSelected
        ? normalBlurEnabled
        : fullScreenBlurEnabled
    readonly property int selectedBackgroundOpacityPercent: normalModeSelected
        ? normalBackgroundOpacityPercent
        : fullScreenBackgroundOpacityPercent
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    readonly property bool interactiveCursorEnabled:
        !!Plasmoid.configuration.globalMouseCursor

    readonly property var modeOptions: [
        {
            "text": i18nc("@option:punchimenu-mode", "PunchiMenu Full screen"),
            "value": "fullScreen"
        },
        {
            "text": i18nc("@option:punchimenu-mode", "PunchiMenu Normal"),
            "value": "normal"
        }
    ]
    readonly property var normalPlacementOptions: [
        {
            "text": i18nc("@option:punchimenu-placement", "Attached to dock or panel"),
            "value": "anchored"
        },
        {
            "text": i18nc("@option:punchimenu-placement", "Centered on desktop"),
            "value": "centered"
        }
    ]
    readonly property var fullScreenCloseButtonPositionOptions: [
        {
            "text": i18nc("@option:close-button-position", "Right"),
            "value": "right"
        },
        {
            "text": i18nc("@option:close-button-position", "Left"),
            "value": "left"
        }
    ]

    function optionIndex(options, value) {
        for (let index = 0; index < options.length; index++) {
            if (String(options[index].value) === String(value)) {
                return index
            }
        }
        return 0
    }

    function findPunchiMenuIndex(items) {
        for (let index = 0; index < items.length; index++) {
            if (items[index] && items[index].type === "punchimenu") {
                return index
            }
        }
        return -1
    }

    function effectiveDockItemsJson() {
        const configuredJson = String(cfg_dockItemsJson || "")
        return configuredJson.trim().length > 0
            ? configuredJson
            : ItemsJS.defaultJson()
    }

    function syncFromItem(item) {
        menuMode = ConfigItemsJS.normalizedPunchiMenuMode(item.menuMode)
        normalPlacementMode =
            ConfigItemsJS.normalizedPunchiMenuNormalPlacementMode(
                item.normalPlacementMode)
        gridIconScalePercent =
            ConfigItemsJS.normalizedPunchiMenuGridIconScalePercent(
                item.gridIconScalePercent)
        favoriteIconScalePercent =
            ConfigItemsJS.normalizedPunchiMenuFavoriteIconScalePercent(
                item.favoriteIconScalePercent)
        normalFolderMaximumColumns =
            ConfigItemsJS.normalizedPunchiMenuNormalFolderMaximumColumns(
                item.normalFolderMaximumColumns)
        normalFolderMaximumRows =
            ConfigItemsJS.normalizedPunchiMenuNormalFolderMaximumRows(
                item.normalFolderMaximumRows)
        fullScreenFolderMaximumColumns =
            ConfigItemsJS.normalizedPunchiMenuFullScreenFolderMaximumColumns(
                item.fullScreenFolderMaximumColumns)
        fullScreenFolderMaximumRows =
            ConfigItemsJS.normalizedPunchiMenuFullScreenFolderMaximumRows(
                item.fullScreenFolderMaximumRows)
        showDistributionName = item.showDistributionName !== false
        showPageNavigationArrows = item.showPageNavigationArrows !== false
        sortApplicationsAlphabetically =
            item.sortApplicationsAlphabetically === true
        fullScreenCloseButtonPosition =
            ConfigItemsJS.normalizedPunchiMenuFullScreenCloseButtonPosition(
                item.fullScreenCloseButtonPosition)
        fullScreenBlurEnabled = item.fullScreenBlurEnabled !== false
        fullScreenBackgroundOpacityPercent =
            ConfigItemsJS.normalizedPunchiMenuFullScreenBackgroundOpacityPercent(
                item.fullScreenBackgroundOpacityPercent)
        normalBlurEnabled = item.normalBlurEnabled !== false
        normalBackgroundOpacityPercent =
            ConfigItemsJS.normalizedPunchiMenuNormalBackgroundOpacityPercent(
                item.normalBackgroundOpacityPercent)
        normalWidthPercent =
            ConfigItemsJS.normalizedPunchiMenuNormalWidthPercent(
                item.normalWidthPercent)
        normalHeightPercent =
            ConfigItemsJS.normalizedPunchiMenuNormalHeightPercent(
                item.normalHeightPercent)
        normalPanelGap = ConfigItemsJS.normalizedPunchiMenuNormalPanelGap(
            item.normalPanelGap)
        iconName = ConfigItemsJS.normalizedPunchiMenuIcon(item.icon)
    }

    function reloadFromConfiguration() {
        let parsed
        try {
            parsed = ConfigItemsJS.parseJsonArray(effectiveDockItemsJson())
        } catch (error) {
            punchiMenuIndex = -1
            return
        }
        if (!parsed.ok) {
            punchiMenuIndex = -1
            return
        }

        punchiMenuIndex = findPunchiMenuIndex(parsed.items)
        if (punchiMenuIndex >= 0) {
            syncFromItem(parsed.items[punchiMenuIndex])
        }
    }

    function setPunchiMenuValue(fieldName, value) {
        let parsed
        try {
            parsed = ConfigItemsJS.parseJsonArray(effectiveDockItemsJson())
        } catch (error) {
            return
        }
        if (!parsed.ok) {
            return
        }

        const index = findPunchiMenuIndex(parsed.items)
        if (index < 0) {
            punchiMenuIndex = -1
            return
        }

        const item = parsed.items[index]
        item[fieldName] = value
        ConfigItemsJS.prunePunchiMenu(item)
        syncFromItem(item)
        punchiMenuIndex = index

        updatingDockItemsJson = true
        cfg_dockItemsJson = JSON.stringify(parsed.items, null, 4)
        updatingDockItemsJson = false
    }

    function setSelectedBlurEnabled(enabled) {
        setPunchiMenuValue(normalModeSelected
            ? "normalBlurEnabled"
            : "fullScreenBlurEnabled", enabled)
    }

    function setSelectedBackgroundOpacityPercent(percent) {
        const normalizedPercent = normalModeSelected
            ? ConfigItemsJS.normalizedPunchiMenuNormalBackgroundOpacityPercent(percent)
            : ConfigItemsJS.normalizedPunchiMenuFullScreenBackgroundOpacityPercent(percent)
        setPunchiMenuValue(normalModeSelected
            ? "normalBackgroundOpacityPercent"
            : "fullScreenBackgroundOpacityPercent", normalizedPercent)
    }

    function syncShortcutControl() {
        updatingShortcut = true
        shortcutItem.keySequence = cfg_punchiMenuShortcut
        updatingShortcut = false
    }

    onCfg_dockItemsJsonChanged: {
        if (!updatingDockItemsJson) {
            reloadFromConfiguration()
        }
    }
    onCfg_punchiMenuShortcutChanged: syncShortcutControl()

    Component.onCompleted: {
        reloadFromConfiguration()
        syncShortcutControl()
    }

    KIconThemes.IconDialog {
        id: iconPicker
        title: i18n("Choose icon")
        iconSize: 48
        modality: Qt.WindowModal
        onAccepted: page.setPunchiMenuValue("icon", iconName)
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 0

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            visible: !page.hasPunchiMenu
            type: Kirigami.MessageType.Information
            text: i18n("Add a PunchiMenu item from the Items page to configure it here.")
        }

        Kirigami.FormLayout {
            id: punchiMenuForm
            Layout.fillWidth: true
            visible: page.hasPunchiMenu

            Kirigami.Heading {
                Kirigami.FormData.isSection: true
                level: 3
                text: i18n("Mode and appearance")
            }

            Controls.ComboBox {
                id: modeCombo
                Kirigami.FormData.label: i18n("Menu mode:")
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                model: page.modeOptions
                textRole: "text"
                currentIndex: page.optionIndex(page.modeOptions, page.menuMode)
                Accessible.name: i18n("PunchiMenu display mode")
                onActivated: function(index) {
                    const option = page.modeOptions[index]
                    if (option) {
                        page.setPunchiMenuValue("menuMode", option.value)
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "comboBox"
                }
            }

            Kirigami.Heading {
                Kirigami.FormData.isSection: true
                level: 3
                text: i18n("Background and legibility")
            }

            Controls.Switch {
                id: backgroundBlurSwitch
                Kirigami.FormData.label: i18n("Background blur:")
                text: i18n("Use background blur when available")
                checked: page.selectedBlurEnabled
                Accessible.name: text
                Accessible.description: i18n("Requests the desktop blur effect for the selected PunchiMenu mode.")
                onClicked: page.setSelectedBlurEnabled(checked)

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "button"
                }
            }

            Kirigami.InlineMessage {
                Kirigami.FormData.isSection: true
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                visible: true
                type: Kirigami.MessageType.Information
                text: page.selectedBlurEnabled
                    ? i18n("The background will use KWin blur when available. The selected opacity controls how much content behind the menu remains visible.")
                    : i18n("Without blur, the background depends on the Plasma theme and the selected opacity.")
                Accessible.name: text
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Background opacity:")
                Layout.maximumWidth: page.contentWidthHint

                Controls.Slider {
                    id: backgroundOpacitySlider
                    Layout.fillWidth: true
                    Layout.preferredWidth: page.contentWidthHint
                        - Kirigami.Units.gridUnit * 4
                    from: 50
                    to: 100
                    stepSize: 5
                    snapMode: Controls.Slider.SnapAlways
                    value: page.selectedBackgroundOpacityPercent
                    Accessible.name: i18n("PunchiMenu background opacity")
                    Accessible.description: i18n("Changes only the menu background opacity; text and icons remain fully opaque.")
                    onMoved: page.setSelectedBackgroundOpacityPercent(value)
                    onValueChanged: {
                        if (activeFocus && !pressed) {
                            page.setSelectedBackgroundOpacityPercent(value)
                        }
                    }

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                        role: "slider"
                    }
                }

                Controls.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    horizontalAlignment: Text.AlignRight
                    text: i18n("%1%", Math.round(backgroundOpacitySlider.value))
                }
            }

            Kirigami.InlineMessage {
                Kirigami.FormData.isSection: true
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                visible: page.selectedBackgroundOpacityPercent < 70
                type: Kirigami.MessageType.Warning
                text: i18n("Low background opacity can make text and icons difficult to read when desktop blur is unavailable.")
            }

            Controls.Button {
                Kirigami.FormData.isSection: true
                Layout.alignment: Qt.AlignRight
                visible: KConfig.KAuthorized.authorizeControlModule(
                    "kcm_kwin_effects")
                icon.name: "configure"
                text: i18nc("@action:button opens system settings",
                    "Configure Desktop Effects…")
                Accessible.name: text
                onClicked: KCM.KCMLauncher.openSystemSettings(
                    "kcm_kwin_effects")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "button"
                }
            }

            Controls.Switch {
                Kirigami.FormData.label: i18n("Application order:")
                text: i18n("Sort applications alphabetically")
                checked: page.sortApplicationsAlphabetically
                Accessible.name: text
                Accessible.description: i18n("Keeps drag and drop available, but prevents manual reordering while alphabetical sorting is enabled.")
                onClicked: page.setPunchiMenuValue(
                    "sortApplicationsAlphabetically", checked)

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "button"
                }
            }

            Kirigami.InlineMessage {
                Kirigami.FormData.isSection: true
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                visible: page.sortApplicationsAlphabetically
                type: Kirigami.MessageType.Information
                text: i18n("Alphabetical sorting is active. Application positions cannot be changed manually, but drag and drop remains available.")
                Accessible.name: text
            }

            Controls.Switch {
                Kirigami.FormData.label: i18n("Distribution label:")
                visible: !page.normalModeSelected
                text: i18n("Show distribution name in full screen")
                checked: page.showDistributionName
                onClicked: page.setPunchiMenuValue(
                    "showDistributionName", checked)
            }

            Controls.Switch {
                Kirigami.FormData.label: i18n("Page navigation:")
                visible: !page.normalModeSelected
                text: i18n("Show page navigation arrows")
                checked: page.showPageNavigationArrows
                Accessible.name: text
                onClicked: page.setPunchiMenuValue(
                    "showPageNavigationArrows", checked)

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "button"
                }
            }

            Controls.ComboBox {
                Kirigami.FormData.label: i18n("Close button:")
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                visible: !page.normalModeSelected
                model: page.fullScreenCloseButtonPositionOptions
                textRole: "text"
                valueRole: "value"
                currentIndex: page.optionIndex(
                    page.fullScreenCloseButtonPositionOptions,
                    page.fullScreenCloseButtonPosition)
                Accessible.name: i18n("Close button position")
                onActivated: function(index) {
                    page.setPunchiMenuValue("fullScreenCloseButtonPosition",
                        page.fullScreenCloseButtonPositionOptions[index].value)
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "button"
                }
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Application grid icon scale:")
                Layout.maximumWidth: page.contentWidthHint

                Controls.Slider {
                    id: iconScaleSlider
                    Layout.fillWidth: true
                    Layout.preferredWidth: page.contentWidthHint
                        - Kirigami.Units.gridUnit * 4
                    from: 75
                    to: 150
                    stepSize: 5
                    snapMode: Controls.Slider.SnapAlways
                    value: page.gridIconScalePercent
                    Accessible.name: i18n("PunchiMenu application icon scale")
                    onMoved: page.setPunchiMenuValue(
                        "gridIconScalePercent", Math.round(value / stepSize) * stepSize)
                    onValueChanged: {
                        if (activeFocus && !pressed) {
                            page.setPunchiMenuValue("gridIconScalePercent",
                                Math.round(value / stepSize) * stepSize)
                        }
                    }

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                        role: "slider"
                    }
                }

                Controls.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    horizontalAlignment: Text.AlignRight
                    text: i18n("%1%", Math.round(iconScaleSlider.value))
                }
            }

            Controls.Label {
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                leftPadding: layoutMetrics.helperIndent
                text: i18n("The effective size adapts to the screen and available grid cell space.")
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.disabledTextColor
            }

            Controls.SpinBox {
                id: folderMaximumColumnsSpin
                Kirigami.FormData.label: i18n("Maximum folder columns:")
                from: 1
                to: page.normalModeSelected ? 3 : 5
                value: page.normalModeSelected
                    ? page.normalFolderMaximumColumns
                    : page.fullScreenFolderMaximumColumns
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                Accessible.name: i18n("Maximum application columns inside folders")
                Accessible.description: i18n("Sets an upper limit for columns inside folders in the selected menu mode. Available space may use fewer columns.")
                onValueModified: page.setPunchiMenuValue(
                    page.normalModeSelected
                        ? "normalFolderMaximumColumns"
                        : "fullScreenFolderMaximumColumns",
                    value)

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }

            Controls.SpinBox {
                id: folderMaximumRowsSpin
                Kirigami.FormData.label: i18n("Maximum folder rows:")
                from: 1
                to: page.normalModeSelected ? 3 : 5
                value: page.normalModeSelected
                    ? page.normalFolderMaximumRows
                    : page.fullScreenFolderMaximumRows
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                Accessible.name: i18n("Maximum application rows inside folders")
                Accessible.description: i18n("Limits the visible rows inside folders in the selected menu mode. Additional applications remain available by scrolling.")
                onValueModified: page.setPunchiMenuValue(
                    page.normalModeSelected
                        ? "normalFolderMaximumRows"
                        : "fullScreenFolderMaximumRows",
                    value)

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }

            Controls.Label {
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                leftPadding: layoutMetrics.helperIndent
                text: i18n("The menu reduces columns when the available width is insufficient and uses scrolling when content exceeds the selected row limit.")
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.disabledTextColor
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Favorites icon scale:")
                Layout.maximumWidth: page.contentWidthHint

                Controls.Slider {
                    id: favoriteIconScaleSlider
                    Layout.fillWidth: true
                    Layout.preferredWidth: page.contentWidthHint
                        - Kirigami.Units.gridUnit * 4
                    from: 75
                    to: 110
                    stepSize: 5
                    snapMode: Controls.Slider.SnapAlways
                    value: page.favoriteIconScalePercent
                    Accessible.name: i18n("PunchiMenu Favorites icon scale")
                    Accessible.description: i18n("Changes the icon size in the reserved Favorites section in both menu modes.")
                    onMoved: page.setPunchiMenuValue(
                        "favoriteIconScalePercent",
                        Math.round(value / stepSize) * stepSize)
                    onValueChanged: {
                        if (activeFocus && !pressed) {
                            page.setPunchiMenuValue(
                                "favoriteIconScalePercent",
                                Math.round(value / stepSize) * stepSize)
                        }
                    }

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                        role: "slider"
                    }
                }

                Controls.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    horizontalAlignment: Text.AlignRight
                    text: i18n("%1%", Math.round(favoriteIconScaleSlider.value))
                }
            }

            Controls.Label {
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                leftPadding: layoutMetrics.helperIndent
                text: i18n("The safe range applies to the reserved Favorites section in both menu modes.")
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.disabledTextColor
            }

            Kirigami.Heading {
                Kirigami.FormData.isSection: true
                visible: page.normalModeSelected
                level: 3
                text: i18n("Location and spacing")
            }

            Controls.ComboBox {
                id: placementCombo
                Kirigami.FormData.label: i18n("Normal menu placement:")
                visible: page.normalModeSelected
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                model: page.normalPlacementOptions
                textRole: "text"
                currentIndex: page.optionIndex(page.normalPlacementOptions,
                    page.normalPlacementMode)
                Accessible.name: i18n("Normal menu placement")
                onActivated: function(index) {
                    const option = page.normalPlacementOptions[index]
                    if (option) {
                        page.setPunchiMenuValue(
                            "normalPlacementMode", option.value)
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "comboBox"
                }
            }

            Controls.Label {
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                visible: page.normalModeSelected
                leftPadding: layoutMetrics.helperIndent
                text: i18n("Attached keeps the menu next to its dock or panel. Centered uses the available area of the active screen.")
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.disabledTextColor
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Panel distance:")
                visible: page.anchoredNormalModeSelected
                Layout.maximumWidth: page.contentWidthHint

                Controls.Slider {
                    id: panelGapSlider
                    Layout.fillWidth: true
                    Layout.preferredWidth: page.contentWidthHint
                        - Kirigami.Units.gridUnit * 4
                    from: 0
                    to: 32
                    stepSize: 1
                    snapMode: Controls.Slider.SnapAlways
                    value: page.normalPanelGap
                    Accessible.name: i18n("PunchiMenu panel distance")
                    Accessible.description: i18n("Adds space between PunchiMenu Normal and the panel edge.")
                    onMoved: page.setPunchiMenuValue(
                        "normalPanelGap", Math.round(value))
                    onValueChanged: {
                        if (activeFocus && !pressed) {
                            page.setPunchiMenuValue(
                                "normalPanelGap", Math.round(value))
                        }
                    }

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                        role: "slider"
                    }
                }

                Controls.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    horizontalAlignment: Text.AlignRight
                    text: i18n("%1 px", Math.round(panelGapSlider.value))
                }
            }

            Controls.Label {
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                visible: page.anchoredNormalModeSelected
                leftPadding: layoutMetrics.helperIndent
                text: i18n("This distance is added after the panel thickness detected by Plasma.")
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.disabledTextColor
            }

            Kirigami.Heading {
                Kirigami.FormData.isSection: true
                visible: page.normalModeSelected
                level: 3
                text: i18n("Normal menu size")
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Normal menu width:")
                visible: page.normalModeSelected
                Layout.maximumWidth: page.contentWidthHint

                Controls.Slider {
                    id: widthSlider
                    Layout.fillWidth: true
                    Layout.preferredWidth: page.contentWidthHint
                        - Kirigami.Units.gridUnit * 4
                    from: 30
                    to: 90
                    stepSize: 5
                    snapMode: Controls.Slider.SnapAlways
                    value: page.normalWidthPercent
                    Accessible.name: i18n("Normal menu width")
                    onMoved: page.setPunchiMenuValue(
                        "normalWidthPercent", Math.round(value / stepSize) * stepSize)
                    onValueChanged: {
                        if (activeFocus && !pressed) {
                            page.setPunchiMenuValue("normalWidthPercent",
                                Math.round(value / stepSize) * stepSize)
                        }
                    }

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                        role: "slider"
                    }
                }

                Controls.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    horizontalAlignment: Text.AlignRight
                    text: i18n("%1%", Math.round(widthSlider.value))
                }
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Normal menu height:")
                visible: page.normalModeSelected
                Layout.maximumWidth: page.contentWidthHint

                Controls.Slider {
                    id: heightSlider
                    Layout.fillWidth: true
                    Layout.preferredWidth: page.contentWidthHint
                        - Kirigami.Units.gridUnit * 4
                    from: 30
                    to: 90
                    stepSize: 5
                    snapMode: Controls.Slider.SnapAlways
                    value: page.normalHeightPercent
                    Accessible.name: i18n("Normal menu height")
                    onMoved: page.setPunchiMenuValue(
                        "normalHeightPercent", Math.round(value / stepSize) * stepSize)
                    onValueChanged: {
                        if (activeFocus && !pressed) {
                            page.setPunchiMenuValue("normalHeightPercent",
                                Math.round(value / stepSize) * stepSize)
                        }
                    }

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                        role: "slider"
                    }
                }

                Controls.Label {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    horizontalAlignment: Text.AlignRight
                    text: i18n("%1%", Math.round(heightSlider.value))
                }
            }

            Controls.Label {
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                visible: page.normalModeSelected
                leftPadding: layoutMetrics.helperIndent
                text: i18n("The percentages adjust the menu size relative to your screen width and height (from 30% to 90%).")
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.disabledTextColor
            }

            Kirigami.Heading {
                Kirigami.FormData.isSection: true
                level: 3
                text: i18n("Icon and shortcut")
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Icon and keyboard shortcut:")
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                spacing: Kirigami.Units.smallSpacing

                Controls.Button {
                    icon.name: page.iconName
                    display: Controls.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Choose PunchiMenu icon")
                    Accessible.name: text
                    Accessible.description: i18nc("@info:accessibility",
                        "Current icon: %1", page.iconName)
                    onClicked: iconPicker.open()

                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.text: text

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                        role: "button"
                    }
                }

                KQuickControls.KeySequenceItem {
                    id: shortcutItem
                    Layout.fillWidth: true
                    showCancelButton: true
                    // Keep the Plasma 6.0-compatible properties. ShortcutPattern was
                    // introduced in a later KF6 release.
                    // qmllint disable deprecated
                    modifierOnlyAllowed: true
                    modifierlessAllowed: false
                    // qmllint enable deprecated
                    Accessible.name: i18n("PunchiMenu keyboard shortcut")
                    onKeySequenceModified: {
                        if (!page.updatingShortcut) {
                            // QKeySequence exposes toString() at runtime, but the Qt
                            // QML metadata does not advertise the method to qmllint.
                            // qmllint disable missing-property
                            page.cfg_punchiMenuShortcut = keySequence.toString()
                            // qmllint enable missing-property
                        }
                    }
                }
            }
        }
    }
}
// qmllint enable unqualified
