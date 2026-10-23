// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components/punchimenu" as PunchiMenu
import org.punchi.dock as Punchi

// Reordering applications is a silent layout change: it must not raise the
// folder notice, while folder operations keep reporting their result.
TestCase {
    id: testCase

    name: "PunchiMenuReorderNotice"

    Component {
        id: normalComponent

        PunchiMenu.PunchiMenuNormal {
            systemDiscovery: QtObject {
                function requestApplications() {
                }
                function launchApplication(storageId) {
                }
                function launchApplicationByCommand(command) {
                }
            }
            favorites: []
            applicationCatalog: [
                { name: "Alpha", icon: "applications-other", storageId: "alpha.desktop" },
                { name: "Bravo", icon: "applications-other", storageId: "bravo.desktop" }
            ]
            applicationLayoutController: Punchi.PunchiMenuLayoutController {
                layoutDocument: ({
                    version: 1,
                    nodes: [
                        { type: "application", storageId: "alpha.desktop" },
                        { type: "application", storageId: "bravo.desktop" }
                    ]
                })
                applicationStorageIds: ["alpha.desktop", "bravo.desktop"]
            }
            menuOpen: true
        }
    }

    Component {
        id: fullscreenComponent

        PunchiMenu.PunchiMenuOverlay {
            systemDiscovery: QtObject {
                function requestApplications() {
                }
                function launchApplication(storageId) {
                }
                function launchApplicationByCommand(command) {
                }
            }
            applicationCatalog: [
                { name: "Alpha", icon: "applications-other", storageId: "alpha.desktop" },
                { name: "Bravo", icon: "applications-other", storageId: "bravo.desktop" }
            ]
            applicationCatalogLoaded: true
            applicationLayoutController: Punchi.PunchiMenuLayoutController {
                layoutDocument: ({
                    version: 1,
                    nodes: [
                        { type: "application", storageId: "alpha.desktop" },
                        { type: "application", storageId: "bravo.desktop" }
                    ]
                })
                applicationStorageIds: ["alpha.desktop", "bravo.desktop"]
            }
            menuOpen: true
        }
    }

    function init() {
        failOnWarning(/.?/)
    }

    function commitReorder(menu) {
        const controller = menu.applicationLayoutController
        const result = controller.requestMoveNode(
            "application:bravo.desktop", "application:alpha.desktop")
        verify(result.accepted === true,
            "move rejected: " + JSON.stringify(result))
        controller.confirmPersistence(controller.pendingTransactionId)
        wait(50)
    }

    function test_normalReorderDoesNotShowNotice() {
        const menu = createTemporaryObject(normalComponent, null)
        verify(menu !== null)
        wait(50)

        commitReorder(menu)
        compare(menu.operationMessage, "",
            "reordering must not raise the folder notice in Normal")
    }

    function test_fullscreenReorderDoesNotShowNotice() {
        const overlay = createTemporaryObject(fullscreenComponent, null)
        verify(overlay !== null)
        wait(50)

        commitReorder(overlay)
        compare(overlay.operationMessage, "",
            "reordering must not raise the folder notice in Fullscreen")
    }

    function test_normalFolderCreationKeepsNotice() {
        const menu = createTemporaryObject(normalComponent, null)
        verify(menu !== null)
        wait(50)

        const controller = menu.applicationLayoutController
        const result = controller.requestCreateFolder(
            "alpha.desktop", "bravo.desktop", "Group")
        verify(result.accepted === true,
            "folder creation rejected: " + JSON.stringify(result))
        controller.confirmPersistence(controller.pendingTransactionId)
        wait(50)

        verify(menu.operationMessage.length > 0,
            "folder operations must keep reporting their result")
    }
}
