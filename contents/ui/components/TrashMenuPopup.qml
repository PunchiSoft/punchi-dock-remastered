import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: trashMenuRoot
    implicitWidth: 220
    implicitHeight: 136
    width: implicitWidth
    height: implicitHeight

    signal openTrashClicked()
    signal emptyTrashClicked()
    signal closeRequested()

    function focusFirstAction() {
        openOption.forceActiveFocus(Qt.TabFocusReason)
    }

    function clearActionFocus() {
        trashMenuRoot.forceActiveFocus(Qt.MouseFocusReason)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Cabecera / Título
        RowLayout {
            Layout.fillWidth: true
            
            PlasmaExtras.ShadowedLabel {
                text: i18n("Trash")
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            
            // Botón de cerrar
            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 10
                color: closeMouse.containsMouse || closeMouse.activeFocus ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.backgroundColor
                
                PlasmaComponents.Label {
                    text: "×"
                    anchors.centerIn: parent
                    color: Kirigami.Theme.textColor
                }
                
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: i18n("Close")
                    onClicked: {
                        trashMenuRoot.closeRequested()
                    }
                }
            }
        }

        // Opción: Abrir Papelera
        Controls.ItemDelegate {
            id: openOption
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            text: i18n("Open trash")
            icon.name: "folder-open"
            
            onClicked: {
                trashMenuRoot.openTrashClicked()
            }
        }

        // Opción: Vaciar Papelera
        Controls.ItemDelegate {
            id: emptyOption
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            text: i18n("Empty trash")
            icon.name: "trash-empty"
            
            onClicked: {
                trashMenuRoot.emptyTrashClicked()
            }
        }
    }
}
