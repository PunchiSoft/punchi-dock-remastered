// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtCore
import QtTest
import "../contents/ui/config" as Config

TestCase {
    id: testCase
    name: "ContainerNativeDiscovery"
    when: windowShown

    property int responseCount: 0
    property int receivedCount: -1
    property bool lastApplied: false
    property bool failed: false
    property var nativeResult: null

    Config.ItemDraftController { id: controller }
    Config.ItemConfigurationDialog {
        id: dialog
        draftController: controller
        onContentLoadRequested: testCase.requestContent()
    }
    SignalSpy { id: acceptedSpy; target: controller; signalName: "itemAccepted" }

    Config.SystemDiscoveryManager {
        id: discovery
        onAppsDiscovered: function(apps, requestId) {
            testCase.receive(apps, requestId, "container-applications")
        }
        onFolderEntriesDiscovered: function(entries, requestId) {
            testCase.receive(entries, requestId, "container-folder")
        }
        onOperationFailed: function(operation, message, requestId) {
            testCase.failed = true
        }
    }

    function receive(entries, requestId, kind) {
        nativeResult = entries
        receivedCount = entries.length
        const operation = controller.takeExternalOperation(kind, requestId)
        lastApplied = operation !== null && controller.applyContainerApplications(
            operation.generation, entries, "")
        if (lastApplied) {
            dialog.refreshEditorFields(true)
        }
        responseCount += 1
    }

    function folderPath(name) {
        return StandardPaths.writableLocation(StandardPaths.RuntimeLocation)
            + "/fixtures/" + name
    }

    function actionEditor() {
        return findChild(dialog, "itemConfigurationActionEditor")
    }

    function requestContent() {
        const draft = controller.draft
        const source = draft.sourceType
        const kind = source === "folder" ? "container-folder" : "container-applications"
        const requestId = controller.beginExternalOperation(kind, source, {})
        if (source === "folder") {
            discovery.requestFolderEntries(draft.sourcePath, requestId)
        } else {
            discovery.requestApplications(draft.sourceCategory, requestId)
        }
    }

    function load(source, value) {
        controller.setDraftValues({sourceType: source,
            sourceCategory: source === "category" ? value : "Network",
            sourcePath: source === "folder" ? value : ""})
        dialog.refreshEditorFields(true)
        const before = responseCount
        findChild(dialog, "itemConfigurationEditorPanel").containerRefreshRequested()
        tryCompare(testCase, "responseCount", before + 1, 5000)
        compare(failed, false, "Native discovery must succeed")
        verify(lastApplied, "The current native result must reach the draft")
    }

    function init() {
        failOnWarning(/.?/)
        responseCount = 0
        receivedCount = -1
        nativeResult = null
        lastApplied = false
        failed = false
        controller.items = []
        acceptedSpy.clear()
        dialog.openFor("folder")
        tryVerify(function() { return dialog.opened })
        compare(actionEditor().actionModel.count, 0)
    }

    function cleanup() {
        dialog.cancelDraft()
        tryVerify(function() { return !dialog.opened })
        compare(discovery.folderRequestActive, false,
            "No native folder request may outlive the test")
    }

    function test_categoryReachesVisibleRowsAndAcceptedItem() {
        load("category", "Network")
        compare(receivedCount, 2, "Only the two visible Network fixtures match")
        compare(controller.nestedCount(), 2)
        compare(actionEditor().actionModel.count, 2)
        verify(Array.isArray(controller.draft.apps), "The draft owns a JavaScript array")
        const names = controller.draft.apps.map(function(item) { return item.name }).sort()
        compare(names.join(","), "Fixture Browser,Fixture Mail")
        compare(controller.items.length, 0, "Discovery must not add a dock item")
        verify(dialog.acceptDraft())
        compare(acceptedSpy.count, 1)
        compare(acceptedSpy.signalArguments[0][0].apps.length, 2)
        compare(acceptedSpy.signalArguments[0][0].sourceCategory, "Network")
    }

    function test_folderReachesVisibleRowsAndPreservesUrls() {
        load("folder", folderPath("populated"))
        compare(receivedCount, 2, "The hidden entry must be excluded")
        compare(controller.nestedCount(), 2)
        compare(actionEditor().actionModel.count, 2)
        const names = controller.draft.apps.map(function(item) { return item.name }).sort()
        compare(names.join(","), "document.txt,subfolder")
        for (let index = 0; index < controller.draft.apps.length; ++index) {
            verify(controller.draft.apps[index].url.indexOf("file:") === 0)
        }
        verify(dialog.acceptDraft())
        compare(acceptedSpy.signalArguments[0][0].apps.length, 2)
    }

    function test_emptyCategoryReplacesExistingContent() {
        load("category", "Network")
        dialog.selectedActionIndex = 1
        load("category", "Graphics")
        compare(receivedCount, 0)
        compare(controller.nestedCount(), 0)
        compare(actionEditor().actionModel.count, 0)
        compare(dialog.selectedActionIndex, -1)
    }

    function test_emptyFolderReplacesExistingContent() {
        load("folder", folderPath("populated"))
        load("folder", folderPath("empty"))
        compare(receivedCount, 0)
        compare(controller.nestedCount(), 0)
        compare(actionEditor().actionModel.count, 0)
    }

    function test_cancelledDraftRejectsLateNativeFolderResult() {
        controller.setDraftValues({sourceType: "folder", sourcePath: folderPath("populated")})
        requestContent()
        dialog.cancelDraft()
        tryCompare(testCase, "responseCount", 1, 5000)
        compare(failed, false)
        compare(receivedCount, 2)
        compare(lastApplied, false)
        compare(controller.draft, null)
        compare(acceptedSpy.count, 0)
        dialog.openFor("folder")
        tryVerify(function() { return dialog.opened })
        compare(actionEditor().actionModel.count, 0)
    }

    function test_nativeResultCannotMutateNewGenerationOrType() {
        load("category", "Network")
        const generation = controller.generation
        const result = nativeResult
        controller.cancel()
        controller.open("folder")
        compare(controller.applyContainerApplications(generation, result, ""), false)
        compare(controller.nestedCount(), 0)
        controller.open("app")
        compare(controller.applyContainerApplications(controller.generation, result, ""), false)
        verify(controller.draft.apps === undefined)
    }

    function test_nonListPayloadsRemainEmpty() {
        const payloads = [null, undefined, "invalid", 4, {name: "Not a list"}]
        for (let index = 0; index < payloads.length; ++index) {
            controller.applyContainerApplications(controller.generation,
                [{type: "app", name: "Existing", command: "/bin/true"}], "")
            verify(controller.applyContainerApplications(controller.generation, payloads[index], ""))
            compare(controller.nestedCount(), 0)
        }
    }
}
