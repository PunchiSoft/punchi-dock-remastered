import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.config as KConfig
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
FocusScope {
    id: root

    property string menuMode: "fullScreen"
    required property bool backgroundBlurEnabled
    required property int backgroundOpacityPercent
    property bool showDistributionName: false
    property bool showPageNavigationArrows: false
    required property bool showApplicationLabels
    required property string hoverAnimation
    required property bool sortApplicationsAlphabetically
    property string closeButtonPosition: "right"
    required property int applicationIconScalePercent
    required property int favoriteIconScalePercent
    required property int folderMaximumColumns
    required property int folderMaximumRows
    property string normalPlacementMode: "anchored"
    property int normalPanelGap: 8
    property int normalWidthPercent: 55
    property int normalHeightPercent: 65
    property string errorMessage: ""

    signal settingChanged(string fieldName, var value)
    signal advancedConfigurationRequested()

    readonly property int contentMaximumWidth: Kirigami.Units.gridUnit * 40
    readonly property bool normalMode: menuMode === "normal"
    readonly property string blurSettingName: normalMode
        ? "normalBlurEnabled" : "fullScreenBlurEnabled"
    readonly property string opacitySettingName: normalMode
        ? "normalBackgroundOpacityPercent"
        : "fullScreenBackgroundOpacityPercent"
    readonly property string folderColumnsSettingName: normalMode
        ? "normalFolderMaximumColumns"
        : "fullScreenFolderMaximumColumns"
    readonly property string folderRowsSettingName: normalMode
        ? "normalFolderMaximumRows"
        : "fullScreenFolderMaximumRows"
    readonly property int folderMaximumLimit: normalMode ? 3 : 5
    readonly property bool anchoredNormalMode: normalMode
        && normalPlacementMode === "anchored"
    readonly property var closeButtonPositionOptions: [
        {
            "text": i18nc("@option:close-button-position", "Right"),
            "value": "right"
        },
        {
            "text": i18nc("@option:close-button-position", "Left"),
            "value": "left"
        }
    ]
    readonly property var hoverAnimationOptions: [
        { "text": i18n("None"), "value": "none" },
        { "text": i18n("Individual"), "value": "individual" },
        { "text": i18n("Pulse"), "value": "pulse" },
        { "text": i18n("Bounce"), "value": "bounce" }
    ]
    readonly property var normalPlacementOptions: [
        {
            "text": i18nc("@option:punchimenu-placement",
                "Attached to dock or panel"),
            "value": "anchored"
        },
        {
            "text": i18nc("@option:punchimenu-placement",
                "Centered on desktop"),
            "value": "centered"
        }
    ]

    function closeButtonPositionIndex() {
        return root.closeButtonPosition === "left" ? 1 : 0
    }

    function hoverAnimationIndex() {
        for (let index = 0; index < hoverAnimationOptions.length; ++index) {
            if (hoverAnimationOptions[index].value === root.hoverAnimation) {
                return index
            }
        }
        return 2
    }

    function normalPlacementIndex() {
        return root.normalPlacementMode === "centered" ? 1 : 0
    }

    function focusInitialAction() {
        backgroundBlurSwitch.forceActiveFocus()
    }

    Controls.ScrollView {
        id: settingsScrollView
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        Item {
            width: settingsScrollView.availableWidth
            implicitHeight: settingsColumn.implicitHeight
                + Kirigami.Units.largeSpacing * 2

            ColumnLayout {
                id: settingsColumn
                anchors.top: parent.top
                anchors.topMargin: Kirigami.Units.largeSpacing
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(1, Math.min(parent.width
                    - Kirigami.Units.largeSpacing * 2,
                    root.contentMaximumWidth))
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 1
                    text: i18nc("@title", "PunchiMenu Settings")
                    Accessible.role: Accessible.Heading
                    Accessible.name: text
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: i18nc("@info", "Changes are saved immediately.")
                    wrapMode: Text.WordWrap
                    color: Kirigami.Theme.disabledTextColor
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: root.errorMessage.length > 0
                    type: Kirigami.MessageType.Error
                    text: root.errorMessage
                    showCloseButton: false
                    Accessible.name: text
                }

                Kirigami.FormLayout {
                    Layout.fillWidth: true

                    Kirigami.Heading {
                        Kirigami.FormData.isSection: true
                        level: 2
                    text: i18n("Background and legibility")
                    }

                    Controls.Switch {
                        id: backgroundBlurSwitch
                        Kirigami.FormData.label: i18n("Background blur:")
                        text: i18n("Use background blur when available")
                        checked: root.backgroundBlurEnabled
                        Accessible.name: text
                        Accessible.description: i18n("Requests the desktop blur effect for the selected PunchiMenu mode.")
                        onToggled: root.settingChanged(root.blurSettingName,
                            checked)
                    }

                    Kirigami.InlineMessage {
                        Kirigami.FormData.isSection: true
                        Layout.fillWidth: true
                        visible: true
                        type: Kirigami.MessageType.Information
                        text: root.backgroundBlurEnabled
                            ? i18n("The background will use KWin blur when available. The selected opacity controls how much content behind the menu remains visible.")
                            : i18n("Without blur, the background depends on the Plasma theme and the selected opacity.")
                        Accessible.name: text
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18n("Background opacity:")

                        Controls.Slider {
                            id: backgroundOpacitySlider
                            Layout.fillWidth: true
                            from: 50
                            to: 100
                            stepSize: 5
                            snapMode: Controls.Slider.SnapAlways
                            value: root.backgroundOpacityPercent
                            Accessible.name: i18n("PunchiMenu background opacity")
                            Accessible.description: i18n("Changes only the menu background opacity; text and icons remain fully opaque.")
                            onMoved: root.settingChanged(
                                root.opacitySettingName,
                                Math.round(value / stepSize) * stepSize)
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged(
                                        root.opacitySettingName,
                                        Math.round(value / stepSize) * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1%", Math.round(
                                backgroundOpacitySlider.value))
                        }
                    }

                    PlasmaComponents.Button {
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

                        HoverHandler {
                            enabled: parent.enabled
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Kirigami.Heading {
                        Kirigami.FormData.isSection: true
                        level: 2
                        text: root.normalMode
                            ? i18nc("@option:punchimenu-mode",
                                "PunchiMenu Normal")
                            : i18nc("@option:punchimenu-mode",
                                "PunchiMenu Full screen")
                    }

                    Controls.Switch {
                        Kirigami.FormData.label: i18n("Application labels:")
                        text: i18n("Show application names")
                        checked: root.showApplicationLabels
                        Accessible.name: text
                        Accessible.description: i18n("Shows application names below their icons in the application grid and Favorites.")
                        onToggled: root.settingChanged(
                            "showApplicationLabels", checked)
                    }

                    PunchiMenuComboBox {
                        Kirigami.FormData.label: i18n("Hover animation:")
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        model: root.hoverAnimationOptions
                        textRole: "text"
                        valueRole: "value"
                        currentIndex: root.hoverAnimationIndex()
                        Accessible.name: i18n("PunchiMenu hover animation")
                        Accessible.description: i18n("Animates the complete application item, including its background, icon, and name.")
                        onActivated: function(index) {
                            const option = root.hoverAnimationOptions[index]
                            if (option) {
                                root.settingChanged(
                                    "hoverAnimation", option.value)
                            }
                        }
                    }

                    Controls.Switch {
                        Kirigami.FormData.label: i18n("Application order:")
                        text: i18n("Sort applications alphabetically")
                        checked: root.sortApplicationsAlphabetically
                        Accessible.name: text
                        Accessible.description: i18n("Keeps drag and drop available, but prevents manual reordering while alphabetical sorting is enabled.")
                        onToggled: root.settingChanged(
                            "sortApplicationsAlphabetically", checked)
                    }

                    Kirigami.InlineMessage {
                        Kirigami.FormData.isSection: true
                        Layout.fillWidth: true
                        visible: root.sortApplicationsAlphabetically
                        type: Kirigami.MessageType.Information
                        text: i18n("Alphabetical sorting is active. Application positions cannot be changed manually, but drag and drop remains available.")
                        Accessible.name: text
                    }

                    Controls.Switch {
                        visible: !root.normalMode
                        Kirigami.FormData.label: i18n("Distribution label:")
                        text: i18n("Show distribution name in full screen")
                        checked: root.showDistributionName
                        Accessible.name: text
                        onToggled: root.settingChanged(
                            "showDistributionName", checked)
                    }

                    Controls.Switch {
                        visible: !root.normalMode
                        Kirigami.FormData.label: i18n("Page navigation:")
                        text: i18n("Show page navigation arrows")
                        checked: root.showPageNavigationArrows
                        Accessible.name: text
                        onToggled: root.settingChanged(
                            "showPageNavigationArrows", checked)
                    }

                    PunchiMenuComboBox {
                        visible: !root.normalMode
                        Kirigami.FormData.label: i18n("Close button:")
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        model: root.closeButtonPositionOptions
                        textRole: "text"
                        valueRole: "value"
                        currentIndex: root.closeButtonPositionIndex()
                        Accessible.name: i18n("Close button position")
                        onActivated: function(index) {
                            const option = root.closeButtonPositionOptions[index]
                            if (option) {
                                root.settingChanged(
                                    "fullScreenCloseButtonPosition", option.value)
                            }
                        }
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18n(
                            "Application grid icon scale:")

                        Controls.Slider {
                            id: applicationIconScaleSlider
                            Layout.fillWidth: true
                            from: 75
                            to: 150
                            stepSize: 5
                            snapMode: Controls.Slider.SnapAlways
                            value: root.applicationIconScalePercent
                            Accessible.name: i18n(
                                "PunchiMenu application icon scale")
                            onMoved: root.settingChanged(
                                "gridIconScalePercent",
                                Math.round(value / stepSize) * stepSize)
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged("gridIconScalePercent",
                                        Math.round(value / stepSize) * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1%", Math.round(
                                applicationIconScaleSlider.value))
                        }
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18n(
                            "Favorites icon scale:")

                        Controls.Slider {
                            id: favoriteIconScaleSlider
                            Layout.fillWidth: true
                            from: 75
                            to: 110
                            stepSize: 5
                            snapMode: Controls.Slider.SnapAlways
                            value: root.favoriteIconScalePercent
                            Accessible.name: i18n(
                                "PunchiMenu Favorites icon scale")
                            Accessible.description: i18n("Changes the icon size in the reserved Favorites section in both menu modes.")
                            onMoved: root.settingChanged(
                                "favoriteIconScalePercent",
                                Math.round(value / stepSize) * stepSize)
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged(
                                        "favoriteIconScalePercent",
                                        Math.round(value / stepSize) * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1%", Math.round(
                                favoriteIconScaleSlider.value))
                        }
                    }

                    Controls.SpinBox {
                        Kirigami.FormData.label: i18n(
                            "Maximum folder columns:")
                        from: 1
                        to: root.folderMaximumLimit
                        value: root.folderMaximumColumns
                        Accessible.name: i18n(
                            "Maximum application columns inside folders")
                        onValueModified: root.settingChanged(
                            root.folderColumnsSettingName, value)
                    }

                    Controls.SpinBox {
                        Kirigami.FormData.label: i18n(
                            "Maximum folder rows:")
                        from: 1
                        to: root.folderMaximumLimit
                        value: root.folderMaximumRows
                        Accessible.name: i18n(
                            "Maximum application rows inside folders")
                        onValueModified: root.settingChanged(
                            root.folderRowsSettingName, value)
                    }

                    Kirigami.Heading {
                        Kirigami.FormData.isSection: true
                        visible: root.normalMode
                        level: 2
                        text: i18n("Location and size")
                    }

                    PunchiMenuComboBox {
                        Kirigami.FormData.label: i18n(
                            "Normal menu placement:")
                        visible: root.normalMode
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        model: root.normalPlacementOptions
                        textRole: "text"
                        valueRole: "value"
                        currentIndex: root.normalPlacementIndex()
                        Accessible.name: i18n("Normal menu placement")
                        Accessible.description: i18n("Attached keeps the menu next to its dock or panel. Centered uses the available area of the active screen.")
                        onActivated: function(index) {
                            const option = root.normalPlacementOptions[index]
                            if (option) {
                                root.settingChanged(
                                    "normalPlacementMode", option.value)
                            }
                        }
                    }

                    RowLayout {
                        visible: root.anchoredNormalMode
                        Kirigami.FormData.label: i18n("Panel distance:")

                        Controls.Slider {
                            id: normalPanelGapSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 32
                            stepSize: 1
                            snapMode: Controls.Slider.SnapAlways
                            value: root.normalPanelGap
                            Accessible.name: i18n("PunchiMenu panel distance")
                            Accessible.description: i18n("Adds space between PunchiMenu Normal and the panel edge.")
                            onMoved: root.settingChanged(
                                "normalPanelGap", Math.round(value))
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged(
                                        "normalPanelGap", Math.round(value))
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1 px", Math.round(
                                normalPanelGapSlider.value))
                        }
                    }

                    RowLayout {
                        visible: root.normalMode
                        Kirigami.FormData.label: i18n("Normal menu width:")

                        Controls.Slider {
                            id: normalWidthSlider
                            Layout.fillWidth: true
                            from: 30
                            to: 90
                            stepSize: 5
                            snapMode: Controls.Slider.SnapAlways
                            value: root.normalWidthPercent
                            Accessible.name: i18n("Normal menu width")
                            onMoved: root.settingChanged(
                                "normalWidthPercent",
                                Math.round(value / stepSize) * stepSize)
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged("normalWidthPercent",
                                        Math.round(value / stepSize) * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1%", Math.round(
                                normalWidthSlider.value))
                        }
                    }

                    RowLayout {
                        visible: root.normalMode
                        Kirigami.FormData.label: i18n("Normal menu height:")

                        Controls.Slider {
                            id: normalHeightSlider
                            Layout.fillWidth: true
                            from: 30
                            to: 90
                            stepSize: 5
                            snapMode: Controls.Slider.SnapAlways
                            value: root.normalHeightPercent
                            Accessible.name: i18n("Normal menu height")
                            onMoved: root.settingChanged(
                                "normalHeightPercent",
                                Math.round(value / stepSize) * stepSize)
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged("normalHeightPercent",
                                        Math.round(value / stepSize) * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1%", Math.round(
                                normalHeightSlider.value))
                        }
                    }
                }

                PlasmaComponents.Button {
                    id: advancedConfigurationButton
                    Layout.alignment: Qt.AlignRight
                    icon.name: "configure"
                    text: i18nc("@action:button",
                        "Open mode, icon, and shortcut settings…")
                    Accessible.name: text
                    onClicked: root.advancedConfigurationRequested()
                }
            }
        }
    }
}
// qmllint enable unqualified
