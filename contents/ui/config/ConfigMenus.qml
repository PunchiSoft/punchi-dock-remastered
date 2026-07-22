import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "components"

Item {
    id: page
    implicitWidth: layoutMetrics.pageImplicitWidth
    implicitHeight: menuForm.implicitHeight

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    property alias cfg_contextMenuTransitionSpeed: contextMenuTransitionSpeedSlider.value
    property alias cfg_contextMenuVisibleRows: contextMenuVisibleRowsSpin.value
    property alias cfg_contextMenuRowHeight: contextMenuRowHeightSlider.value
    property alias cfg_contextMenuIconSize: contextMenuIconSizeSlider.value
    property alias cfg_contextMenuWidth: contextMenuWidthSlider.value
    property string cfg_contextMenuTransitionDirection: "fromRight"

    readonly property bool interactiveCursorEnabled:
        !!Plasmoid.configuration.globalMouseCursor
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    // qmllint disable unqualified
    readonly property var sizePresetOptions: [
        { "text": i18nc("@item:inlistbox Context menu size", "Compact"), "value": "compact" },
        { "text": i18nc("@item:inlistbox Context menu size", "Comfortable"), "value": "comfortable" },
        { "text": i18nc("@item:inlistbox Context menu size", "Large"), "value": "large" },
        { "text": i18nc("@item:inlistbox Context menu size", "Custom"), "value": "custom" }
    ]
    // qmllint enable unqualified
    readonly property string detectedSizePreset: {
        const rowHeight = Math.round(contextMenuRowHeightSlider.value)
        const iconSize = Math.round(contextMenuIconSizeSlider.value)
        const menuWidth = Math.round(contextMenuWidthSlider.value)
        if (rowHeight === 38 && iconSize === 20 && menuWidth === 300) {
            return "compact"
        }
        if (rowHeight === 46 && iconSize === 26 && menuWidth === 360) {
            return "comfortable"
        }
        if (rowHeight === 56 && iconSize === 32 && menuWidth === 440) {
            return "large"
        }
        return "custom"
    }
    readonly property int detectedSizePresetIndex: Math.max(0,
        sizePresetCombo.indexOfValue(detectedSizePreset))
    // qmllint disable unqualified
    readonly property var transitionDirectionOptions: [
        { "text": i18nc("@item:inlistbox Context menu entrance", "From the right"), "value": "fromRight" },
        { "text": i18nc("@item:inlistbox Context menu entrance", "From the left"), "value": "fromLeft" },
        { "text": i18nc("@item:inlistbox Context menu entrance", "From the top"), "value": "fromTop" },
        { "text": i18nc("@item:inlistbox Context menu entrance", "From the bottom"), "value": "fromBottom" },
        { "text": i18nc("@item:inlistbox Context menu entrance", "Morph only"), "value": "morphOnly" }
    ]
    // qmllint enable unqualified

    function syncDirectionSelector() {
        const resolvedIndex = Math.max(0,
            transitionDirectionCombo.indexOfValue(cfg_contextMenuTransitionDirection))
        if (transitionDirectionCombo.currentIndex !== resolvedIndex) {
            transitionDirectionCombo.currentIndex = resolvedIndex
        }
    }

    function applySizePreset(preset) {
        if (preset === "compact") {
            contextMenuRowHeightSlider.value = 38
            contextMenuIconSizeSlider.value = 20
            contextMenuWidthSlider.value = 300
        } else if (preset === "comfortable") {
            contextMenuRowHeightSlider.value = 46
            contextMenuIconSizeSlider.value = 26
            contextMenuWidthSlider.value = 360
        } else if (preset === "large") {
            contextMenuRowHeightSlider.value = 56
            contextMenuIconSizeSlider.value = 32
            contextMenuWidthSlider.value = 440
        }
    }

    onCfg_contextMenuTransitionDirectionChanged: syncDirectionSelector()
    Component.onCompleted: syncDirectionSelector()

    // qmllint disable unqualified
    Kirigami.FormLayout {
        id: menuForm
        width: page.width

        Controls.ComboBox {
            id: sizePresetCombo
            Kirigami.FormData.label: i18n("Menu size:")
            Layout.preferredWidth: page.selectorWidthHint
            Layout.maximumWidth: page.selectorWidthHint
            textRole: "text"
            valueRole: "value"
            model: page.sizePresetOptions
            currentIndex: page.detectedSizePresetIndex
            Accessible.name: i18n("Context menu size preset")
            onActivated: page.applySizePreset(currentValue)

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.SpinBox {
            id: contextMenuVisibleRowsSpin
            Kirigami.FormData.label: i18n("Visible actions:")
            from: 3
            to: 12
            value: 6
            Layout.preferredWidth: layoutMetrics.selectorWidth
            Accessible.name: i18n("Maximum visible context menu actions")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Row height:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: contextMenuRowHeightSlider
                from: 32
                to: 64
                value: 46
                stepSize: 2
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Context menu row height")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1 px", Math.round(contextMenuRowHeightSlider.value))
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Icon size:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: contextMenuIconSizeSlider
                from: 16
                to: 40
                value: 26
                stepSize: 2
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Context menu icon size")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1 px", Math.round(contextMenuIconSizeSlider.value))
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Menu width:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: contextMenuWidthSlider
                from: 240
                to: 520
                value: 360
                stepSize: 10
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Context menu target width")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1 px", Math.round(contextMenuWidthSlider.value))
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        Controls.Label {
            text: i18n("Menus use these target dimensions after morphing from a window preview. Screen limits can reduce the effective size safely.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        Controls.ComboBox {
            id: transitionDirectionCombo
            Kirigami.FormData.label: i18n("Menu entrance:")
            Layout.preferredWidth: page.selectorWidthHint
            Layout.maximumWidth: page.selectorWidthHint
            textRole: "text"
            valueRole: "value"
            model: page.transitionDirectionOptions
            Accessible.name: i18n("Context menu entrance direction")
            onActivated: {
                if (page.cfg_contextMenuTransitionDirection !== currentValue) {
                    page.cfg_contextMenuTransitionDirection = currentValue
                }
            }

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Menu transition speed:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: contextMenuTransitionSpeedSlider
                from: 10
                to: 200
                value: 100
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Preview to context menu transition speed")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1%", Math.round(contextMenuTransitionSpeedSlider.value))
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        Controls.Label {
            text: i18n("Lower values make the preview-to-menu movement gentler; higher values make it faster. 100% follows the Plasma theme duration.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        Kirigami.InlineMessage {
            visible: true
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            type: Kirigami.MessageType.Information
            text: i18n("Menu entries and per-item actions remain configured from the Items section.")
        }
    }
    // qmllint enable unqualified
}
