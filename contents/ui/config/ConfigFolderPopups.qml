import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "components"

Item {
    id: page
    implicitWidth: layoutMetrics.pageImplicitWidth
    implicitHeight: popupForm.implicitHeight

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

    property string activeProfile: "grid"

    readonly property bool interactiveCursorEnabled:
        !!Plasmoid.configuration.globalMouseCursor
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
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

    // qmllint disable unqualified
    Kirigami.FormLayout {
        id: popupForm
        width: page.width

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Folder popups")
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
    }
    // qmllint enable unqualified
}
