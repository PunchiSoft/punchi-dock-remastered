// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml
import org.kde.kcmutils as KCMUtils

QtObject {
    id: root

    property var applicationLauncher: null

    function openSettings(section) {
        let moduleName = ""
        switch (String(section || "")) {
        case "network":
            moduleName = "kcm_networkmanagement"
            break
        case "bluetooth":
            moduleName = "kcm_bluetooth"
            break
        case "sound":
            moduleName = "kcm_pulseaudio"
            break
        case "display":
            moduleName = "kcm_kscreen"
            break
        case "notifications":
            moduleName = "kcm_notifications"
            break
        case "appearance":
            moduleName = "kcm_lookandfeel"
            break
        case "nightlight":
            moduleName = "kcm_nightlight"
            break
        default:
            return false
        }

        KCMUtils.KCMLauncher.openSystemSettings(moduleName)
        return true
    }

    function openApplication(action) {
        if (!applicationLauncher) {
            return false
        }

        switch (String(action || "")) {
        case "updates":
            if (applicationLauncher.launchApplicationAction(
                    "org.kde.discover.desktop", "Updates")) {
                return true
            }
            applicationLauncher.launchApplication(
                "org.kde.discover.desktop")
            return true
        case "calculator":
            applicationLauncher.launchApplication("org.kde.kcalc.desktop")
            return true
        default:
            return false
        }
    }
}
