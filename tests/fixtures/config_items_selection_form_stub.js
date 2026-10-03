// SPDX-License-Identifier: GPL-2.0-or-later

// Selection unit fixture: record each form phase in the owning QML test context.
function refreshItemForm() {
    testCase.recordSelectionRefresh("form")
}

function refreshActions() {
    testCase.recordSelectionRefresh("actions")
}
