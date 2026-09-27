// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import ".."

// Thin wrapper of `TimedOptionsPanel`.
//
// The panel owns the layout, the controls and their texts; this dialog keeps only
// what makes it a dialog—title, modality, size and close button—plus the public API
// it already had, so the page and its form helper keep working without changes. It
// reads from the page the type being configured and whether it is being synchronized,
// forwards what the panel announces and opens the colour dialog the panel only
// requests; it writes nothing else.
//
// The four colour controls of `calendarBackgroundColor`, `calendarAccentColor`,
// `calendarBorderColor` and `calendarRadius` are kept as they were: they resolve to
// null today, because nothing in the calendar or clock flow ever asks for another
// target, and the page still declares aliases to them. Removing them would change
// the public surface of this wrapper, so this session preserves them.
//
// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
Controls.Dialog {
    id: timedDialog

    property var controller
    property alias itemNameControl: optionsPanel.itemNameControl
    property alias timedItemWidthControl: optionsPanel.timedItemWidthControl
    property alias timedTextScaleControl: optionsPanel.timedTextScaleControl
    property alias calendarItemHeightControl: optionsPanel.calendarItemHeightControl
    property alias calendarFormatControl: optionsPanel.calendarFormatControl
    property alias calendarTimeTextScaleControl:
        optionsPanel.calendarTimeTextScaleControl
    property alias calendarDateTextScaleControl:
        optionsPanel.calendarDateTextScaleControl
    property alias calendarTextShadowsControl: optionsPanel.calendarTextShadowsControl
    property alias calendarShowWeekNumbersControl:
        optionsPanel.calendarShowWeekNumbersControl
    property alias calendarPopupScaleControl: optionsPanel.calendarPopupScaleControl
    property alias calendarTextColorControl: optionsPanel.calendarTextColorControl
    property var calendarBackgroundColorControl: null
    property var calendarAccentColorControl: null
    property var calendarBorderColorControl: null
    property var calendarRadiusControl: null

    function hasController() {
        return timedDialog.controller !== undefined && timedDialog.controller !== null
    }

    function selectedType() {
        return timedDialog.hasController()
            ? String(timedDialog.controller.selectedItemType) : "calendar"
    }

    function selectedItemIsEditable() {
        return timedDialog.hasController()
            && Number(timedDialog.controller.selectedIndex) >= 0
    }

    // The page sets its own flag while it fills the form: the panel must not read a
    // synchronization as an edit of the user.
    function isSynchronizing() {
        return timedDialog.hasController()
            && timedDialog.controller.syncing === true
    }

    modal: true
    title: timedDialog.hasController()
        ? String(timedDialog.controller.selectedConfigureTitle())
        : ""
    standardButtons: Controls.Dialog.Close
    width: Math.min(timedDialog.hasController()
        ? timedDialog.controller.width - Kirigami.Units.largeSpacing * 2
        : Kirigami.Units.gridUnit * 42, Kirigami.Units.gridUnit * 42)
    height: Math.min(timedDialog.hasController()
        ? timedDialog.controller.height - Kirigami.Units.largeSpacing * 2
        : Kirigami.Units.gridUnit * 40,
        optionsPanel.implicitHeight + Kirigami.Units.gridUnit * 8)

    contentItem: TimedOptionsPanel {
        id: optionsPanel

        objectName: "timedOptionsPanel"

        selectedItemType: timedDialog.selectedType()
        editable: timedDialog.selectedItemIsEditable()
        syncingValues: timedDialog.isSynchronizing()
        onFormChanged: {
            if (timedDialog.hasController()) {
                timedDialog.controller.applyItemForm()
            }
        }
        onColorRequested: function(target) {
            if (timedDialog.hasController()) {
                timedDialog.controller.openTimedColorDialog(String(target))
            }
        }
    }
}
// qmllint enable unqualified
