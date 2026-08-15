import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import "components"

// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
KCM.SimpleKCM {
    id: page

    title: i18n("Additional Shortcuts")
    implicitWidth: layoutMetrics.pageImplicitWidth
    implicitHeight: contentColumn.implicitHeight

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    property string cfg_punchiMenuShortcut: ""
    property bool updatingShortcut: false

    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth

    function syncShortcutControl() {
        updatingShortcut = true
        shortcutItem.keySequence = cfg_punchiMenuShortcut
        updatingShortcut = false
    }

    onCfg_punchiMenuShortcutChanged: syncShortcutControl()

    Component.onCompleted: syncShortcutControl()

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 0

        Kirigami.FormLayout {
            Layout.fillWidth: true

            KQuickControls.KeySequenceItem {
                id: shortcutItem
                Kirigami.FormData.label: i18n("Open or close PunchiMenu:")
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                showCancelButton: true
                // Keep the Plasma 6.0-compatible properties. ShortcutPattern was
                // introduced in a later KF6 release.
                // qmllint disable deprecated
                modifierOnlyAllowed: true
                modifierlessAllowed: false
                // qmllint enable deprecated
                Accessible.name: i18n("PunchiMenu keyboard shortcut")
                Accessible.description: i18n(
                    "Opens or closes PunchiMenu independently from Plasma's widget activation shortcut.")
                onKeySequenceModified: {
                    if (!page.updatingShortcut) {
                        // QKeySequence exposes toString() at runtime, but the Qt
                        // QML metadata does not advertise the method to qmllint.
                        // qmllint disable missing-property
                        page.cfg_punchiMenuShortcut = keySequence.toString()
                        // qmllint enable missing-property
                    }
                }
            }

            Controls.Label {
                text: i18n(
                    "This shortcut is independent from Plasma's widget activation shortcut.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                leftPadding: layoutMetrics.helperIndent
                color: Kirigami.Theme.disabledTextColor
            }
        }
    }
}
// qmllint enable unqualified
