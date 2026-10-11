import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".."

ColumnLayout {
    id: root

    property alias showSeparator: separatorVisible.checked
    property string separatorAppearanceSource: "theme"
    property string separatorStyle: "line"
    property int separatorThickness: 2
    property real separatorLengthRatio: 0.72
    property real separatorOpacity: 0.34
    property bool separatorGlowEnabled: false
    property bool syncing: false

    function syncOptions() {
        if (root.syncing) { return }
        root.syncing = true
        try {
            options.setSeparatorAppearanceSourceValue(root.separatorAppearanceSource)
            options.setSeparatorStyleValue(root.separatorStyle)
            options.setSeparatorThicknessValue(root.separatorThickness)
            options.setSeparatorLengthRatioValue(root.separatorLengthRatio)
            options.setSeparatorOpacityValue(root.separatorOpacity)
            options.setSeparatorGlowEnabled(root.separatorGlowEnabled)
        } finally {
            root.syncing = false
        }
    }

    function applyItemForm() {
        if (root.syncing) { return }
        root.syncing = true
        try {
            root.separatorAppearanceSource = options.separatorAppearanceSourceValue
            root.separatorStyle = options.separatorStyleValue
            root.separatorThickness = options.separatorThicknessValue
            root.separatorLengthRatio = options.separatorLengthRatioValue
            root.separatorOpacity = options.separatorOpacityValue
            root.separatorGlowEnabled = options.separatorGlowEnabled
        } finally {
            root.syncing = false
        }
    }

    onSeparatorAppearanceSourceChanged: syncOptions()
    onSeparatorStyleChanged: syncOptions()
    onSeparatorThicknessChanged: syncOptions()
    onSeparatorLengthRatioChanged: syncOptions()
    onSeparatorOpacityChanged: syncOptions()
    onSeparatorGlowEnabledChanged: syncOptions()
    Component.onCompleted: syncOptions()

    spacing: Kirigami.Units.smallSpacing

    Controls.Switch {
        id: separatorVisible
        objectName: "recentApplicationsSeparatorVisibleSwitch"
        text: i18n("Show separator") // qmllint disable unqualified
        Accessible.name: text
        checked: true
        activeFocusOnTab: true
        Layout.fillWidth: true
    }

    SeparatorOptions {
        id: options
        objectName: "recentApplicationsSeparatorOptions"
        Layout.fillWidth: true
        enabled: root.showSeparator
        visible: root.showSeparator
        showDescription: false
        hideInactiveAppearanceControls: true
        controller: root
    }
}
