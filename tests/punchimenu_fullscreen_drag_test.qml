// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components/punchimenu" as PunchiMenu

// Guards the fullscreen press-and-hold entry point: the gesture must reach
// PunchiMenuDragLayer before any drop can be resolved.
TestCase {
    id: testCase

    name: "PunchiMenuFullscreenDrag"
    when: windowShown

    property var hostWindowUnderTest: null

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 1280
            height: 800
            visible: true

            property alias overlay: overlay

            PunchiMenu.PunchiMenuOverlay {
                id: overlay
                anchors.fill: parent
                systemDiscovery: null
                applicationCatalog: [
                    { name: "Alpha", icon: "applications-other", storageId: "alpha.desktop" },
                    { name: "Bravo", icon: "applications-other", storageId: "bravo.desktop" },
                    { name: "Charlie", icon: "applications-other", storageId: "charlie.desktop" },
                    { name: "Delta", icon: "applications-other", storageId: "delta.desktop" }
                ]
                applicationCatalogLoaded: true
                applicationLayoutController: controller
                menuOpen: true
            }

            QtObject {
                id: controller

                signal transactionCommitted(string transactionId,
                    string operation, string subjectId)
                signal transactionFailed(string transactionId,
                    string operation, string errorCode)

                property var layoutDocument: ({
                    version: 1,
                    nodes: [
                        { type: "application", storageId: "alpha.desktop" },
                        { type: "application", storageId: "bravo.desktop" },
                        { type: "application", storageId: "charlie.desktop" },
                        { type: "application", storageId: "delta.desktop" }
                    ]
                })
                property bool transactionPending: false
                property bool canUndo: false

                function requestMoveNode(nodeId, beforeNodeId) {
                    return { accepted: true }
                }
                function requestAddApplicationToFolder(storageId, folderId) {
                    return { accepted: true }
                }
                function discardUndoHistory() {
                }
                function requestUndo() {
                    return { accepted: false }
                }
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
    }

    function cleanup() {
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
    }

    function collectHighlights(item, result) {
        for (let index = 0; index < item.children.length; ++index) {
            const child = item.children[index]
            if (String(child).indexOf("PunchiMenuItemHighlight") === 0) {
                result.push(child)
            } else {
                collectHighlights(child, result)
            }
        }
        return result
    }

    function createHostWindow() {
        hostWindowUnderTest = createTemporaryObject(windowComponent, null)
        verify(hostWindowUnderTest !== null)
        wait(150)
        return hostWindowUnderTest
    }

    function test_pressAndHoldStartsFullscreenDrag() {
        const hostWindow = createHostWindow()
        const overlay = hostWindow.overlay
        compare(overlay.visibleApplications.length, 4,
            "organized listing exposes every application")

        const highlights = collectHighlights(overlay, [])
        compare(highlights.length >= 2, true,
            "first page exposes launcher items")

        const sourcePoint = highlights[0].mapToItem(overlay,
            highlights[0].width / 2, highlights[0].height / 2)

        mousePress(overlay, sourcePoint.x, sourcePoint.y, Qt.LeftButton)
        wait(1200)
        compare(overlay.suppressDragReleaseClick, true,
            "press-and-hold starts the internal layout drag")

        mouseRelease(overlay, sourcePoint.x, sourcePoint.y, Qt.LeftButton)
        wait(50)
    }

}
