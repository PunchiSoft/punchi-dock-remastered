pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "ThemedSeparatorLifecycle"
    when: windowShown
    width: 320
    height: 240

    Component {
        id: separatorHostComponent

        Item {
            id: separatorHost

            required property string separatorStyle
            required property bool verticalPanel

            property int separatorCount: 1

            width: verticalPanel ? 48 : 96
            height: verticalPanel ? 96 : 48

            Repeater {
                model: separatorHost.separatorCount

                delegate: Item {
                    required property int index

                    anchors.fill: parent

                    Components.ThemedSeparator {
                        anchors.centerIn: parent
                        availableLength: separatorHost.verticalPanel
                            ? separatorHost.height
                            : separatorHost.width
                        style: separatorHost.separatorStyle
                        verticalPanel: separatorHost.verticalPanel
                    }
                }
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
    }

    function test_delegatesSurviveHostTeardownWithoutNullDereferences() {
        const styles = ["doubleLine", "chevron"]

        for (let iteration = 0; iteration < 12; ++iteration) {
            const host = separatorHostComponent.createObject(testCase, {
                "separatorStyle": styles[iteration % styles.length],
                "verticalPanel": iteration % 2 === 0
            })

            verify(host !== null)
            wait(0)
            host.separatorCount = 0
            wait(0)
            host.destroy()
            wait(0)
        }
    }
}
