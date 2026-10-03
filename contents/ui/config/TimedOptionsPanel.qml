// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import "components"

// Options of a calendar or clock element: its name, its format, the text scales, the
// popup scale, the week numbers and its colour.
//
// This is a passive visual component. It receives the type it is configuring, whether
// that element is editable and the values it shows—which the caller pushes into the
// controls, exactly as the page does today—announces what the user asked for through
// its signals and writes nothing: it never touches the dock item list, the
// configuration values or the draft of the add dialog. It does not know the page and
// it does not open the colour dialog: asking for a colour is an intention.
//
// The controls keep the names and the ranges they already had, so the caller that
// reads and writes them keeps working without changes.
//
// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
ColumnLayout {
    id: root

    // Type being configured and whether the element can be edited. The clock shows
    // the width of the item; the calendar shows the shadows switch.
    property string selectedItemType: "calendar"
    property bool editable: true
    // Layout variant: two columns by default, one when the panel shares its width
    // with the type selector, so the existing dialog keeps its distribution.
    property bool compactLayout: false
    // True while the caller is writing several values at once. A synchronization is
    // not an edit of the user, so nothing is announced while it runs.
    property bool syncingValues: false
    // True until the component has finished being built. Placing a control at its
    // starting value is part of the built-in state, not a choice of the user, so the
    // panel stays silent while it happens.
    property bool initializing: true

    // Value of the text colour. The caller reads and writes `text`, which is how the
    // page has always carried this value.
    QtObject {
        id: textColorHolder

        property string text: ""
    }

    // Controls the caller reads and writes. `*Control` names are part of the API the
    // page and its form helper use.
    property alias itemNameControl: itemName
    property alias timedItemWidthControl: timedItemWidth
    property alias timedTextScaleControl: timedTextScale
    property alias calendarItemHeightControl: calendarItemHeight
    property alias calendarFormatControl: calendarFormatCombo
    property alias calendarTimeTextScaleControl: calendarTimeTextScale
    property alias calendarDateTextScaleControl: calendarDateTextScale
    property alias calendarTextShadowsControl: calendarTextShadows
    property alias calendarShowWeekNumbersControl: calendarShowWeekNumbers
    property alias calendarPopupScaleControl: calendarPopupScale
    property alias calendarTextColorControl: textColorHolder

    // Intentions of the user, announced as they are. The colour request names the
    // target the page already knows; it is not this panel's business to open it.
    signal formChanged()
    signal colorRequested(string target)

    readonly property bool clockSelected: root.selectedItemType === "clock"

    // Announces the form, unless the change came from a synchronization or from the
    // own construction of the panel.
    function announce() {
        if (!root.initializing && !root.syncingValues) {
            root.formChanged()
        }
    }

    Component.onCompleted: root.initializing = false

    // Writes a set of values without announcing anything: it is the only path the
    // caller uses to show what it holds, and it never emits.
    function synchronizeValues(values) {
        const source = values || ({})
        const previous = root.syncingValues
        root.syncingValues = true
        try {
            if (source.name !== undefined) {
                itemName.text = String(source.name)
            }
            if (source.width !== undefined) {
                timedItemWidth.value = Number(source.width)
            }
            if (source.textScale !== undefined) {
                timedTextScale.value = Number(source.textScale)
            }
            if (source.itemHeight !== undefined) {
                calendarItemHeight.value = Number(source.itemHeight)
            }
            if (source.format !== undefined) {
                calendarFormatCombo.editText = String(source.format)
            }
            if (source.timeTextScale !== undefined) {
                calendarTimeTextScale.value = Number(source.timeTextScale)
            }
            if (source.dateTextScale !== undefined) {
                calendarDateTextScale.value = Number(source.dateTextScale)
            }
            if (source.textShadowsEnabled !== undefined) {
                calendarTextShadows.checked = Boolean(source.textShadowsEnabled)
            }
            if (source.showWeekNumbers !== undefined) {
                calendarShowWeekNumbers.checked = Boolean(source.showWeekNumbers)
            }
            if (source.popupScale !== undefined) {
                calendarPopupScale.value = Number(source.popupScale)
            }
            if (source.color !== undefined) {
                textColorHolder.text = String(source.color)
            }
        } finally {
            root.syncingValues = previous
        }
    }

    spacing: Kirigami.Units.largeSpacing

    GridLayout {
        Layout.fillWidth: true
        columns: root.compactLayout ? 1 : 2
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Controls.Label {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
            text: i18n("Name:")
            horizontalAlignment: Text.AlignLeft
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.TextField {
                id: itemName

                objectName: "timedNameField"

                Layout.fillWidth: true
                enabled: root.editable
                onEditingFinished: root.announce()
            }
        }

        Controls.Label {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            visible: root.clockSelected
            text: i18n("Item width:")
            horizontalAlignment: Text.AlignLeft
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.clockSelected
            enabled: root.editable
            spacing: Kirigami.Units.smallSpacing

            Controls.Label {
                text: i18n("Width:")
                opacity: 0.75
            }

            Controls.SpinBox {
                id: timedItemWidth

                objectName: "timedItemWidthSpinBox"

                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                from: 0
                to: 600
                stepSize: 10
                Accessible.name: i18n("Item width:")
                textFromValue: function(value) {
                    return value === 0 ? i18n("Automatic") : value + " px"
                }
                valueFromText: function(text) {
                    return text === i18n("Automatic") ? 0
                        : Number.fromLocaleString(Qt.locale(), text.replace("px", ""))
                }
                onValueModified: root.announce()

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Item width:")
            }

            Controls.Label {
                visible: false
                text: i18n("Height:")
                opacity: 0.75
            }

            Controls.SpinBox {
                id: calendarItemHeight

                objectName: "calendarItemHeightSpinBox"

                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                visible: false
                enabled: root.editable
                from: 0
                to: 600
                stepSize: 10
                textFromValue: function(value) {
                    return value === 0 ? i18n("Automatic") : value + " px"
                }
                valueFromText: function(text) {
                    return text === i18n("Automatic") ? 0
                        : Number.fromLocaleString(Qt.locale(), text.replace("px", ""))
                }
                onValueModified: root.announce()

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Item height:")
            }
        }

        Controls.Label {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            visible: false
            text: i18n("Text scale:")
            horizontalAlignment: Text.AlignLeft
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            visible: false
            enabled: root.editable
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: timedTextScale

                objectName: "timedTextScaleSlider"

                Layout.fillWidth: true
                from: 0.75
                to: 1.8
                stepSize: 0.05
                snapMode: Controls.Slider.SnapAlways
                onMoved: root.announce()
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.6
                horizontalAlignment: Text.AlignRight
                text: Math.round(timedTextScale.value * 100) + "%"
                opacity: 0.75
            }
        }

        Controls.Label {
            text: i18n("Format:")
            opacity: 0.75
        }

        Controls.ComboBox {
            id: calendarFormatCombo

            objectName: "calendarFormatCombo"

            Layout.fillWidth: true
            enabled: root.editable
            editable: true
            Accessible.name: i18n("Format:")
            model: [
                "HH:mm",
                "HH:mm:ss",
                "hh:mm AP",
                "dd/MM/yyyy",
                "dd/MM/yyyy HH:mm",
                "ddd dd MMM - HH:mm",
                "dddd, d MMMM yyyy"
            ]
            onAccepted: root.announce()
            onActivated: function(index) {
                if (index >= 0 && index < model.length) {
                    editText = model[index]
                }
                root.announce()
            }
        }

        Controls.Label {
            text: i18n("Time text scale:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: calendarTimeTextScale

                objectName: "calendarTimeTextScaleSlider"

                Layout.fillWidth: true
                from: 0.75
                to: 2.0
                stepSize: 0.05
                snapMode: Controls.Slider.SnapAlways
                enabled: root.editable
                onMoved: root.announce()
                Accessible.name: i18n("Time text scale")
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: Math.round(calendarTimeTextScale.value * 100) + "%"
                opacity: 0.75
            }
        }

        Controls.Label {
            text: i18n("Date text scale:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: calendarDateTextScale

                objectName: "calendarDateTextScaleSlider"

                Layout.fillWidth: true
                from: 0.75
                to: 2.0
                stepSize: 0.05
                snapMode: Controls.Slider.SnapAlways
                enabled: root.editable
                onMoved: root.announce()
                Accessible.name: i18n("Date text scale")
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: Math.round(calendarDateTextScale.value * 100) + "%"
                opacity: 0.75
            }
        }

        Controls.CheckBox {
            id: calendarTextShadows

            objectName: "calendarTextShadowsCheckBox"

            Layout.columnSpan: root.compactLayout ? 1 : 2
            text: i18n("Show shadows on clock and date text")
            visible: root.selectedItemType === "calendar"
            enabled: root.editable
            onToggled: root.announce()
        }

        Controls.CheckBox {
            id: calendarShowWeekNumbers

            objectName: "calendarShowWeekNumbersCheckBox"

            Layout.columnSpan: root.compactLayout ? 1 : 2
            text: i18n("Show week numbers")
            enabled: root.editable
            onToggled: root.announce()
            Accessible.name: i18n("Show calendar week numbers")
        }

        Controls.Label {
            text: i18n("Popup scale:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: calendarPopupScale

                objectName: "calendarPopupScaleSlider"

                Layout.fillWidth: true
                from: 0.5
                to: 3.0
                stepSize: 0.05
                snapMode: Controls.Slider.SnapAlways
                enabled: root.editable
                onMoved: root.announce()
                Accessible.name: i18n("Calendar popup scale")
                Accessible.description: i18n("Adjusts the calendar popup scale between 50 and 300 percent.")
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: Math.round(calendarPopupScale.value * 100) + "%"
                opacity: 0.75
            }
        }

        Controls.Label {
            text: i18n("Text color:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            ColorModeControl {
                id: textColorMode

                objectName: "timedTextColorControl"

                Layout.fillWidth: true
                enabled: root.editable
                customColor: root.calendarTextColorControl.text
                fallbackColor: Kirigami.Theme.textColor
                onColorRequested: root.colorRequested("text")
                // Returning to the theme is an edit: the value goes back to empty and
                // exactly one intention is announced.
                onThemeRequested: {
                    root.calendarTextColorControl.text = ""
                    root.announce()
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
    }
}
// qmllint enable unqualified
