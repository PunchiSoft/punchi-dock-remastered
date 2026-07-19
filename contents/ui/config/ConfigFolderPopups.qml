import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "components"

Item {
    id: page
    implicitWidth: layoutMetrics.pageImplicitWidth
    implicitHeight: placeholderLabel.implicitHeight
        + (Kirigami.Units.largeSpacing * 2)

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    Controls.Label {
        id: placeholderLabel
        text: i18n("Coming soon")
        anchors.centerIn: parent
        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
        color: Kirigami.Theme.disabledTextColor
    }
}
