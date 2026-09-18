// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../org/punchi/dock" as Punchi
import "components"

// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
KCM.SimpleKCM {
    id: page

    title: i18n("Development")
    implicitWidth: layoutMetrics.pageImplicitWidth
    implicitHeight: contentColumn.implicitHeight

    property string cfg_dockItemsJson: ""

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    ColumnLayout {
        id: contentColumn

        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        Controls.Button {
            id: configureItemsButton

            objectName: "configureItemsButton"
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            text: i18nc("@action:button", "Configure items")
            icon.name: "configure"
            Accessible.name: text
            onClicked: {
                panelRevealAdapter.beginReveal()
                itemsConfigurationWindow.openWithReveal()
            }
        }
    }

    ItemsConfigurationWindow {
        id: itemsConfigurationWindow

        ownerWindow: page.Window.window
        sourceJson: page.cfg_dockItemsJson
        onConcealed: {
            panelRevealAdapter.endReveal()
            configureItemsButton.forceActiveFocus(Qt.PopupFocusReason)
        }
        onCommitRequested: function(expectedRaw, nextRaw, closeAfterCommit) {
            const result = dockItemsPersistenceAdapter.commitDockItemsJson(
                expectedRaw, nextRaw)
            if (result && result.success) {
                const committed = String(result.currentJson || nextRaw)
                page.cfg_dockItemsJson = committed
                itemsConfigurationWindow.confirmCommit(
                    committed, closeAfterCommit)
                return
            }
            itemsConfigurationWindow.rejectCommit(
                result ? String(result.errorCode || "persistence-failed")
                       : "persistence-failed",
                result ? String(result.currentJson || "") : "")
        }
    }

    Punchi.DockItemsPersistenceAdapter {
        id: dockItemsPersistenceAdapter
        applet: Plasmoid
    }

    // Keeps the dock visible while its items are edited, even when the panel that
    // hosts it is set to auto hide or to dodge windows. Only the containment of
    // this applet receives a temporary attention status; panel edit mode and the
    // user's visibility preference stay untouched.
    Punchi.PanelRevealAdapter {
        id: panelRevealAdapter

        objectName: "panelRevealAdapter"
        applet: Plasmoid
    }
}
// qmllint enable unqualified
