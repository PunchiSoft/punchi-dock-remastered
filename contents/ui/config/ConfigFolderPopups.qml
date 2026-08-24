import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "components"

Item {
    id: page
    implicitWidth: layoutMetrics.pageImplicitWidth
    implicitHeight: popupColumn.implicitHeight

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    property int cfg_folderGridIconSize: 36
    property int cfg_folderGridColumns: 3
    property int cfg_folderGridRows: 4
    property bool cfg_folderGridShowLabels: true
    property string cfg_folderGridFontFamily: ""
    property int cfg_folderGridFontSize: 9
    property int cfg_folderListIconSize: 32
    property int cfg_folderListRows: 4
    property bool cfg_folderListShowLabels: true
    property string cfg_folderListFontFamily: ""
    property int cfg_folderListFontSize: 10
    property int cfg_folderDetailedIconSize: 32
    property int cfg_folderDetailedRows: 4
    property bool cfg_folderDetailedShowLabels: true
    property string cfg_folderDetailedFontFamily: ""
    property int cfg_folderDetailedFontSize: 10
    property int cfg_folderPopupExtraDistance: 0
    property int cfg_folderPopupDistancePercent: -1
    property alias cfg_folderPopupScale: folderPopupScaleSlider.value
    property alias cfg_folderPopupBackgroundOpacityPercent: folderPopupBackgroundOpacitySlider.value
    property alias cfg_folderPopupShowHeader: showFolderHeaderCheck.checked
    property alias cfg_popupTextShadowsEnabled: popupTextShadowsCheck.checked
    property alias cfg_popupAnimation: generalPopupAnimationSettings.animationStyle
    property alias cfg_popupAnimationSpeedPercent: generalPopupAnimationSettings.animationSpeedPercent
    property alias cfg_popupAnimationIntensity: generalPopupAnimationSettings.animationIntensityPercent

    property string activeProfile: "grid"

    readonly property bool interactiveCursorEnabled:
        !!Plasmoid.configuration.globalMouseCursor
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    readonly property int effectiveFolderPopupDistancePercent: {
        const configuredPercent = Number(page.cfg_folderPopupDistancePercent)
        if (Number.isFinite(configuredPercent) && configuredPercent >= 0) {
            return Math.max(0, Math.min(100,
                Math.round(configuredPercent / 5) * 5))
        }
        const legacyDistance = Number(page.cfg_folderPopupExtraDistance)
        const safeLegacyDistance = Number.isFinite(legacyDistance)
            ? Math.max(0, Math.min(32, legacyDistance))
            : 0
        return Math.max(0, Math.min(100,
            Math.round((safeLegacyDistance * 100 / 32) / 5) * 5))
    }
    readonly property int activeIconSize: activeProfile === "list"
        ? cfg_folderListIconSize
        : (activeProfile === "detailed"
            ? cfg_folderDetailedIconSize
            : cfg_folderGridIconSize)
    readonly property int activeRows: activeProfile === "list"
        ? cfg_folderListRows
        : (activeProfile === "detailed"
            ? cfg_folderDetailedRows
            : cfg_folderGridRows)
    readonly property bool activeShowLabels: activeProfile === "list"
        ? cfg_folderListShowLabels
        : (activeProfile === "detailed"
            ? cfg_folderDetailedShowLabels
            : cfg_folderGridShowLabels)
    readonly property string activeFontFamily: activeProfile === "list"
        ? cfg_folderListFontFamily
        : (activeProfile === "detailed"
            ? cfg_folderDetailedFontFamily
            : cfg_folderGridFontFamily)
    readonly property int activeFontSize: activeProfile === "list"
        ? cfg_folderListFontSize
        : (activeProfile === "detailed"
            ? cfg_folderDetailedFontSize
            : cfg_folderGridFontSize)
    // qmllint disable unqualified
    readonly property var profileOptions: [
        { "text": i18nc("@item:inlistbox Folder popup layout", "Grid"), "value": "grid" },
        { "text": i18nc("@item:inlistbox Folder popup layout", "List"), "value": "list" },
        { "text": i18nc("@item:inlistbox Folder popup layout", "Detailed"), "value": "detailed" }
    ]
    // qmllint enable unqualified

    function setActiveIconSize(value) {
        if (activeProfile === "list") {
            cfg_folderListIconSize = value
        } else if (activeProfile === "detailed") {
            cfg_folderDetailedIconSize = value
        } else {
            cfg_folderGridIconSize = value
        }
    }

    function setActiveRows(value) {
        if (activeProfile === "list") {
            cfg_folderListRows = value
        } else if (activeProfile === "detailed") {
            cfg_folderDetailedRows = value
        } else {
            cfg_folderGridRows = value
        }
    }

    function setActiveShowLabels(value) {
        if (activeProfile === "list") {
            cfg_folderListShowLabels = value
        } else if (activeProfile === "detailed") {
            cfg_folderDetailedShowLabels = value
        } else {
            cfg_folderGridShowLabels = value
        }
    }

    function setActiveFontFamily(value) {
        if (activeProfile === "list") {
            cfg_folderListFontFamily = value
        } else if (activeProfile === "detailed") {
            cfg_folderDetailedFontFamily = value
        } else {
            cfg_folderGridFontFamily = value
        }
    }

    function setActiveFontSize(value) {
        if (activeProfile === "list") {
            cfg_folderListFontSize = value
        } else if (activeProfile === "detailed") {
            cfg_folderDetailedFontSize = value
        } else {
            cfg_folderGridFontSize = value
        }
    }

    // qmllint disable unqualified
    function availableFonts() {
        const result = [i18n("Automatic")]
        try {
            const families = Qt.fontFamilies()
            if (families && families.length > 0) {
                return result.concat(families.sort())
            }
        } catch (error) {
        }
        return result
    }
    // qmllint enable unqualified

    function fontIndex(family) {
        if (!family || String(family).length === 0) {
            return 0
        }
        const index = fontFamilyCombo.find(String(family))
        return index >= 0 ? index : 0
    }

    readonly property var fontOptions: availableFonts()

    component SectionTitle: Kirigami.Heading {
        Layout.fillWidth: true
        level: 3
        leftPadding: 0
    }

    ColumnLayout {
        id: popupColumn
        anchors.fill: parent
        spacing: 0

        // qmllint disable unqualified
        Kirigami.FormLayout {
            id: popupForm
            Layout.fillWidth: true

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Folder popups")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Popup scale:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: folderPopupScaleSlider
                from: 0.5
                to: 3.0
                stepSize: 0.1
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Folder popup scale")
                Accessible.description: i18n("Adjusts the folder popup content scale between 50 and 300 percent.")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1%", Math.round(Number(folderPopupScaleSlider.value || 1.0) * 100))
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        Controls.Label {
            text: i18n("This global scale applies to all folder popup layout profiles while maintaining fixed window geometry.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background opacity:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: folderPopupBackgroundOpacitySlider
                from: 50
                to: 100
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                value: 75
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Folder popup background opacity")
                Accessible.description: i18n("Only the folder popup background changes; applications, icons, controls and text remain fully opaque.")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1%", Math.round(folderPopupBackgroundOpacitySlider.value))
                font.bold: true
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 54
            }
        }

        Controls.Label {
            text: i18n("Only the folder popup background changes; applications, icons, controls and text remain fully opaque.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Popup distance:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: folderPopupDistanceSlider
                from: 0
                to: 100
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                value: page.effectiveFolderPopupDistancePercent
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Folder popup distance")
                Accessible.description: i18n("Adds safe spacing between the dock item and folder popups.")
                onMoved: page.cfg_folderPopupDistancePercent =
                    Math.round(value)

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1%", Math.round(folderPopupDistanceSlider.value))
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        Controls.Label {
            text: i18n("The percentage scales with Plasma metrics. It only affects folder popups and is limited to a safe maximum distance.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        Controls.CheckBox {
            id: showFolderHeaderCheck
            Kirigami.FormData.label: i18n("Title header:")
            text: i18n("Show folder name header at top of popups")
            Accessible.description: i18n("Displays the folder title header label and close button at the top of the popup.")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
                role: "checkbox"
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Layout customization")
        }

        Controls.ComboBox {
            id: profileCombo
            Kirigami.FormData.label: i18n("Layout profile:")
            Layout.preferredWidth: page.selectorWidthHint
            Layout.maximumWidth: page.selectorWidthHint
            textRole: "text"
            valueRole: "value"
            model: page.profileOptions
            currentIndex: Math.max(0, indexOfValue(page.activeProfile))
            Accessible.name: i18n("Folder popup layout profile")
            onActivated: page.activeProfile = currentValue

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: i18n("Each profile applies to every folder that uses that layout. Choose a profile here to edit it; folder layouts are selected in Items.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Icon size:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: iconSizeSlider
                from: 24
                to: 64
                stepSize: 4
                snapMode: Controls.Slider.SnapAlways
                value: page.activeIconSize
                onMoved: page.setActiveIconSize(Math.round(value))
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 60
                Accessible.name: i18n("Folder popup icon size")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1 px", Math.round(iconSizeSlider.value))
                font.bold: true
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 52
            }
        }

        Controls.SpinBox {
            id: columnsSpin
            visible: page.activeProfile === "grid"
            Kirigami.FormData.label: i18n("Visible columns:")
            from: 1
            to: 8
            value: page.cfg_folderGridColumns
            onValueModified: page.cfg_folderGridColumns = value
            Layout.preferredWidth: page.selectorWidthHint
            Accessible.name: i18n("Maximum visible folder popup columns")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.SpinBox {
            id: rowsSpin
            Kirigami.FormData.label: i18n("Visible rows:")
            from: 1
            to: 8
            value: page.activeRows
            onValueModified: page.setActiveRows(value)
            Layout.preferredWidth: page.selectorWidthHint
            Accessible.name: i18n("Maximum visible folder popup rows")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.CheckBox {
            id: showLabelsCheck
            Kirigami.FormData.label: i18n("Item text:")
            text: i18n("Show application names and details")
            checked: page.activeShowLabels
            Accessible.description: i18n("Shows application names in every layout and command details in the detailed layout.")
            onToggled: page.setActiveShowLabels(checked)

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.ComboBox {
            id: fontFamilyCombo
            Kirigami.FormData.label: i18n("Font family:")
            enabled: page.activeShowLabels
            Layout.preferredWidth: page.selectorWidthHint
            Layout.maximumWidth: page.selectorWidthHint
            model: page.fontOptions
            currentIndex: page.fontIndex(page.activeFontFamily)
            font.family: page.activeFontFamily.length > 0
                ? page.activeFontFamily
                : Kirigami.Theme.defaultFont.family
            Accessible.name: i18n("Folder popup font family")
            onActivated: page.setActiveFontFamily(currentIndex > 0
                ? String(currentText)
                : "")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        RowLayout {
            enabled: page.activeShowLabels
            Kirigami.FormData.label: i18n("Font size:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: fontSizeSlider
                from: 8
                to: 18
                stepSize: 1
                snapMode: Controls.Slider.SnapAlways
                value: page.activeFontSize
                onMoved: page.setActiveFontSize(Math.round(value))
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 60
                Accessible.name: i18n("Folder popup font size")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1 pt", Math.round(fontSizeSlider.value))
                font.bold: true
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 52
            }
        }

        Controls.Label {
            text: page.activeProfile === "grid"
                ? i18n("Additional applications remain available by scrolling. On narrow screens, the popup safely reduces the number of columns.")
                : i18n("Additional applications remain available by scrolling.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Popup text appearance")
        }

        Controls.CheckBox {
            id: popupTextShadowsCheck
            Kirigami.FormData.label: i18n("Text shadows:")
            text: i18n("Show subtle shadows on popup text")
            Accessible.description: i18n("Applies to folder popup labels and note popup titles.")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }
        }
        // qmllint enable unqualified

        PopupAnimationSettings {
            id: generalPopupAnimationSettings
            Layout.fillWidth: true
            // qmllint disable unqualified
            sectionTitle: i18n("General popup animation")
            // qmllint enable unqualified
            animationStyle: "scale"
            animationSpeedPercent: 100
            animationIntensityPercent: 100
            contentWidthHint: page.contentWidthHint
            selectorWidthHint: page.selectorWidthHint
            interactiveCursorEnabled: page.interactiveCursorEnabled
        }
    }
}
