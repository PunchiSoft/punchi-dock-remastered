import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
Controls.Dialog {
    id: root

    property string menuMode: "normal"
    property string normalPlacementMode: "anchored"
    property int gridIconScalePercent: 100
    property int favoriteIconScalePercent: 100
    property bool showDistributionName: true
    property int normalWidthPercent: 55
    property int normalHeightPercent: 65
    property real selectorWidth: Kirigami.Units.gridUnit * 16
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

    signal menuModeSelected(string mode)
    signal normalPlacementModeSelected(string mode)
    signal gridIconScalePercentSelected(int percent)
    signal favoriteIconScalePercentSelected(int percent)
    signal showDistributionNameSelected(bool enabled)
    signal normalSizePercentSelected(int widthPercent, int heightPercent)

    readonly property bool normalModeSelected: root.menuMode === "normal"

    function modeIndex(mode) {
        for (let index = 0; index < modeOptions.length; index++) {
            if (modeOptions[index].value === mode) {
                return index
            }
        }
        return 0
    }

    function normalPlacementIndex(mode) {
        for (let index = 0; index < normalPlacementOptions.length; index++) {
            if (normalPlacementOptions[index].value === mode) {
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
        normalPlacementCombo.currentIndex = root.normalPlacementIndex(
            root.normalPlacementMode)
        iconScaleSlider.value = root.gridIconScalePercent
        favoriteIconScaleSlider.value = root.favoriteIconScalePercent
        normalWidthSlider.value = root.normalWidthPercent
        normalHeightSlider.value = root.normalHeightPercent
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

        Controls.Switch {
            id: distributionNameSwitch

            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            visible: !root.normalModeSelected
            text: i18n("Show distribution name in full screen")
            checked: root.showDistributionName
            onClicked: {
                root.showDistributionName = checked
                root.showDistributionNameSelected(checked)
            }
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
                to: 200
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
            text: i18n("Favorites icon scale:")
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: root.selectorWidth
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: favoriteIconScaleSlider

                Layout.fillWidth: true
                from: 75
                to: 150
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                value: 100
                Accessible.name: i18n("PunchiMenu Favorites icon scale")
                Accessible.description: i18n("Changes the icon size in the reserved Favorites section in both menu modes.")

                onMoved: {
                    const normalizedPercent = Math.round(value / stepSize) * stepSize
                    root.favoriteIconScalePercent = normalizedPercent
                    root.favoriteIconScalePercentSelected(normalizedPercent)
                }
                onValueChanged: {
                    if (activeFocus && !pressed) {
                        const normalizedPercent = Math.round(value / stepSize) * stepSize
                        if (normalizedPercent !== root.favoriteIconScalePercent) {
                            root.favoriteIconScalePercent = normalizedPercent
                            root.favoriteIconScalePercentSelected(normalizedPercent)
                        }
                    }
                }
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                horizontalAlignment: Text.AlignRight
                text: i18n("%1%", Math.round(favoriteIconScaleSlider.value))
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            visible: root.normalModeSelected
            text: i18n("Normal menu placement:")
            wrapMode: Text.WordWrap
        }

        Controls.ComboBox {
            id: normalPlacementCombo

            Layout.fillWidth: true
            Layout.preferredWidth: root.selectorWidth
            Layout.maximumWidth: root.selectorWidth
            visible: root.normalModeSelected
            model: root.normalPlacementOptions
            textRole: "text"
            Accessible.name: i18n("Normal menu placement")

            onActivated: function(index) {
                const option = root.normalPlacementOptions[index]
                if (!option) {
                    currentIndex = root.normalPlacementIndex(
                        root.normalPlacementMode)
                    return
                }
                root.normalPlacementMode = String(option.value)
                root.normalPlacementModeSelected(root.normalPlacementMode)
            }
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

    }
}
// qmllint enable unqualified
