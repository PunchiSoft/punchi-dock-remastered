// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtTest
import "../contents/ui/config" as Config
import "../contents/ui/config/components" as ConfigComponents

// Sizing contract of the shared action editor.
//
// A row takes its width from the list and reserves a share of that same width for
// its subtitle. Reading that reservation back as the row's own implicit width used
// to close a sizing cycle with the KDE delegate style, which reported an
// implicitWidth warning while the editor resized. These cases instantiate the
// editor in the contexts that used to trigger it—definite width, inside a layout,
// with and without the vertical scrollbar, long subtitles, inside the dialog that
// hosts it and inside the shared action dialog—and require that no warning is
// emitted and that every measured dimension stays stable while the rows change.
TestCase {
    id: layoutCase

    name: "ItemActionEditorLayout"
    when: windowShown

    readonly property string longSubtitle: "An intentionally long subtitle that forces the row to elide it"

    ListModel {
        id: rowsModel
    }

    Component {
        id: itemHostComponent

        Item {
            id: host

            property alias editor: fixedEditor

            width: 420
            height: 220

            Config.ItemActionEditor {
                id: fixedEditor
                anchors.fill: parent
                actionModel: rowsModel
                selectedItemIndex: 0
                selectedItemType: "app"
                itemModeValue: "app"
                editableItemAvailable: true
            }
        }
    }

    Component {
        id: layoutHostComponent

        ColumnLayout {
            id: layoutHost

            property alias editor: layoutEditor

            width: 360
            height: 320

            Config.ItemActionEditor {
                id: layoutEditor
                Layout.fillWidth: true
                Layout.fillHeight: true
                actionModel: rowsModel
                selectedItemIndex: 0
                selectedItemType: "app"
                itemModeValue: "app"
                editableItemAvailable: true
            }
        }
    }

    Component {
        id: actionDialogComponent

        ConfigComponents.ActionDialog {
            id: actionDialog
            actionModel: rowsModel
            selectedItemIndex: 0
            selectedItemType: "app"
        }
    }

    Config.ItemDraftController {
        id: dialogController

        items: []
    }

    Config.ItemConfigurationDialog {
        id: configurationDialog

        draftController: dialogController
    }

    function seedRows(count) {
        rowsModel.clear()
        appendRows(count)
    }

    function appendRows(count) {
        for (let index = 0; index < count; ++index) {
            rowsModel.append({
                "title": "Action with a fairly long name " + index,
                "subtitle": longSubtitle,
                "iconName": "folder"
            })
        }
    }

    function actionListOf(editor) {
        return findChild(editor, "actionList")
    }

    function firstRowOf(editor) {
        const list = actionListOf(editor)
        if (list === null) {
            return null
        }
        tryVerify(function() {
            return list.itemAtIndex(0) !== null
        }, 2000, "The list must render its first row")
        return list.itemAtIndex(0)
    }

    function init() {
        failOnWarning(/.?/)
        seedRows(0)
        dialogController.cancel()
    }

    function test_definiteWidthReservesTheSubtitleWithoutWarning() {
        seedRows(2)
        const host = createTemporaryObject(itemHostComponent, layoutCase)
        verify(host !== null)
        const editor = host.editor

        const list = actionListOf(editor)
        const row = firstRowOf(editor)

        compare(row.width, list.width,
            "A row must take its width from the list, not from its own implicit size")
        verify(row.width <= editor.width,
            "A row must not grow beyond the editor")
        verify(row.rightPadding >= row.width * 0.42,
            "A row must reserve a share of its width for the subtitle")

        // Adding, moving and removing rows must not move the measured geometry.
        const editorWidth = editor.width
        const editorHeight = editor.height

        appendRows(3)
        tryVerify(function() {
            return editor.actionCount === 5
        }, 2000, "The list must follow the model")
        rowsModel.move(0, 1, 1)
        rowsModel.remove(0, 1)
        tryVerify(function() {
            return editor.actionCount === 4
        }, 2000, "The list must follow the removal")
        wait(20)

        compare(editor.width, editorWidth, "The editor width must not follow its rows")
        compare(editor.height, editorHeight, "The editor height must not follow its rows")

        const resizedRow = firstRowOf(editor)
        compare(resizedRow.width, list.width,
            "The row width must not change with the row count")
        verify(resizedRow.rightPadding >= resizedRow.width * 0.42,
            "The reserved subtitle space must survive a shorter list")
    }

    function test_insideLayoutTakesTheLayoutWidth() {
        seedRows(3)
        const host = createTemporaryObject(layoutHostComponent, layoutCase)
        verify(host !== null)
        const editor = host.editor

        compare(editor.width, host.width,
            "A filling editor must take the width of its layout")
        tryVerify(function() {
            return firstRowOf(editor) !== null
        })
        const list = actionListOf(editor)
        const row = firstRowOf(editor)

        compare(row.width, list.width,
            "A row must take its width from the list inside a layout too")
        verify(row.rightPadding >= row.width * 0.42,
            "A row inside a layout must reserve the same subtitle share")
    }

    function test_verticalScrollbarAddsItsGutterWithoutResizingRows() {
        seedRows(2)
        // A taller host: the case needs a list that fits two rows before it
        // overflows, so the two states can be compared.
        const host = createTemporaryObject(itemHostComponent, layoutCase, {"height": 640})
        verify(host !== null)
        const editor = host.editor

        const list = actionListOf(editor)
        const row = firstRowOf(editor)
        verify(list.contentHeight <= list.height,
            "Two rows must fit without a scrollbar in this editor")
        const rowWidth = row.width
        const paddingWithoutScroll = row.rightPadding

        appendRows(12)
        tryVerify(function() {
            return list.contentHeight > list.height
        }, 2000, "The list must overflow and show its scrollbar")
        wait(20)

        const scrolledRow = firstRowOf(editor)
        compare(scrolledRow.width, rowWidth,
            "The scrollbar must not narrow the rows")
        compare(scrolledRow.width, list.width,
            "A row must keep taking its width from the list while it scrolls")
        verify(scrolledRow.rightPadding > paddingWithoutScroll,
            "The scrollbar must reserve its gutter inside the row")
        compare(editor.width, host.width, "The scrollbar must not resize the editor")
    }

    function test_insideConfigurationDialogKeepsRowGeometry() {
        configurationDialog.openFor("app")
        tryVerify(function() {
            return configurationDialog.opened
        })

        const editor = findChild(configurationDialog, "itemConfigurationActionEditor")
        verify(editor !== null, "The dialog must host the shared action editor")

        editor.actionsEnabledToggled(true)
        editor.addActionRequested()
        editor.actionNameText = "Open in Dolphin"
        editor.actionIconText = "folder"
        editor.actionCommandText = "dolphin %U"
        editor.actionFormChanged()
        tryVerify(function() {
            return editor.actionCount === 1
        }, 2000, "The projection must be rebuilt from the draft")

        const list = actionListOf(editor)
        const row = firstRowOf(editor)
        compare(row.width, list.width,
            "A row must take its width from the list inside the dialog")
        verify(row.rightPadding >= row.width * 0.42,
            "A row inside the dialog must reserve the subtitle share")

        const editorWidth = editor.width
        editor.addActionRequested()
        editor.actionNameText = "Open in Terminal"
        editor.actionCommandText = "konsole"
        editor.actionFormChanged()
        tryVerify(function() {
            return editor.actionCount === 2
        }, 2000, "The projection must follow the second action")

        compare(editor.width, editorWidth,
            "Adding an action must not resize the editor inside the dialog")
        verify(configurationDialog.opened, "The dialog must stay open while editing")
    }

    function test_insideActionDialogKeepsRowGeometry() {
        seedRows(1)
        const dialog = createTemporaryObject(actionDialogComponent, layoutCase,
            {"width": 520, "height": 560})
        verify(dialog !== null)
        dialog.open()
        tryVerify(function() {
            return dialog.visible
        }, 2000, "The action dialog must open")
        tryVerify(function() {
            return dialog.actionCount === 1
        }, 2000, "The action dialog must render its row")

        const list = findChild(dialog, "actionList")
        verify(list !== null, "The action dialog must render its list")
        const row = firstRowOf(dialog)
        compare(row.width, list.width,
            "A row must take its width from the list inside the action dialog")
        verify(row.rightPadding >= row.width * 0.42,
            "A row inside the action dialog must reserve the subtitle share")

        const rowWidth = row.width
        appendRows(1)
        tryVerify(function() {
            return list.count === 2
        }, 2000, "The action dialog must follow its model")
        verify(firstRowOf(dialog).width === rowWidth,
            "Adding an action must not change the row width")
    }
}
