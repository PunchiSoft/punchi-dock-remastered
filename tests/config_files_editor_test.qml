// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtTest
import "../contents/ui/config" as ConfigPages

TestCase {
    id: testCase
    name: "ConfigFilesEditor"
    when: windowShown
    visible: true
    width: 850
    height: 850

    Component {
        id: pageComponent
        ConfigPages.ConfigFiles {
            width: 720
            height: 720
        }
    }

    SignalSpy {
        id: configSpy
        signalName: "cfg_dockItemsJsonChanged"
    }

    function init() {
        failOnWarning(/.?/)
    }

    function cleanup() {
        configSpy.target = null
        configSpy.clear()
    }

    function createPage(source) {
        const page = createTemporaryObject(pageComponent, testCase, {
            cfg_dockItemsJson: source
        })
        verify(page !== null)
        configSpy.target = page
        configSpy.clear()
        return page
    }

    function editorFor(page) {
        const editor = findChild(page, "jsonEditorTextArea")
        verify(editor !== null)
        return editor
    }

    function scrollFor(page) {
        const scroll = findChild(page, "jsonEditorScrollView")
        verify(scroll !== null)
        waitForPolish(scroll)
        return scroll
    }

    function test_loadingFormatsOnlyThePresentation() {
        const source = '[{"type":"app","name":"Example","nested":{"value":42}}]'
        const page = createPage(source)
        const editor = editorFor(page)
        compare(editor.text, JSON.stringify(JSON.parse(source), null, 4))
        compare(page.cfg_dockItemsJson, source)
        compare(page.editorDockItemsJson, source)
        compare(configSpy.count, 0)
    }

    function test_invalidInputRemainsIntact() {
        const source = '[{"type":"app",'
        const page = createPage(source)
        compare(editorFor(page).text, source)
        compare(page.cfg_dockItemsJson, source)
        compare(configSpy.count, 0)
    }

    function test_emptyStoredValueKeepsTheDefaultUnchanged() {
        const page = createPage("")
        verify(JSON.parse(editorFor(page).text).length > 0)
        compare(page.cfg_dockItemsJson, "")
        compare(configSpy.count, 0)
    }

    function test_reloadAndRestoreReformatWithoutExtraWrites() {
        const page = createPage('[{"type":"app","name":"First"}]')
        const source = '[{"type":"app","name":"Reloaded"}]'
        page.cfg_dockItemsJson = source
        compare(editorFor(page).text, JSON.stringify(JSON.parse(source), null, 4))
        compare(page.cfg_dockItemsJson, source)
        compare(configSpy.count, 1)

        page.cfg_dockItemsJson = ""
        verify(JSON.parse(editorFor(page).text).length > 0)
        compare(page.cfg_dockItemsJson, "")
        compare(configSpy.count, 2)
    }

    function test_editingKeepsTheTypedTextUntilExplicitFormatting() {
        const page = createPage('[{"type":"app","name":"Example"}]')
        const editor = editorFor(page)
        editor.forceActiveFocus()
        editor.cursorPosition = editor.length
        keyClick(Qt.Key_Space)
        compare(page.cfg_dockItemsJson, editor.text)
        verify(editor.text.endsWith(" "))
        compare(configSpy.count, 1)

        page.setItems(JSON.parse(editor.text))
        compare(editor.text, JSON.stringify(JSON.parse(editor.text), null, 4))
        compare(page.cfg_dockItemsJson, editor.text)
    }

    function test_exportPreservesFormattingAndStoredValue() {
        const source = '[{"type":"app","name":"Example"}]'
        const page = createPage(source)
        const editor = editorFor(page)
        const displayed = editor.text
        page.exportJsonRequested()
        compare(editor.text, displayed)
        compare(editor.selectedText, displayed)
        compare(page.cfg_dockItemsJson, source)
        compare(configSpy.count, 0)
    }

    function test_largeDocumentScrollsWithWheelAndKeyboard() {
        const items = []
        for (let i = 0; i < 80; ++i) {
            items.push({type: "app", name: "Example " + i,
                command: "example " + "long_argument_".repeat(100)})
        }
        const source = JSON.stringify(items)
        const page = createPage(source)
        const editor = editorFor(page)
        const scroll = scrollFor(page)
        tryVerify(function() {
            return scroll.contentHeight > scroll.availableHeight
                && scroll.contentWidth > scroll.availableWidth
        })
        tryVerify(function() { return scroll.Controls.ScrollBar.vertical.visible })
        tryVerify(function() { return scroll.Controls.ScrollBar.horizontal.visible })
        const flickable = scroll.contentItem
        mouseWheel(editor, 80, 80, 0, -120, Qt.NoButton)
        tryVerify(function() { return flickable.contentY > 0 }, 1500,
            "Viewport " + scroll.width + "x" + scroll.height + "; content "
            + scroll.contentWidth + "x" + scroll.contentHeight + "; origin "
            + flickable.contentX + "," + flickable.contentY + "; point "
            + editor.mapToItem(testCase, 80, 80) + "; cursor " + editor.cursorPosition)

        editor.forceActiveFocus()
        keyClick(Qt.Key_End, Qt.ControlModifier)
        tryCompare(editor, "cursorPosition", editor.length)
        tryVerify(function() {
            return flickable.contentY > flickable.contentHeight / 2
        })
        keyClick(Qt.Key_Home, Qt.ControlModifier)
        tryCompare(editor, "cursorPosition", 0)
        tryVerify(function() { return flickable.contentY < 1 })
        mouseWheel(editor, 80, 80, -120, 0, Qt.NoButton)
        tryVerify(function() { return flickable.contentX > 0 })
        compare(page.cfg_dockItemsJson, source)
        compare(configSpy.count, 0)
    }
}
