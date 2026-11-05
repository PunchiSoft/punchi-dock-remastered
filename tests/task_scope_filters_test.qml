import QtQuick
import QtTest
import "../contents/ui/components" as Components
import "../contents/ui/config" as Config
import "../contents/ui/components/TaskManagerCompatibility.js" as TaskManagerCompatibility

TestCase {
    id: testCase
    name: "TaskScopeFilters"
    when: windowShown
    visible: true
    width: 800
    height: 900

    Component {
        id: controllerComponent
        Components.TaskModelController {}
    }

    Component {
        id: pageComponent
        Config.ConfigWindows {}
    }

    QtObject {
        id: modernFilter
        property bool filterByCurrentVirtualDesktop: false
    }

    function init() {
        failOnWarning(/.?/)
    }

    function test_combinations_data() {
        const cases = []
        for (let desktop = 0; desktop < 2; desktop++) {
            for (let activity = 0; activity < 2; activity++) {
                for (let screen = 0; screen < 2; screen++) {
                    cases.push({
                        "tag": "desktop-" + desktop + "-activity-" + activity + "-screen-" + screen,
                        "desktop": !!desktop,
                        "activity": !!activity,
                        "screen": !!screen
                    })
                }
            }
        }
        return cases
    }

    function test_combinations(data) {
        const controller = createTemporaryObject(controllerComponent, testCase)
        verify(controller !== null)
        const model = findChild(controller, "tasksModel")
        verify(model !== null)
        controller.currentDesktopOnly = data.desktop
        controller.currentActivityOnly = data.activity
        controller.currentScreenOnly = data.screen
        compare(model.filterByActivity, data.activity)
        compare(model.filterByScreen, data.screen)
        compare(model.filterByVirtualDesktop, controller.useLegacyCurrentDesktopFilter)
        const modern = model.filterByCurrentVirtualDesktop !== undefined
        compare(controller.useLegacyCurrentDesktopFilter,
            controller.virtualDesktopInfoAvailable && data.desktop && !modern)
        if (modern) {
            compare(model.filterByCurrentVirtualDesktop,
                controller.virtualDesktopInfoAvailable && data.desktop)
        }
        controller.currentDesktopOnly = false
        compare(model.filterByVirtualDesktop, false)
        if (modern) {
            compare(model.filterByCurrentVirtualDesktop, false)
        }
        compare(model.filterByActivity, data.activity)
        compare(model.filterByScreen, data.screen)
    }

    function test_disableAndReenablePreservesScope() {
        const controller = createTemporaryObject(controllerComponent, testCase, {
            "currentDesktopOnly": true,
            "currentActivityOnly": true,
            "currentScreenOnly": true
        })
        verify(controller !== null)
        const model = findChild(controller, "tasksModel")
        controller.showActiveTasks = false
        compare(model.filterByActivity, false)
        compare(model.filterByScreen, false)
        compare(model.filterByVirtualDesktop, false)
        compare(controller.currentDesktopOnly, true)
        compare(controller.currentActivityOnly, true)
        compare(controller.currentScreenOnly, true)
        controller.showActiveTasks = true
        compare(model.filterByActivity, true)
        compare(model.filterByScreen, true)
    }

    function test_screenGeometryFollowsDockWithoutRecreation() {
        const controller = createTemporaryObject(controllerComponent, testCase, {
            "currentScreenOnly": true
        })
        verify(controller !== null)
        const model = findChild(controller, "tasksModel")
        for (const geometry of [
            Qt.rect(0, 0, 1920, 1080),
            Qt.rect(-2560, 0, 2560, 1440),
            Qt.rect(1920, -900, 1600, 900),
            Qt.rect(0, 0, 0, 0)
        ]) {
            controller.screenGeometry = geometry
            compare(model.screenGeometry, geometry)
            compare(model.filterByScreen, true)
        }
        controller.currentScreenOnly = false
        compare(model.filterByScreen, false)
    }

    function test_optionalModernFilterCanBeTurnedOff() {
        verify(TaskManagerCompatibility.setOptionalProperty(
            modernFilter, "filterByCurrentVirtualDesktop", true))
        compare(modernFilter.filterByCurrentVirtualDesktop, true)
        verify(TaskManagerCompatibility.setOptionalProperty(
            modernFilter, "filterByCurrentVirtualDesktop", false))
        compare(modernFilter.filterByCurrentVirtualDesktop, false)
        compare(TaskManagerCompatibility.setOptionalProperty(
            modernFilter, "nonexistentFilter", true), false)
    }

    function test_settingsAliasesAndKeyboard() {
        const page = createTemporaryObject(pageComponent, testCase, {
            "width": 760, "height": 860,
            "cfg_showActiveTasks": true,
            "cfg_showTasksCurrentDesktopOnly": true,
            "cfg_showTasksCurrentActivityOnly": false,
            "cfg_showTasksCurrentScreenOnly": false
        })
        verify(page !== null)
        verify(waitForPolish(page))
        const controls = [
            ["currentDesktopOnlySwitch", "cfg_showTasksCurrentDesktopOnly"],
            ["currentActivityOnlySwitch", "cfg_showTasksCurrentActivityOnly"],
            ["currentScreenOnlySwitch", "cfg_showTasksCurrentScreenOnly"]
        ]
        for (const entry of controls) {
            const toggle = findChild(page, entry[0])
            verify(toggle !== null)
            verify(toggle.activeFocusOnTab)
            verify(String(toggle.Accessible.name).length > 0)
            verify(String(toggle.Accessible.description).length > 0)
            const before = page[entry[1]]
            toggle.forceActiveFocus()
            tryCompare(toggle, "activeFocus", true)
            keyClick(Qt.Key_Space)
            compare(page[entry[1]], !before)
            page.cfg_showActiveTasks = false
            compare(toggle.enabled, false)
            compare(page[entry[1]], !before)
            page.cfg_showActiveTasks = true
            compare(toggle.enabled, true)
            page[entry[1]] = before
            compare(toggle.checked, before)
        }
    }

    function test_destroyWithPendingRefreshAndRecreate() {
        for (let index = 0; index < 3; index++) {
            const controller = controllerComponent.createObject(testCase)
            verify(controller !== null)
            controller.currentActivityOnly = true
            controller.currentScreenOnly = true
            controller.screenGeometry = Qt.rect(-1920, 0, 1920, 1080)
            controller.destroy()
            wait(0)
        }
        const controller = createTemporaryObject(controllerComponent, testCase)
        verify(controller !== null)
        compare(controller.currentDesktopOnly, true)
        compare(controller.currentActivityOnly, false)
        compare(controller.currentScreenOnly, false)
    }
}
