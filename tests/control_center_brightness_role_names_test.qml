// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml.Models
import QtTest
import org.kde.kitemmodels as KItemModels

TestCase {
    id: testCase

    name: "ControlCenterBrightnessRoleNames"

    ListModel {
        id: displaysModel

        ListElement {
            displayName: "display0"
            brightness: 5000
            maxBrightness: 10000
        }
    }

    function init() {
        failOnWarning(/.?/)
    }

    function test_rolesAreResolvedFromTheDisplayModelAttachment() {
        const displayNameRole =
            displaysModel.KItemModels.KRoleNames.role("displayName")
        const brightnessRole =
            displaysModel.KItemModels.KRoleNames.role("brightness")
        const maximumRole =
            displaysModel.KItemModels.KRoleNames.role("maxBrightness")
        const modelIndex = displaysModel.index(0, 0)

        compare(displaysModel.data(modelIndex, displayNameRole), "display0")
        compare(displaysModel.data(modelIndex, brightnessRole), 5000)
        compare(displaysModel.data(modelIndex, maximumRole), 10000)
    }
}
