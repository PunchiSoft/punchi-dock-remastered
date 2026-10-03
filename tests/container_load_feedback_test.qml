// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtCore
import QtQuick.Layouts
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/config" as Config

TestCase {
    id: testCase
    name: "ContainerLoadFeedback"
    when: windowShown
    visible: true
    width: 820
    height: 700

    property var page: null
    property var dialog: null
    property var editor: null
    property var message: null
    property var mainView: null

    Component {
        id: pageComponent
        Config.ConfigItems {
            width: testCase.width
            height: testCase.height
            // Disk loading and the legacy selected-item form are outside this
            // test. Keep the real add-dialog, routing and native discovery graph.
            function loadItems() {}
        }
    }

    function init() {
        failOnWarning(/.?/)
        page = createTemporaryObject(pageComponent, testCase)
        verify(page !== null)
        dialog = findChild(page, "itemConfigurationDialog")
        mainView = findChild(page, "itemsConfigurationMainView")
        verify(dialog !== null)
        verify(mainView !== null)
        dialog.openFor("folder")
        tryCompare(dialog, "opened", true)
        editor = findChild(dialog, "itemConfigurationEditorPanel")
        message = findChild(editor, "containerLoadStatusMessage")
        verify(message !== null)
        setSource("folder", "")
        compare(message.visible, false)
        compare(mainView.statusText, "")
    }

    function cleanup() {
        if (dialog !== null) {
            dialog.cancelDraft()
            tryCompare(dialog, "opened", false)
        }
        page = null
        dialog = null
        editor = null
        message = null
        mainView = null
    }

    function setSource(source, path) {
        dialog.draftController.setDraftValues({sourceType: source,
            sourcePath: path, sourceCategory: "Network"})
        dialog.refreshEditorFields()
    }

    function assertNoDockChanges() {
        compare(page.items.length, 0)
        compare(page.cfg_dockItemsJson, "")
    }

    function test_emptyFolderWarningBelongsToModal() {
        editor.containerRefreshRequested()
        tryCompare(message, "visible", true)
        compare(message.text, "Choose a folder first.")
        compare(message.type, Kirigami.MessageType.Warning)
        compare(mainView.statusText, "", "No feedback behind the modal")
        compare(dialog.draftController.pendingExternalOperation, null)
        compare(dialog.draftController.draftValid, false)
        assertNoDockChanges()
    }

    function test_folderErrorFromNativeDiscoveryBelongsToModal() {
        setSource("folder", StandardPaths.writableLocation(StandardPaths.RuntimeLocation)
            + "/fixtures/missing-folder")
        editor.containerRefreshRequested()
        tryVerify(function() { return message.text.length > 0 }, 5000)
        compare(message.type, Kirigami.MessageType.Error)
        verify(message.text.indexOf("System operation failed: ") === 0)
        compare(mainView.statusText, "")
        compare(dialog.draftController.pendingExternalOperation, null)
        assertNoDockChanges()
    }

    function test_typingClearsWarningAndInvalidatesOnlyContent() {
        editor.containerRefreshRequested()
        tryCompare(message, "visible", true)
        const controller = dialog.draftController
        const requestId = controller.beginExternalOperation("container-folder", "folder", {})
        const field = findChild(editor, "containerPathField")
        field.forceActiveFocus()
        keyClick(Qt.Key_A)
        compare(message.visible, false)
        compare(controller.pendingExternalOperation, null)
        page.showDiscoveryFailure("Late folder failure", requestId)
        compare(message.visible, false)
        compare(mainView.statusText, "")
        const iconId = controller.beginExternalOperation("icon", "item", {})
        keyClick(Qt.Key_B)
        compare(controller.pendingExternalOperation.id, iconId,
            "Editing a path must not cancel an unrelated picker")
        controller.clearExternalOperation()
        assertNoDockChanges()
    }

    function test_retryReadsCurrentPathAndSuccessClearsFeedback() {
        editor.containerRefreshRequested()
        tryCompare(message, "visible", true)
        editor.containerPathText = StandardPaths.writableLocation(StandardPaths.RuntimeLocation)
            + "/fixtures/populated"
        // No editingFinished: the load action must commit the current field.
        editor.containerRefreshRequested()
        compare(message.visible, false)
        tryCompare(dialog.draftController, "pendingExternalOperation", null, 5000)
        compare(dialog.draftController.draft.sourcePath, editor.containerPathText)
        compare(dialog.draftController.nestedCount(), 2)
        compare(findChild(dialog, "itemConfigurationActionEditor").actionModel.count, 2)
        compare(mainView.statusText, "")
        assertNoDockChanges()
    }

    function test_sourceAndCategoryChangesClearFeedback() {
        editor.containerRefreshRequested()
        tryCompare(message, "visible", true)
        editor.containerSourceIndex = editor.sourceIndexFor("category")
        editor.containerSourceChanged("category")
        compare(message.visible, false)
        const requestId = dialog.draftController.beginExternalOperation(
            "container-applications", "category", {})
        page.showDiscoveryFailure("Category discovery failed", requestId)
        tryCompare(message, "visible", true)
        compare(message.type, Kirigami.MessageType.Error)
        editor.containerCategoryIndex = editor.categoryIndexFor("Office")
        editor.containerCategoryChanged("Office")
        compare(message.visible, false)
        compare(mainView.statusText, "")
        assertNoDockChanges()
    }

    function test_closeReopenAndTypeChangeDiscardFeedback() {
        editor.containerRefreshRequested()
        tryCompare(message, "visible", true)
        const requestId = dialog.draftController.beginExternalOperation("container-folder", "folder", {})
        dialog.cancelDraft()
        tryCompare(dialog, "opened", false)
        compare(dialog.containerLoadStatusText, "")
        dialog.openFor("folder")
        tryCompare(dialog, "opened", true)
        setSource("folder", "")
        page.showDiscoveryFailure("Previous draft failed", requestId)
        compare(message.visible, false)
        compare(mainView.statusText, "")
        editor.containerRefreshRequested()
        tryCompare(message, "visible", true)
        dialog.requestType("app")
        if (dialog.pendingTypeChange.length > 0) {
            dialog.confirmTypeChange()
        }
        compare(dialog.containerLoadStatusText, "")
        compare(message.visible, false)
        assertNoDockChanges()
    }

    function test_pageOperationsRetainPageFeedback() {
        page.showDiscoveryFailure("Page operation failed", 0)
        compare(mainView.statusText, "System operation failed: Page operation failed")
        compare(message.visible, false)
        mainView.clearStatus()
    }

    function test_inlineGeometry_data() {
        return [{tag: "compact", width: 570}, {tag: "wide", width: 820}]
    }

    function test_inlineGeometry(data) {
        page.width = data.width
        editor.containerRefreshRequested()
        tryVerify(function() { return message.visible && message.height > 0
            && !message.animating })
        const field = findChild(editor, "containerPathField")
        const pathBottom = field.mapToItem(editor, 0, field.height)
        const messageTop = message.mapToItem(editor, 0, 0)
        verify(messageTop.y >= pathBottom.y, "Feedback follows the folder field")
        verify(message.width > 0 && message.width <= editor.width)
        verify(messageTop.x >= 0 && messageTop.x + message.width <= editor.width + 1)
        compare(message.Layout.columnSpan, 2)
    }
}
