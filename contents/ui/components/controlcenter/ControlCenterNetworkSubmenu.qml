// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// Inline Wi-Fi submenu of the Control Center home page.
//
// It is the expandable section that already governs the Night Light reveal, used
// out of the layout flow: the home page places it right below the row that asked
// for it and pushes the rest of the page downwards with the same growth, so the
// remaining content leaves the frame through its bottom edge. The section is only
// as tall as the space left below itself, which makes that exit exact.

ControlCenterExpandableSection {
    id: root

    property var adapter: null

    signal settingsRequested(string section)

    function focusFirstControl(reason) {
        const page = networkLoader.item as ControlCenterNetworkPage
        if (page) {
            page.focusFirstControl(reason)
            return true
        }
        return false
    }

    function showError(message) {
        const page = networkLoader.item as ControlCenterNetworkPage
        if (page) {
            page.showError(message)
        }
    }

    // The network page exists only while the reveal is on screen, so the list of
    // networks is not built for a section nobody is looking at.
    Loader {
        id: networkLoader

        anchors.fill: parent
        active: root.adapter !== null && root.expansionProgress > 0.001
        sourceComponent: Component {
            ControlCenterNetworkPage {
                inlineMode: true
                adapter: root.adapter
                onSettingsRequested: function(section) {
                    root.settingsRequested(section)
                }
            }
        }
    }
}
