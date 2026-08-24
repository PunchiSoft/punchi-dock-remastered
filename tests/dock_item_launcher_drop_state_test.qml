import QtQuick
import QtTest
import "../contents/code/dockDropState.js" as DockDropState

TestCase {
    id: testCase

    name: "DockItemLauncherDropState"
    width: 320
    height: 180

    function init() {
        failOnWarning(/.?/)
    }

    function test_launcherAcceptanceSurvivesPointerMovement() {
        compare(DockDropState.launcherDropAcceptance(
            "launcherContainmentAcceptable"), true)
        compare(DockDropState.launcherDropAcceptance(
            "launcherAcceptable"), true)
    }

    function test_rejectedAndUnrelatedStatesRemainRejected() {
        compare(DockDropState.launcherDropAcceptance(
            "launcherContainmentRejected"), false)
        compare(DockDropState.launcherDropAcceptance("rejected"), false)
        compare(DockDropState.launcherDropAcceptance("none"), undefined)
    }
}
