// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/config/components" as ConfigComponents

TestCase {
    id: testCase

    name: "ItemsConfigurationWindow"
    when: windowShown
    property var windowUnderTest: null

    SignalSpy {
        id: commitSpy
        signalName: "commitRequested"
    }

    Component {
        id: windowComponent

        ConfigComponents.ItemsConfigurationWindow {
            motionEnabled: false
            openDuration: 1
            closeDuration: 1
        }
    }

    function initTestCase() {
        // The test runner injects this opt-in helper only for native popup tests.
        // qmllint disable unqualified
        nativePopupTestSupport.allowNativePopupPlatformWarnings()
        // qmllint enable unqualified
    }

    function init() {
        failOnWarning(/.?/)
    }

    function cleanup() {
        commitSpy.target = null
        commitSpy.clear()
        if (windowUnderTest) {
            const target = windowUnderTest
            windowUnderTest = null
            target.closeImmediately()
            wait(0)
            target.destroy()
            wait(0)
        }
    }

    function test_opensOpaqueAndClosesAfterFadeContract() {
        const target = createTemporaryObject(windowComponent, testCase)
        verify(target !== null)
        windowUnderTest = target
        target.sourceJson = JSON.stringify([
            {
                "type": "app",
                "name": "Inherited application",
                "futureProperty": "preserved"
            },
            {
                "type": "trash",
                "name": "Inherited trash"
            }
        ])
        commitSpy.target = target

        compare(target.visible, false)
        compare(target.surfaceOpen, false)
        verify(target.desiredContentWidth > 0)
        verify(target.desiredContentHeight > 0)

        target.openWithReveal()
        tryCompare(target, "visible", true)
        tryCompare(target, "surfaceOpen", true)

        const background = findChild(
            target.mainItem, "itemsConfigurationOpaqueBackground")
        const closeButton = findChild(
            target.mainItem, "itemsConfigurationCloseButton")
        const catalog = findChild(
            target.mainItem, "itemsConfigurationCatalog")
        const preview = findChild(
            target.mainItem, "itemsConfigurationDockPreview")
        const applyButton = findChild(
            target.mainItem, "itemsConfigurationApplyButton")
        verify(background !== null)
        compare(background.imagePath, "solid/dialogs/background")
        compare(background.opacity, 1.0)
        verify(closeButton !== null)
        compare(closeButton.activeFocusOnTab, true)
        verify(catalog !== null)
        verify(preview !== null)
        verify(applyButton !== null)
        compare(target.draftItems.length, 2)
        compare(target.hasPendingChanges, false)
        compare(applyButton.enabled, false)

        verify(target.addDraftItem("separator", 1))
        compare(target.draftItems.length, 3)
        compare(target.draftItems[0].futureProperty, "preserved")
        compare(target.hasPendingChanges, true)
        tryCompare(applyButton, "enabled", true)

        target.requestCommit(false)
        compare(commitSpy.count, 1)
        compare(commitSpy.signalArguments[0][0], target.sourceJson)
        compare(commitSpy.signalArguments[0][2], false)
        compare(target.committing, true)
        target.confirmCommit(commitSpy.signalArguments[0][1], false)
        compare(target.committing, false)
        compare(target.hasPendingChanges, false)

        target.closeWithFade()
        tryCompare(target, "visible", false)
        compare(target.surfaceOpen, false)
    }

    function test_openApplicationsRemovalKeepsLegacyEditor() {
        const target = createTemporaryObject(windowComponent, testCase)
        verify(target !== null)
        windowUnderTest = target
        target.sourceJson = JSON.stringify([{
            "type": "dynamic-applications",
            "name": "Open applications"
        }])

        target.openWithReveal()
        tryCompare(target, "surfaceOpen", true)
        compare(target.selectedItemRemovable, false)

        const removeButton = findChild(
            target.mainItem, "itemsConfigurationRemoveButton")
        verify(removeButton !== null)
        compare(removeButton.enabled, false)

        compare(target.removeDraftItem(0), false)
        compare(target.commitErrorCode, "requires-legacy-editor")
        compare(target.draftItems.length, 1)
        compare(target.hasPendingChanges, false)
        verify(target.errorMessage().length > 0)

        // Any other element type keeps its removal available.
        verify(target.addDraftItem("separator", 1))
        compare(removeButton.enabled, true)
        verify(target.removeDraftItem(1))
        compare(target.commitErrorCode, "")
        compare(target.draftItems.length, 1)
    }

    function test_catalogOffersEveryElementAndGatesSingletons() {
        const target = createTemporaryObject(windowComponent, testCase)
        verify(target !== null)
        windowUnderTest = target
        target.sourceJson = JSON.stringify([
            { "type": "punchimenu", "name": "PunchiMenu" },
            { "type": "app", "name": "Konsole" }
        ])

        target.openWithReveal()
        tryCompare(target, "surfaceOpen", true)

        const catalog = findChild(
            target.mainItem, "itemsConfigurationCatalog")
        verify(catalog !== null)
        compare(catalog.count, 10)

        const offered = []
        const disabled = []
        for (let index = 0; index < catalog.count; index++) {
            const tile = catalog.itemAtIndex(index)
            verify(tile !== null)
            offered.push(String(tile.itemType))
            if (!tile.enabled) {
                disabled.push(String(tile.itemType))
            }

            // The tooltip lives in its own Plasma window and belongs to the
            // tile, so it is never clipped by the configuration surface.
            const toolTip = findChild(
                tile, "itemsConfigurationTileToolTip")
            verify(toolTip !== null)
            verify(toolTip.parent === tile)
            verify(String(toolTip.mainText).length > 0)
            if (tile.enabled) {
                verify(String(toolTip.subText).length > 0)
            } else {
                compare(String(toolTip.subText), "")
            }
        }
        for (const actionToolTip of [
            "itemsConfigurationMoveLeftToolTip",
            "itemsConfigurationMoveRightToolTip",
            "itemsConfigurationRemoveToolTip",
            "itemsConfigurationCloseToolTip"
        ]) {
            verify(findChild(target.mainItem, actionToolTip) !== null)
        }
        compare(offered.indexOf("dynamic-applications"), -1)
        compare(offered.indexOf("punchimenu") >= 0, true)
        compare(offered.indexOf("control-center") >= 0, true)
        compare(offered.indexOf("media") >= 0, true)
        compare(offered.indexOf("calendar") >= 0, true)
        compare(offered.indexOf("note") >= 0, true)
        compare(offered.indexOf("spacer") >= 0, true)
        // Only the singleton already present stays unavailable.
        compare(disabled.length, 1)
        compare(disabled[0], "punchimenu")

        // Every offered tile stays inside the visible catalog area.
        const rows = Math.ceil(catalog.count
            / Math.floor(catalog.width / catalog.cellWidth))
        compare(catalog.height >= rows * catalog.cellHeight - 0.5, true)
    }

    function test_catalogTileDoesNotPaintProgrammaticFocus() {
        const target = createTemporaryObject(windowComponent, testCase)
        verify(target !== null)
        windowUnderTest = target
        target.sourceJson = JSON.stringify([])

        target.openWithReveal()
        tryCompare(target, "surfaceOpen", true)

        const catalog = findChild(
            target.mainItem, "itemsConfigurationCatalog")
        verify(catalog !== null)

        // Opening grants a programmatic focus. The tile keeps that focus for
        // keyboard and assistive access, but must not paint the focus ring: the
        // shared Plasma tooltip dialog serves one area at a time, so a ring and
        // a tooltip for a focus the user did not ask for fought the hovered
        // tile. Control.focusReason is only fed by real navigation events, so
        // the keyboard path stays covered by the static development contract
        // and by the visual check in Plasma.
        const tile = catalog.itemAtIndex(0)
        verify(tile !== null)
        tryCompare(tile, "activeFocus", true)
        compare(tile.keyboardFocusVisible, false)

        const secondTile = catalog.itemAtIndex(1)
        verify(secondTile !== null)
        secondTile.forceActiveFocus()
        tryCompare(secondTile, "activeFocus", true)
        compare(secondTile.keyboardFocusVisible, false)
    }

    function test_cancelDiscardsDraftOnNextOpen() {
        const target = createTemporaryObject(windowComponent, testCase)
        verify(target !== null)
        windowUnderTest = target
        target.sourceJson = JSON.stringify([{
            "type": "folder",
            "name": "Existing folder",
            "unknown": 9
        }])

        target.openWithReveal()
        tryCompare(target, "surfaceOpen", true)
        compare(target.draftItems.length, 1)
        verify(target.addDraftItem("trash", 1))
        compare(target.draftItems.length, 2)

        target.cancelDraft()
        tryCompare(target, "visible", false)
        target.openWithReveal()
        tryCompare(target, "surfaceOpen", true)
        compare(target.draftItems.length, 1)
        compare(target.draftItems[0].unknown, 9)
    }
}
