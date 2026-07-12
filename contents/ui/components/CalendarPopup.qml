import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: calendarRoot
    implicitWidth: 320
    implicitHeight: 300
    width: implicitWidth
    height: implicitHeight

    property date displayedDate: new Date()
    property date today: new Date()
    signal closeRequested()

    // Formateador nativo de KDE/Qt Locale para traducciones automáticas del sistema
    property var dayNames: {
        var locale = Qt.locale()
        var days = []
        // Generar nombres cortos de días empezando en Lunes (1) a Domingo (7/0 en Qt)
        for (var i = 1; i <= 7; i++) {
            var dayNum = (i === 7) ? 0 : i
            days.push(locale.standaloneDayName(dayNum, Locale.NarrowFormat))
        }
        return days
    }

    function getFormattedMonthYear() {
        var locale = Qt.locale()
        var monthName = locale.standaloneMonthName(displayedDate.getMonth(), Locale.LongFormat)
        // Capitalizar primera letra del mes
        monthName = monthName.charAt(0).toUpperCase() + monthName.slice(1)
        return monthName + " " + displayedDate.getFullYear()
    }

    // Navegar meses
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

    // Modelo de días (42 celdas para cubrir cualquier mes)
    ListModel {
        id: daysModel
    }

    function updateGrid() {
        daysModel.clear();
        var year = displayedDate.getFullYear();
        var month = displayedDate.getMonth();

        // Días en el mes actual y primer día de la semana (Lunes=0...Domingo=6)
        var daysInMonth = new Date(year, month + 1, 0).getDate();
        var firstDayIndex = new Date(year, month, 1).getDay();
        firstDayIndex = (firstDayIndex === 0) ? 6 : firstDayIndex - 1;

        // Días en el mes anterior (para rellenar huecos)
        var prevMonthDays = new Date(year, month, 0).getDate();

        // Rellenar días del mes anterior
        for (var i = firstDayIndex - 1; i >= 0; i--) {
            daysModel.append({
                dayNumber: prevMonthDays - i,
                isCurrentMonth: false,
                isToday: false
            });
        }

        // Rellenar días del mes actual
        for (var j = 1; j <= daysInMonth; j++) {
            var isItToday = (j === today.getDate() && 
                             month === today.getMonth() && 
                             year === today.getFullYear());
            daysModel.append({
                dayNumber: j,
                isCurrentMonth: true,
                isToday: isItToday
            });
        }

        // Rellenar días del mes siguiente hasta completar las 42 celdas
        var remainingCells = 42 - daysModel.count;
        for (var k = 1; k <= remainingCells; k++) {
            daysModel.append({
                dayNumber: k,
                isCurrentMonth: false,
                isToday: false
            });
        }
    }

    Component.onCompleted: updateGrid()

    onVisibleChanged: {
        if (visible) {
            displayedDate = new Date()
            updateGrid()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header (Mes y Año con controles de navegación)
        RowLayout {
            Layout.fillWidth: true
            
            PlasmaComponents.Label {
                text: calendarRoot.getFormattedMonthYear()
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.weight: Font.Bold
                color: Kirigami.Theme.textColor
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 8
                
                // Botón Anterior
                Rectangle {
                    width: 28; height: 28; radius: 6
                    color: prevMouse.containsMouse || prevMouse.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    border.width: prevMouse.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.highlightColor
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 16; height: 16
                        source: "go-previous-symbolic"
                    }
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent; hoverEnabled: true
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: i18n("Mes anterior")
                        onClicked: prevMonth()
                        Keys.onReturnPressed: prevMonth()
                        Keys.onSpacePressed: prevMonth()
                    }
                }

                // Botón Siguiente
                Rectangle {
                    width: 28; height: 28; radius: 6
                    color: nextMouse.containsMouse || nextMouse.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    border.width: nextMouse.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.highlightColor
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 16; height: 16
                        source: "go-next-symbolic"
                    }
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent; hoverEnabled: true
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: i18n("Mes siguiente")
                        onClicked: nextMonth()
                        Keys.onReturnPressed: nextMonth()
                        Keys.onSpacePressed: nextMonth()
                    }
                }

                Rectangle {
                    width: 28; height: 28; radius: 6
                    color: closeMouse.containsMouse || closeMouse.activeFocus ? Kirigami.Theme.negativeTextColor : "transparent"
                    border.width: closeMouse.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.negativeTextColor

                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        text: "×"
                        color: Kirigami.Theme.textColor
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

        // Días de la semana (Cabecera L, M, M, J...)
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: dayNames
                delegate: PlasmaComponents.Label {
                    text: modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Kirigami.Theme.smallFont.family
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.weight: Font.DemiBold
                    color: Kirigami.Theme.textColor
                    opacity: 0.5
                }
            }
        }

        // Rejilla del calendario (42 días)
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rows: 6
            columnSpacing: 0
            rowSpacing: 4

            Repeater {
                model: daysModel
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 4
                        height: width
                        radius: 6
                        
                        // Resaltado de hoy vs selección vs días comunes
                        color: isToday ? Kirigami.Theme.highlightColor : "transparent"
                        
                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            text: dayNumber
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.weight: isToday ? Font.Bold : Font.Normal
                            
                            // Días fuera del mes actual se ven atenuados
                            color: isToday ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                            opacity: isToday || isCurrentMonth ? 1 : 0.3
                        }
                    }
                }
            }
        }
    }
}
