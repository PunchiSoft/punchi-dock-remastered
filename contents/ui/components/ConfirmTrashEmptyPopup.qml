import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: confirmRoot
    width: 260
    height: 124
    implicitWidth: width
    implicitHeight: height

    signal confirmRequested()
    signal cancelRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        PlasmaComponents.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Do you want to empty the trash?")
            color: Kirigami.Theme.textColor
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8

            Controls.Button {
                text: i18n("Cancel")
                onClicked: confirmRoot.cancelRequested()
            }

            Controls.Button {
                text: i18n("Yes")
                icon.name: "trash-empty"
                onClicked: confirmRoot.confirmRequested()
            }
        }
    }
}
