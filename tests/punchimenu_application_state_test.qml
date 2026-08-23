// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components/punchimenu" as PunchiMenu

TestCase {
    id: testCase

    name: "PunchiMenuApplicationState"
    when: windowShown

    PunchiMenu.PunchiMenuApplicationState {
        id: applicationState
    }

    function init() {
        failOnWarning(/.?/)
        applicationState.favorites = []
        applicationState.hiddenApplicationIds = []
        applicationState.applicationCatalog = []
    }

    function test_favoriteIdentitySupportsCurrentAndLegacyShapes() {
        applicationState.favorites = [
            { "appStorageId": "org.kde.dolphin.desktop" },
            { "storageId": "org.kde.kate.desktop" },
            { "id": "org.kde.konsole.desktop" },
            "org.kde.discover.desktop"
        ]

        verify(applicationState.isFavorite("org.kde.dolphin.desktop"))
        verify(applicationState.isFavorite("org.kde.kate.desktop"))
        verify(applicationState.isFavorite("org.kde.konsole.desktop"))
        verify(applicationState.isFavorite("org.kde.discover.desktop"))
        verify(!applicationState.isFavorite("org.kde.gwenview.desktop"))
    }

    function test_invalidStorageIdsAreRejected() {
        const oversizedId = "a".repeat(513)
        applicationState.favorites = [
            { "appStorageId": oversizedId },
            { "appStorageId": "unsafe\u0000.desktop" }
        ]
        applicationState.hiddenApplicationIds = [
            "valid.desktop", "unsafe\u0000.desktop", oversizedId, ""
        ]

        verify(!applicationState.isFavorite(oversizedId))
        verify(!applicationState.isFavorite("unsafe\u0000.desktop"))
        compare(applicationState.hiddenIdCount, 1)
        verify(applicationState.isApplicationHidden("valid.desktop"))
        verify(!applicationState.isApplicationHidden("unsafe\u0000.desktop"))
    }

    function test_hiddenCountsKeepConfiguredAndCatalogPoliciesSeparate() {
        applicationState.hiddenApplicationIds = [
            "first.desktop", "second.desktop", "stale.desktop",
            "first.desktop"
        ]
        applicationState.applicationCatalog = [
            { "storageId": "first.desktop" },
            { "appStorageId": "second.desktop" },
            { "storageId": "visible.desktop" }
        ]

        compare(applicationState.hiddenIdCount, 3)
        compare(applicationState.hiddenCatalogApplicationCount, 2)
    }

    function test_reactsToReplacementInputs() {
        applicationState.favorites = [
            { "appStorageId": "first.desktop" }
        ]
        verify(applicationState.isFavorite("first.desktop"))

        applicationState.favorites = [
            { "appStorageId": "second.desktop" }
        ]
        verify(!applicationState.isFavorite("first.desktop"))
        verify(applicationState.isFavorite("second.desktop"))

        applicationState.hiddenApplicationIds = ["first.desktop"]
        compare(applicationState.hiddenIdCount, 1)
        applicationState.hiddenApplicationIds = ["second.desktop"]
        verify(!applicationState.isApplicationHidden("first.desktop"))
        verify(applicationState.isApplicationHidden("second.desktop"))
    }
}
