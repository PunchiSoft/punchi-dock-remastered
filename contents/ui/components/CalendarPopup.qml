pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: calendarRoot
    readonly property real effectivePopupScale: Math.max(0.5, Math.min(3.0,
        Number(popupScale || 1.0)))
    readonly property int scaledMargin: Math.round(16 * effectivePopupScale)
    readonly property int scaledSpacing: Math.round(12 * effectivePopupScale)
    readonly property int scaledControlSize: Math.round(28 * effectivePopupScale)
    readonly property int scaledIconSize: Math.max(12, Math.round(16 * effectivePopupScale))
    readonly property int scaledCellInset: Math.max(2, Math.round(4 * effectivePopupScale))
    readonly property int scaledCellRadius: Math.max(4, Math.round(6 * effectivePopupScale))
    readonly property int scaledBodySpacing: Math.max(2, Math.round(4 * effectivePopupScale))
    readonly property int dayColumnCount: showWeekNumbers ? 8 : 7
    implicitWidth: Math.round((showWeekNumbers ? 356 : 320) * effectivePopupScale)
    implicitHeight: Math.round(300 * effectivePopupScale)
    width: implicitWidth
    height: implicitHeight

    property date displayedDate: new Date()
    property date today: new Date()
    property bool showWeekNumbers: false
    property real popupScale: 1.0
    signal closeRequested()

    // Native KDE/Qt locale formatter for system-provided translations.
    property var dayNames: {
        var locale = Qt.locale()
        var days = []
        // Generate short day names from Monday (1) through Sunday (7/0 in Qt).
        for (var i = 1; i <= 7; i++) {
            var dayNum = (i === 7) ? 0 : i
            days.push(locale.standaloneDayName(dayNum, Locale.NarrowFormat))
        }
        return days
    }

    function getFormattedMonthYear() {
        var locale = Qt.locale()
        var monthName = locale.standaloneMonthName(displayedDate.getMonth(), Locale.LongFormat)
        monthName = monthName.charAt(0).toUpperCase() + monthName.slice(1)
        return monthName + " " + displayedDate.getFullYear()
    }

    function getFormattedTodaySubtitle() {
        var locale = Qt.locale()
        var dayName = locale.standaloneDayName(today.getDay() === 0 ? 0 : today.getDay(), Locale.LongFormat)
        if (dayName.length > 0) {
            dayName = dayName.charAt(0).toUpperCase() + dayName.slice(1)
        }
        var monthName = locale.standaloneMonthName(today.getMonth(), Locale.ShortFormat)
        if (monthName.length > 0) {
            monthName = monthName.charAt(0).toUpperCase() + monthName.slice(1)
        }
        return dayName + ", " + today.getDate() + " " + monthName + " " + today.getFullYear()
    }

    function goToToday() {
        displayedDate = new Date()
        today = new Date()
        updateGrid()
    }

    // Navigate between months.
    function prevMonth() {
        var m = displayedDate.getMonth();
        var y = displayedDate.getFullYear();
        if (m === 0) {
            displayedDate = new Date(y - 1, 11, 1);
        } else {
            displayedDate = new Date(y, m - 1, 1);
        }
        updateGrid();
    }

    function nextMonth() {
        var m = displayedDate.getMonth();
        var y = displayedDate.getFullYear();
        if (m === 11) {
            displayedDate = new Date(y + 1, 0, 1);
        } else {
            displayedDate = new Date(y, m + 1, 1);
        }
        updateGrid();
    }

    function isoWeekNumber(date) {
        var weekDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())
        var day = weekDate.getDay()
        day = day === 0 ? 7 : day
        weekDate.setDate(weekDate.getDate() + 4 - day)
        var yearStart = new Date(weekDate.getFullYear(), 0, 1)
        return Math.ceil((((weekDate - yearStart) / 86400000) + 1) / 7)
    }

    // Calendar model with six rows. Each row can include a leading ISO week cell.
    ListModel {
        id: calendarCellsModel
    }

    function updateGrid() {
        calendarCellsModel.clear();
        var year = displayedDate.getFullYear();
        var month = displayedDate.getMonth();
        var days = [];

        // Days in the current month and first weekday (Monday=0 through Sunday=6).
        var daysInMonth = new Date(year, month + 1, 0).getDate();
        var firstDayIndex = new Date(year, month, 1).getDay();
        firstDayIndex = (firstDayIndex === 0) ? 6 : firstDayIndex - 1;

        // Days in the previous month used to fill leading cells.
        var prevMonthDays = new Date(year, month, 0).getDate();

        // Fill days from the previous month.
        for (var i = firstDayIndex - 1; i >= 0; i--) {
            var previousDayNumber = prevMonthDays - i;
            days.push({
                dayNumber: prevMonthDays - i,
                cellDate: new Date(year, month - 1, previousDayNumber),
                isCurrentMonth: false,
                isToday: false
            });
        }

        // Fill days from the current month.
        for (var j = 1; j <= daysInMonth; j++) {
            var isItToday = (j === today.getDate() && 
                             month === today.getMonth() && 
                             year === today.getFullYear());
            days.push({
                dayNumber: j,
                cellDate: new Date(year, month, j),
                isCurrentMonth: true,
                isToday: isItToday
            });
        }

        // Fill days from the next month until all 42 cells are populated.
        var remainingCells = 42 - days.length;
        for (var k = 1; k <= remainingCells; k++) {
            days.push({
                dayNumber: k,
                cellDate: new Date(year, month + 1, k),
                isCurrentMonth: false,
                isToday: false
            });
        }

        for (var row = 0; row < 6; row++) {
            if (showWeekNumbers) {
                calendarCellsModel.append({
                    isWeekNumber: true,
                    weekNumber: isoWeekNumber(days[row * 7].cellDate),
                    dayNumber: 0,
                    isCurrentMonth: false,
                    isToday: false
                });
            }
            for (var column = 0; column < 7; column++) {
                var dayCell = days[row * 7 + column];
                calendarCellsModel.append({
                    isWeekNumber: false,
                    weekNumber: 0,
                    dayNumber: dayCell.dayNumber,
                    isCurrentMonth: dayCell.isCurrentMonth,
                    isToday: dayCell.isToday
                });
            }
        }
    }

    Component.onCompleted: updateGrid()

    onShowWeekNumbersChanged: updateGrid()

    onVisibleChanged: {
        if (visible) {
            displayedDate = new Date()
            today = new Date()
            updateGrid()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: calendarRoot.scaledMargin
        spacing: calendarRoot.scaledSpacing

        // Main Header: Month/Year on left, control buttons on top right.
        RowLayout {
            Layout.fillWidth: true
            spacing: calendarRoot.scaledSpacing

            PlasmaComponents.Label {
                text: calendarRoot.getFormattedMonthYear()
                font.family: Kirigami.Theme.defaultFont.family
                font.pixelSize: Math.max(14, Math.round(16 * calendarRoot.effectivePopupScale))
                font.weight: Font.Bold
                color: Kirigami.Theme.textColor
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            RowLayout {
                spacing: Math.round(4 * calendarRoot.effectivePopupScale)
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                
                // Previous month button.
                Rectangle {
                    Layout.preferredWidth: calendarRoot.scaledControlSize
                    Layout.preferredHeight: calendarRoot.scaledControlSize
                    radius: calendarRoot.scaledCellRadius
                    color: prevMouse.containsMouse ? Kirigami.Theme.hoverColor : "transparent"
                    border.width: prevMouse.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.highlightColor
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: calendarRoot.scaledIconSize
                        height: calendarRoot.scaledIconSize
                        source: "go-previous-symbolic"
                    }
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent; hoverEnabled: true
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: i18n("Previous month")
                        onClicked: prevMonth()
                        Keys.onReturnPressed: prevMonth()
                        Keys.onSpacePressed: prevMonth()
                    }
                }

                // Return to Today button.
                Rectangle {
                    Layout.preferredWidth: calendarRoot.scaledControlSize
                    Layout.preferredHeight: calendarRoot.scaledControlSize
                    radius: calendarRoot.scaledCellRadius
                    color: todayMouse.containsMouse ? Kirigami.Theme.hoverColor : "transparent"
                    border.width: todayMouse.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.highlightColor
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: calendarRoot.scaledIconSize
                        height: calendarRoot.scaledIconSize
                        source: "appointment-recurring-symbolic"
                    }
                    MouseArea {
                        id: todayMouse
                        anchors.fill: parent; hoverEnabled: true
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: i18n("Go to today")
                        onClicked: goToToday()
                        Keys.onReturnPressed: goToToday()
                        Keys.onSpacePressed: goToToday()
                    }
                }

                // Next month button.
                Rectangle {
                    Layout.preferredWidth: calendarRoot.scaledControlSize
                    Layout.preferredHeight: calendarRoot.scaledControlSize
                    radius: calendarRoot.scaledCellRadius
                    color: nextMouse.containsMouse ? Kirigami.Theme.hoverColor : "transparent"
                    border.width: nextMouse.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.highlightColor
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: calendarRoot.scaledIconSize
                        height: calendarRoot.scaledIconSize
                        source: "go-next-symbolic"
                    }
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent; hoverEnabled: true
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: i18n("Next month")
                        onClicked: nextMonth()
                        Keys.onReturnPressed: nextMonth()
                        Keys.onSpacePressed: nextMonth()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: Math.round(14 * calendarRoot.effectivePopupScale)
                    color: Kirigami.Theme.textColor
                    opacity: 0.15
                    Layout.leftMargin: Math.round(3 * calendarRoot.effectivePopupScale)
                    Layout.rightMargin: Math.round(3 * calendarRoot.effectivePopupScale)
                }

                // Close button.
                Rectangle {
                    Layout.preferredWidth: calendarRoot.scaledControlSize
                    Layout.preferredHeight: calendarRoot.scaledControlSize
                    radius: calendarRoot.scaledCellRadius
                    color: closeMouse.containsMouse ? Kirigami.Theme.hoverColor : "transparent"
                    border.width: closeMouse.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.negativeTextColor

                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        text: "×"
                        font.pixelSize: Math.max(12, Math.round(14 * calendarRoot.effectivePopupScale))
                        color: closeMouse.containsMouse ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent; hoverEnabled: true
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: i18n("Close")
                        onClicked: calendarRoot.closeRequested()
                        Keys.onReturnPressed: calendarRoot.closeRequested()
                        Keys.onSpacePressed: calendarRoot.closeRequested()
                    }
                }
            }
        }

        // Subtitle: Full Today's Date.
        PlasmaComponents.Label {
            text: calendarRoot.getFormattedTodaySubtitle()
            font.family: Kirigami.Theme.smallFont.family
            font.pixelSize: Math.max(9, Math.round(10 * calendarRoot.effectivePopupScale))
            color: Kirigami.Theme.textColor
            opacity: 0.55
            Layout.fillWidth: true
            Layout.topMargin: -Math.round(6 * calendarRoot.effectivePopupScale)
        }

        // Weekday header with perfectly matched column dimensions.
        GridLayout {
            Layout.fillWidth: true
            columns: calendarRoot.dayColumnCount
            columnSpacing: 0

            Item {
                visible: calendarRoot.showWeekNumbers
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(20 * calendarRoot.effectivePopupScale)

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    text: i18nc("@title:column calendar week number", "#")
                    font.family: Kirigami.Theme.smallFont.family
                    font.pixelSize: Math.max(9, Math.round(11 * calendarRoot.effectivePopupScale))
                    font.weight: Font.Bold
                    color: Kirigami.Theme.textColor
                    opacity: 0.45
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Kirigami.Theme.textColor
                    opacity: 0.15
                }
            }

            Repeater {
                model: calendarRoot.dayNames
                delegate: Item {
                    required property string modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(20 * calendarRoot.effectivePopupScale)

                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Kirigami.Theme.smallFont.family
                        font.pixelSize: Math.max(8, Math.round(10 * calendarRoot.effectivePopupScale))
                        font.weight: Font.DemiBold
                        color: Kirigami.Theme.textColor
                        opacity: 0.6
                    }
                }
            }
        }

        // Calendar grid with six rows. Week numbers are ISO-8601 and optional.
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: calendarRoot.dayColumnCount
            rows: 6
            columnSpacing: 0
            rowSpacing: calendarRoot.scaledBodySpacing

            Repeater {
                model: calendarCellsModel
                delegate: Item {
                    required property bool isWeekNumber
                    required property int weekNumber
                    required property int dayNumber
                    required property bool isCurrentMonth
                    required property bool isToday

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Vertical line for week column separation.
                    Rectangle {
                        visible: isWeekNumber
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: Kirigami.Theme.textColor
                        opacity: 0.12
                    }

                    Rectangle {
                        id: cellBg
                        anchors.centerIn: parent
                        width: Math.max(1, Math.min(parent.width, parent.height) - calendarRoot.scaledCellInset)
                        height: width
                        radius: calendarRoot.scaledCellRadius
                        
                        color: {
                            if (isWeekNumber) return "transparent"
                            if (isToday) return Kirigami.Theme.highlightColor
                            if (cellMouse.containsMouse) return Kirigami.Theme.hoverColor
                            return "transparent"
                        }
                        
                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            text: isWeekNumber ? weekNumber : dayNumber
                            font.family: isWeekNumber ? Kirigami.Theme.smallFont.family : Kirigami.Theme.defaultFont.family
                            font.pixelSize: isWeekNumber
                                ? Math.max(8, Math.round(9 * calendarRoot.effectivePopupScale))
                                : Math.max(10, Math.round(13 * calendarRoot.effectivePopupScale))
                            font.weight: isToday && !isWeekNumber ? Font.Bold : Font.Normal
                            
                            color: isToday && !isWeekNumber
                                ? Kirigami.Theme.highlightedTextColor
                                : Kirigami.Theme.textColor
                            opacity: isWeekNumber ? 0.35 : (isToday || isCurrentMonth ? 1.0 : 0.25)
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            enabled: !isWeekNumber
                            hoverEnabled: true
                            cursorShape: isWeekNumber ? Qt.ArrowCursor : Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }
}
