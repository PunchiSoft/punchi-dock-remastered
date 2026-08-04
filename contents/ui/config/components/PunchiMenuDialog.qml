import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls

// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
Controls.Dialog {
    id: root

    property string menuMode: "normal"
    property int gridIconScalePercent: 100
    property int normalWidthPercent: 55
    property int normalHeightPercent: 65
    property string iconName: defaultIconName
    property string shortcut: ""
    property real selectorWidth: Kirigami.Units.gridUnit * 16
    readonly property string defaultIconName: "start-here-kde"
    readonly property real pairedControlWidth: Math.max(root.selectorWidth,
        Math.min(root.width - Kirigami.Units.largeSpacing * 2,
            root.selectorWidth * 1.5))
    readonly property var modeOptions: [
        {
            "text": i18nc("@option:punchimenu-mode", "Full screen"),
            "value": "fullScreen",
            "available": true
        },
        {
            "text": i18nc("@option:punchimenu-mode", "Normal"),
            "value": "normal",
            "available": true
        },
        {
            "text": i18nc("@option:punchimenu-mode", "Compact (coming soon)"),
            "value": "compact",
            "available": false
        }
    ]

    signal menuModeSelected(string mode)
    signal gridIconScalePercentSelected(int percent)
    signal normalSizePercentSelected(int widthPercent, int heightPercent)
    signal iconPickerRequested()
    signal shortcutSelected(string shortcut)

    readonly property bool normalModeSelected: root.menuMode === "normal"

    function modeIndex(mode) {
        for (let index = 0; index < modeOptions.length; index++) {
            if (modeOptions[index].value === mode) {
                return index
            }
        }
        return 0
    }

    title: i18n("Configure PunchiMenu")
    modal: true
    standardButtons: Controls.Dialog.Close
    onOpened: {
        modeCombo.currentIndex = root.modeIndex(root.menuMode)
        iconScaleSlider.value = root.gridIconScalePercent
        normalWidthSlider.value = root.normalWidthPercent
        normalHeightSlider.value = root.normalHeightPercent
        shortcutItem.keySequence = root.shortcut
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            text: i18n("Menu mode:")
            wrapMode: Text.WordWrap
        }

        Controls.ComboBox {
            id: modeCombo

            Layout.fillWidth: true
            Layout.preferredWidth: root.selectorWidth
            Layout.maximumWidth: root.selectorWidth
            model: root.modeOptions
            textRole: "text"
            Accessible.name: i18n("PunchiMenu display mode")

            delegate: Controls.ItemDelegate {
                required property int index
                required property var modelData

                width: modeCombo.width
                text: String(modelData.text || "")
                enabled: modelData.available === true
                highlighted: modeCombo.highlightedIndex === index
            }

            onActivated: function(index) {
                const option = root.modeOptions[index]
                if (!option || option.available !== true) {
                    currentIndex = root.modeIndex(root.menuMode)
                    return
                }
                root.menuMode = String(option.value)
                root.menuModeSelected(root.menuMode)
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            text: i18n("Full screen and Normal are available. Compact will be enabled in a future update.")
            wrapMode: Text.WordWrap
            opacity: 0.75
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            text: i18n("Application grid icon scale:")
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: root.selectorWidth
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: iconScaleSlider

                Layout.fillWidth: true
                from: 75
                to: 150
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                value: 100
                Accessible.name: i18n("PunchiMenu application icon scale")

                onMoved: {
                    const normalizedPercent = Math.round(value / stepSize) * stepSize
                    root.gridIconScalePercent = normalizedPercent
                    root.gridIconScalePercentSelected(normalizedPercent)
                }
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                horizontalAlignment: Text.AlignRight
                text: i18n("%1%", Math.round(iconScaleSlider.value))
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            text: i18n("The effective size adapts to the screen and available grid cell space.")
            wrapMode: Text.WordWrap
            opacity: 0.75
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            visible: root.normalModeSelected
            text: i18n("Normal menu width:")
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: root.selectorWidth
            visible: root.normalModeSelected
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: normalWidthSlider

                Layout.fillWidth: true
                from: 30
                to: 90
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                value: 55
                Accessible.name: i18n("Normal menu width")
                onMoved: {
                    const normalizedPercent = Math.round(value / stepSize) * stepSize
                    root.normalWidthPercent = normalizedPercent
                    root.normalSizePercentSelected(normalizedPercent,
                        root.normalHeightPercent)
                }
                onValueChanged: {
                    if (activeFocus && !pressed) {
                        const normalizedPercent = Math.round(value / stepSize) * stepSize
                        if (normalizedPercent !== root.normalWidthPercent) {
                            root.normalWidthPercent = normalizedPercent
                            root.normalSizePercentSelected(normalizedPercent,
                                root.normalHeightPercent)
                        }
                    }
                }
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                horizontalAlignment: Text.AlignRight
                text: i18n("%1%", Math.round(normalWidthSlider.value))
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            visible: root.normalModeSelected
            text: i18n("Normal menu height:")
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: root.selectorWidth
            visible: root.normalModeSelected
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: normalHeightSlider

                Layout.fillWidth: true
                from: 30
                to: 90
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                value: 65
                Accessible.name: i18n("Normal menu height")
                onMoved: {
                    const normalizedPercent = Math.round(value / stepSize) * stepSize
                    root.normalHeightPercent = normalizedPercent
                    root.normalSizePercentSelected(root.normalWidthPercent,
                        normalizedPercent)
                }
                onValueChanged: {
                    if (activeFocus && !pressed) {
                        const normalizedPercent = Math.round(value / stepSize) * stepSize
                        if (normalizedPercent !== root.normalHeightPercent) {
                            root.normalHeightPercent = normalizedPercent
                            root.normalSizePercentSelected(root.normalWidthPercent,
                                normalizedPercent)
                        }
                    }
                }
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                horizontalAlignment: Text.AlignRight
                text: i18n("%1%", Math.round(normalHeightSlider.value))
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            visible: root.normalModeSelected
            text: i18n("The percentages adjust the menu size relative to your screen width and height (from 30% to 90%).")
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.disabledTextColor
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: root.pairedControlWidth
            Layout.maximumWidth: root.pairedControlWidth
            columns: 2
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            Controls.Label {
                Layout.fillWidth: true
                text: i18n("Icon:")
                wrapMode: Text.WordWrap
            }

            Controls.Label {
                Layout.fillWidth: true
                text: i18n("Keyboard shortcut:")
                wrapMode: Text.WordWrap
            }

            Controls.Button {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                icon.name: root.iconName.length > 0
                    ? root.iconName
                    : root.defaultIconName
                icon.source: root.iconName.length > 0
                    ? root.iconName
                    : root.defaultIconName
                display: Controls.AbstractButton.IconOnly
                Accessible.name: i18nc("@action:button", "Choose PunchiMenu icon")
                Accessible.description: i18nc("@info:accessibility", "Current icon: %1",
                    root.iconName.length > 0 ? root.iconName : root.defaultIconName)
                onClicked: root.iconPickerRequested()

                HoverHandler { cursorShape: Qt.PointingHandCursor }

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: Accessible.name
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
                    // QKeySequence exposes toString() at runtime, but the Qt QML
                    // metadata does not advertise the method to qmllint.
                    // qmllint disable missing-property
                    root.shortcutSelected(keySequence.toString())
                    // qmllint enable missing-property
                }
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            text: i18n("This shortcut controls PunchiMenu independently from the widget activation shortcut.")
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
// qmllint enable unqualified
