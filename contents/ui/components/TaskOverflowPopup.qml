import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var entries: []
    property int maxVisibleRows: 4
    readonly property int rowHeight: 48
    readonly property int visibleRows: Math.max(1, Math.min(maxVisibleRows, entries.length))

    implicitWidth: 300
    implicitHeight: Math.min(420, header.implicitHeight + 24 + visibleRows * rowHeight)
    width: implicitWidth
    height: implicitHeight

    signal entryActivated(var entry)
    signal closeRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            id: header
            Layout.fillWidth: true

            Controls.Label {
                Layout.fillWidth: true
                text: i18n("More window groups")
                font.bold: true
                elide: Text.ElideRight
            }

            Controls.ToolButton {
                icon.name: "window-close-symbolic"
                display: Controls.AbstractButton.IconOnly
                Accessible.name: i18n("Close window group list")
                onClicked: root.closeRequested()
            }
        }

        Controls.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff

            ListView {
                model: root.entries
                spacing: 2

                delegate: Controls.ItemDelegate {
                    required property var modelData
                    width: ListView.view.width
                    height: root.rowHeight
                    text: modelData.name
                    icon.name: modelData.icon
                    Accessible.description: i18np("%1 open window", "%1 open windows", modelData.count)
                    onClicked: root.entryActivated(modelData)

                    contentItem: RowLayout {
                        spacing: 8

                        Kirigami.Icon {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            source: modelData.icon
                        }

                        Controls.Label {
                            Layout.fillWidth: true
                            text: modelData.name
                            elide: Text.ElideRight
                        }

                        Controls.Label {
                            text: String(modelData.count)
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }
                }
            }
        }
    }
}
