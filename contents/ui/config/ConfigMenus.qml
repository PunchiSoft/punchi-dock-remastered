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

    readonly property bool interactiveCursorEnabled:
        !!Plasmoid.configuration.globalMouseCursor
    readonly property int contentWidthHint: layoutMetrics.contentWidth

    // qmllint disable unqualified
    Kirigami.FormLayout {
        id: menuForm
        width: page.width

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
