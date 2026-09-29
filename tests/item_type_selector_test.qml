// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Window
import QtTest
import "../contents/ui/config" as Config
import "../contents/ui/config/code/itemTypeCatalog.js" as ItemTypeCatalog

// Drop-down selector of the «Add item» dialog.
//
// The cases protect the native ComboBox contract, the canonical catalogue, the
// transactional selection and the visible explanation of unavailable types.
TestCase {
    id: testCase

    name: "ItemTypeSelector"
    when: windowShown

    QtObject {
        id: stubController

        property var items: []
        property string draftType: "app"
        property var unavailable: ["media"]

        function isTypeAvailable(type) {
            return stubController.unavailable.indexOf(String(type)) < 0
        }

        function unavailableReason(type) {
            return stubController.isTypeAvailable(type)
                ? "" : "Only one item of this type can be added."
        }
    }

    Config.ItemTypeSelector {
        id: selector

        width: 340
        draftController: stubController
    }

    SignalSpy {
        id: typeSpy
        target: selector
        signalName: "typeRequested"
    }

    Component {
        id: tallWindowComponent

        Window {
            width: 900
            height: 800
            visible: true

            property alias selector: tallSelector

            Config.ItemTypeSelector {
                id: tallSelector

                x: 120
                y: 120
                width: 340
                draftController: stubController
            }
        }
    }

    function indexOfType(type) {
        return selector.indexOfType(type)
    }

    function init() {
        failOnWarning(/.?/)
        selector.popup.close()
        stubController.unavailable = ["media"]
        stubController.draftType = "app"
        selector.refresh()
        typeSpy.clear()
    }

    function cleanup() {
        selector.popup.close()
    }

    function test_theClosedControlShowsTheDraftType() {
        compare(selector.popup.visible, false,
            "The catalogue must start as a closed drop-down")
        compare(selector.currentIndex, indexOfType("app"))
        compare(String(selector.displayText),
            String(selector.rows[indexOfType("app")].title))
    }

    function test_theEntriesComeFromTheCanonicalCatalogue() {
        const catalogue = ItemTypeCatalog.types()
        compare(selector.rows.length, 11)
        compare(selector.rows.length, catalogue.length)
        for (let index = 0; index < catalogue.length; index++) {
            compare(String(selector.rows[index].type), String(catalogue[index].type))
            compare(String(selector.rows[index].title), String(catalogue[index].title))
            compare(String(selector.rows[index].icon), String(catalogue[index].icon))
            verify(String(selector.rows[index].detail).length > 0,
                "Every option must show a description or a reason")
        }
    }

    function test_anUnavailableTypeStaysVisibleAndExplained() {
        const mediaIndex = indexOfType("media")
        compare(Boolean(selector.rows[mediaIndex].available), false)
        verify(String(selector.rows[mediaIndex].detail).length > 0)
        compare(selector.isEntryAvailable(mediaIndex), false)

        const trashIndex = indexOfType("trash")
        compare(Boolean(selector.rows[trashIndex].available), true)
    }

    function test_openingAndClosingThePopupKeepsTheSelection() {
        selector.popup.open()
        tryVerify(function() {
            return selector.popup.visible
        })
        compare(selector.currentIndex, indexOfType("app"))

        selector.popup.close()
        tryVerify(function() {
            return !selector.popup.visible
        })
        compare(selector.currentIndex, indexOfType("app"))
    }

    function test_popupUsesABoundedScrollableViewport() {
        const host = createTemporaryObject(tallWindowComponent, testCase)
        verify(host !== null)
        tryVerify(function() {
            return host.visible
        })

        const boundedSelector = host.selector
        boundedSelector.refresh()
        boundedSelector.popup.open()
        tryVerify(function() {
            return boundedSelector.popup.visible
        })
        wait(0)

        const popup = boundedSelector.popup
        const viewport = popup.contentItem
        const maximumHeight = boundedSelector.entryHeight * 6
            + popup.topPadding + popup.bottomPadding
        verify(popup.height <= maximumHeight + 0.5,
            "The type popup must not expand beyond six visible entries")
        verify(viewport.contentHeight > viewport.height,
            "The remaining entries must overflow into a scrolling viewport")
        compare(viewport.interactive, true,
            "Wheel, touch and scrollbar input must move the bounded list")

        const scrollBar = viewport.Controls.ScrollBar.vertical
        verify(scrollBar !== null,
            "The bounded type list must expose a vertical scrollbar")
        compare(scrollBar.policy, Controls.ScrollBar.AsNeeded)
        verify(scrollBar.visible,
            "The vertical scrollbar must be visible while entries overflow")

        boundedSelector.popup.close()
        host.destroy()
        wait(0)
    }

    function test_popupScrollsTheCurrentDraftIntoView() {
        stubController.draftType = "trash"
        const host = createTemporaryObject(tallWindowComponent, testCase)
        verify(host !== null)
        tryVerify(function() {
            return host.visible
        })

        const boundedSelector = host.selector
        boundedSelector.refresh()
        compare(boundedSelector.currentIndex, indexOfType("trash"))
        boundedSelector.popup.open()
        tryVerify(function() {
            return boundedSelector.popup.visible
        })
        tryVerify(function() {
            return boundedSelector.popup.contentItem.contentY > 0
        })

        const viewport = boundedSelector.popup.contentItem
        const currentItem = viewport.itemAtIndex(boundedSelector.currentIndex)
        verify(currentItem !== null,
            "The current draft entry must be instantiated in the viewport")
        verify(currentItem.y >= viewport.contentY - 0.5,
            "The current draft entry must not remain above the viewport")
        verify(currentItem.y + currentItem.height
                <= viewport.contentY + viewport.height + 0.5,
            "The current draft entry must remain fully visible after opening")

        boundedSelector.popup.close()
        host.destroy()
        wait(0)
    }

    function test_anUnavailableOptionCannotBeRequested() {
        const mediaIndex = indexOfType("media")
        compare(selector.requestIndex(mediaIndex), false)
        compare(typeSpy.count, 0)
        compare(selector.currentIndex, indexOfType("app"))
    }

    function test_activatingAnOptionAnnouncesOneRequest() {
        const noteIndex = indexOfType("note")
        selector.activated(noteIndex)

        compare(typeSpy.count, 1)
        compare(String(typeSpy.signalArguments[0][0]), "note")
        compare(selector.currentIndex, indexOfType("app"),
            "The drop-down must not preselect a type before the draft accepts it")
    }

    function test_clickingTheContainerDelegateRequestsTheType() {
        const folderIndex = indexOfType("folder")
        const folderDelegate = selector.delegate.createObject(testCase, {
            "index": folderIndex,
            "model": selector.rows[folderIndex]
        })
        verify(folderDelegate !== null,
            "The ComboBox delegate must accept the model role object")
        compare(String(folderDelegate.objectName), "itemTypeEntry-folder")
        compare(folderDelegate.enabled, true,
            "An available Container row must accept pointer input")
        folderDelegate.destroy()
    }

    function test_theSelectionFollowsAnExternalDraftChange() {
        stubController.draftType = "spacer"
        tryCompare(selector, "currentIndex", indexOfType("spacer"))
        compare(String(selector.selectedType), "spacer")
        compare(String(selector.displayText),
            String(selector.rows[indexOfType("spacer")].title))
    }

    function test_refreshReevaluatesAvailabilityWithoutChangingTheDraft() {
        stubController.unavailable = ["media", "trash"]
        selector.refresh()

        compare(Boolean(selector.rows[indexOfType("trash")].available), false)
        compare(selector.currentIndex, indexOfType("app"))
        compare(typeSpy.count, 0)
    }

    function test_focusTargetsTheClosedSelector() {
        selector.focusFirstAvailable()
        tryVerify(function() {
            return selector.activeFocus
        })
        compare(selector.currentIndex, indexOfType("app"))
    }
}
