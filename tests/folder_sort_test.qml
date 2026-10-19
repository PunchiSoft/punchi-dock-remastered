// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import org.punchi.dock as Punchi

TestCase {
    id: testCase
    name: "FolderSort"

    readonly property string fixturePath: {
        for (let index = 0; index < Qt.application.arguments.length; index++) {
            const argument = String(Qt.application.arguments[index])
            if (argument.indexOf("--fixture=") === 0) {
                return argument.substring("--fixture=".length)
            }
        }
        return "/tmp/punchi-folder-sort-fixture"
    }

    Punchi.FolderNavigationModel {
        id: model
        rootPath: testCase.fixturePath
    }

    function names() {
        const result = []
        for (let index = 0; index < model.count; index++) {
            result.push(String(model.get(index).name))
        }
        return result
    }

    function settle() {
        model.enabled = true
        tryCompare(model, "loading", false, 5000)
        compare(model.error, "")
    }

    function init() {
        model.enabled = false
        model.rootPath = fixturePath
        model.enabled = true
    }

    function cleanup() {
        model.enabled = false
    }

    function test_nameSortIsAlphabetical() {
        model.sortMode = "name"
        settle()
        compare(names(), ["alpha.txt", "Bravo.txt", "charlie.txt", "doc.png", "echo.pdf"])
    }

    function test_sizeSortIsLargestFirst() {
        model.sortMode = "size"
        settle()
        compare(names(), ["doc.png", "echo.pdf", "alpha.txt", "charlie.txt", "Bravo.txt"])
    }

    function test_modifiedSortIsNewestFirst() {
        model.sortMode = "modified"
        settle()
        compare(names(), ["echo.pdf", "doc.png", "charlie.txt", "Bravo.txt", "alpha.txt"])
    }

    function test_kindSortUsesMimeTypeThenName() {
        model.sortMode = "kind"
        settle()
        compare(names(), ["echo.pdf", "doc.png", "alpha.txt", "Bravo.txt", "charlie.txt"])
    }

    function test_liveSortModeChangeReordersLoadedRows() {
        model.sortMode = "name"
        settle()
        compare(names()[0], "alpha.txt")
        model.sortMode = "size"
        compare(names()[0], "doc.png")
    }
}
