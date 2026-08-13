import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
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
    property string iconName: "start-here-kde"

    readonly property bool hasPunchiMenu: punchiMenuIndex >= 0
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
