// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "PopupMarqueeLabel"
    when: windowShown

    Window {
        id: hostWindow
        width: 320
        height: 160
        visible: true

        Components.PopupMarqueeLabel {
            id: label
            anchors.centerIn: parent
            width: 96
            height: implicitHeight
            text: "Extraordinarily long application name"
        }
    }

    function init() {
        failOnWarning(/.?/)
        label.text = "Extraordinarily long application name"
        label.width = 96
        label.visibleCharacterLimit = 10
        label.shorteningEnabled = true
        label.shadowEnabled = false
        label.shadowPercent = 0
        label.motionEnabled = false
        label.hovered = false
        label.focused = false
        wait(0)
        label.motionEnabled = true
        wait(0)
    }

    function test_restingStateIsElidedByTheCalculatedViewport() {
        verify(label.overflowing)
        verify(label.viewportWidth <= label.maximumRestingWidth)
        compare(label.revealFullText, false)
        compare(label.scrollOffset, 0)
        compare(label.restingOpacity, 1)
        compare(label.movingOpacity, 0)
    }

    function test_hoverAndFocusRevealTheFullTextWithoutResizing() {
        const restingWidth = label.width
        label.hovered = true
        tryVerify(function() {
            return label.scrollOffset < 0 && label.movingOpacity > 0.5
        })
        compare(label.width, restingWidth)
        tryVerify(function() {
            return Math.abs(label.scrollOffset - label.terminalOffset) < 1.0
        })

        label.hovered = false
        label.focused = true
        verify(label.revealFullText)
        compare(label.width, restingWidth)

        label.focused = false
        tryCompare(label, "scrollOffset", 0)
        compare(label.width, restingWidth)
    }

    function test_marqueeUsesAReadableThemeScaledVelocity() {
        const oneGridUnitPerLongDuration = Kirigami.Units.gridUnit * 1000
            / Kirigami.Units.longDuration
        verify(label.marqueeVelocity >= oneGridUnitPerLongDuration * 0.5,
            "The caption must still reveal the full name without stalling")
        verify(label.marqueeVelocity <= oneGridUnitPerLongDuration * 0.7,
            "The caption must move more slowly than one grid unit per long duration")

        label.motionEnabled = false
        compare(label.marqueeVelocity, -1,
            "Reduced motion must keep disabling spatial text movement")
    }

    function test_visibleCharacterLimitChangesTheFontAwareCeiling() {
        label.visibleCharacterLimit = 6
        wait(0)
        const narrowCeiling = label.maximumRestingWidth

        label.visibleCharacterLimit = 14
        wait(0)
        verify(label.maximumRestingWidth > narrowCeiling)

        label.visibleCharacterLimit = 100
        wait(0)
        compare(label.safeVisibleCharacterLimit, 20)
    }

    function test_shorteningCanBeDisabledWithoutStartingTheMarquee() {
        label.shorteningEnabled = false
        label.hovered = true
        wait(0)

        compare(label.viewportWidth, label.width)
        verify(!label.overflowing)
        verify(!label.revealFullText)
        compare(label.scrollOffset, 0)
    }

    function test_reducedMotionKeepsTheElidedCaptionStable() {
        label.motionEnabled = false
        label.hovered = true
        wait(0)

        verify(label.revealFullText)
        compare(label.scrollOffset, 0)
        compare(label.restingOpacity, 1)
        compare(label.movingOpacity, 0)
    }

    function test_shortTextDoesNotCreateAFalseMarquee() {
        label.text = "Krita"
        label.hovered = true
        wait(0)

        verify(!label.overflowing)
        verify(!label.revealFullText)
        compare(label.scrollOffset, 0)
    }
}
