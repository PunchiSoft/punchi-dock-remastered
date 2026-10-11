// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "MediaDockItemLifecycle"
    when: windowShown

    Component {
        id: hostComponent
        Item {
            width: 240
            height: 64
            property alias loader: mediaLoader
            Loader {
                id: mediaLoader
                anchors.fill: parent
                sourceComponent: Components.MediaDockItem {
                    textMode: "always"
                }
            }
        }
    }

    function init() { failOnWarning(/.?/) }

    Component {
        id: repeaterHostComponent
        Item {
            property alias entries: mediaRepeater.model
            property alias repeater: mediaRepeater
            Repeater {
                id: mediaRepeater
                model: [{ name: "First" }]
                Components.MediaDockItem {
                    width: 240
                    height: 64
                    textMode: "always"
                }
            }
        }
    }

    function test_replaceDockModelBeforeDeferredMetadataUpdate() {
        const host = createTemporaryObject(repeaterHostComponent, testCase)
        verify(host)
        for (let cycle = 0; cycle < 12; cycle++) {
            verify(host.repeater.itemAt(0))
            host.repeater.itemAt(0).defaultPlayerName = "Player " + cycle
            host.entries = [{ name: "Replacement " + cycle }]
            wait(0)
        }
        host.entries = []
        wait(0)
        compare(host.repeater.count, 0)
        host.entries = [{ name: "Recreated" }]
        wait(0)
        verify(host.repeater.itemAt(0))
        host.destroy()
        wait(0)
    }

    function test_destroyBeforeDeferredMetadataUpdate() {
        const host = createTemporaryObject(hostComponent, testCase)
        verify(host)
        for (let cycle = 0; cycle < 12; cycle++) {
            verify(host.loader.item)
            host.loader.item.defaultPlayerName = "Player " + cycle
            // Creation queues the metadata callback. Unloading in the same
            // event turn must not leave work accessing the destroyed item.
            host.loader.active = false
            compare(host.loader.item, null)
            wait(0)
            host.loader.active = true
            verify(host.loader.item)
        }
        host.loader.active = false
        wait(0)
        host.loader.active = true
        tryCompare(host.loader, "status", Loader.Ready)
        wait(0)
        verify(host.loader.item.metadataText.length > 0)
        host.destroy()
        wait(0)
    }
}
