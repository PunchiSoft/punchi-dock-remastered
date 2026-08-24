import QtQuick
import QtTest
import "../contents/code/logic.js" as Logic
import "../contents/ui/config/code/configItems.js" as ConfigItems

TestCase {
    name: "DynamicApplicationsMarkerLogic"

    function init() {
        failOnWarning(/.?/)
    }

    function test_appendsMarkerAfterExistingItems() {
        const original = [
            { "type": "app", "name": "First" },
            { "type": "separator", "name": "Divider" }
        ]

        const result = Logic.dynamicApplicationsMarkerUpdate(original)

        verify(result.changed)
        compare(result.errorCode, "")
        compare(original.length, 2)
        compare(result.items.length, 3)
        compare(result.items[0].name, "First")
        compare(result.items[1].name, "Divider")
        compare(result.items[2].type, "dynamic-applications")
        compare(result.items[2].name, "Open applications")
    }

    function test_existingMarkerIsIdempotent() {
        const original = [
            { "type": "dynamic-applications", "name": "Open applications" },
            { "type": "app", "name": "After marker" }
        ]

        const result = Logic.dynamicApplicationsMarkerUpdate(original)

        verify(!result.changed)
        compare(result.errorCode, "")
        verify(result.items === original)
        compare(result.items.length, 2)
    }

    function test_itemLimitKeepsFallbackWithoutGrowingConfiguration() {
        const original = []
        for (let index = 0; index < Logic.maximumDockItemCount; index++) {
            original.push({ "type": "app", "name": "Application " + index })
        }

        const result = Logic.dynamicApplicationsMarkerUpdate(original)

        verify(!result.changed)
        compare(result.errorCode, "maximumItemCount")
        verify(result.items === original)
        compare(result.items.length, Logic.maximumDockItemCount)
    }

    function test_markerAppearanceIsNormalizedAndVisibilityIsPreserved() {
        const item = {
            "type": "dynamic-applications",
            "name": "Unexpected name",
            "showSeparator": false,
            "separatorStyle": "pill",
            "separatorThickness": 40,
            "separatorLengthRatio": 0.05,
            "separatorOpacity": 2,
            "separatorGlowEnabled": true,
            "command": "must-not-survive"
        }

        ConfigItems.pruneDynamicApplications(item)

        compare(item.name, "Open applications")
        compare(item.showSeparator, false)
        compare(item.separatorStyle, "capsule")
        compare(item.separatorThickness, 16)
        compare(item.separatorLengthRatio, 0.20)
        compare(item.separatorOpacity, 1.0)
        compare(item.separatorGlowEnabled, true)
        verify(Object.keys(item).indexOf("command") < 0)
    }

    function test_visibleMarkerUsesBackwardCompatibleDefault() {
        const item = {
            "type": "dynamic-applications",
            "showSeparator": true
        }

        ConfigItems.pruneDynamicApplications(item)

        verify(Object.keys(item).indexOf("showSeparator") < 0)
    }

    function test_calendarUsesUnambiguousDefaultTitle() {
        const translate = function(text) { return "translated:" + text }

        compare(ConfigItems.itemTitle({
            "type": "calendar",
            "name": "Calendar"
        }, translate), "translated:Calendar/Clock")
        compare(ConfigItems.itemTypeTitle("calendar", translate),
            "translated:Calendar/Clock")
    }

    function test_punchiMenuPanelDistanceMigratesFromLegacyPixels() {
        const item = {
            "type": "punchimenu",
            "normalPanelGap": 8
        }

        ConfigItems.prunePunchiMenu(item)

        compare(item.normalPanelDistancePercent, 25)
        verify(Object.keys(item).indexOf("normalPanelGap") < 0)
    }

    function test_punchiMenuPanelDistancePrefersAndClampsPercentage() {
        const explicitItem = {
            "type": "punchimenu",
            "normalPanelDistancePercent": 73,
            "normalPanelGap": 1
        }
        ConfigItems.prunePunchiMenu(explicitItem)
        compare(explicitItem.normalPanelDistancePercent, 75)
        verify(Object.keys(explicitItem).indexOf("normalPanelGap") < 0)

        const defaultItem = { "type": "punchimenu" }
        ConfigItems.prunePunchiMenu(defaultItem)
        compare(defaultItem.normalPanelDistancePercent, 25)
    }
}
