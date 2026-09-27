// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
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
