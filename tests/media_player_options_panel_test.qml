// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/config" as Config
import "../contents/ui/config/components" as ConfigComponents

// Behaviour of the media player options panel and its parity with the dialog that
// hosts it.
//
// The panel is a passive component: the values it shows arrive through its
// properties—including the list of players, which arrives asynchronously—and the
// user interaction is announced through its signals. The activation of a combo is
// simulated by emitting the signal the control itself emits when the user picks an
// item, which is the exact contract the panel responds to.
TestCase {
    id: testCase

    name: "MediaPlayerOptionsPanel"
    when: windowShown

    SignalSpy {
        id: panelPlayerSpy
        signalName: "playerSelected"
    }

    SignalSpy {
        id: panelTextModeSpy
        signalName: "mediaTextModeSelected"
    }

    SignalSpy {
        id: panelDisplayModeSpy
        signalName: "mediaDisplayModeSelected"
    }

    SignalSpy {
        id: panelMinimizedSpy
        signalName: "openPlayerMinimizedSelected"
    }

    SignalSpy {
        id: panelDelaySpy
        signalName: "autoCollapseDelaySecondsSelected"
    }

    SignalSpy {
        id: dialogPlayerSpy
        signalName: "playerSelected"
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow

            property alias panel: optionsPanel
            property alias dialog: mediaDialog

            width: 720
            height: 900
            visible: true

            Config.MediaPlayerOptionsPanel {
                id: optionsPanel
                anchors.left: parent.left
                anchors.top: parent.top
                width: 620
            }

            ConfigComponents.MediaPlayerDialog {
                id: mediaDialog
                title: "Configure media player"
                width: 480
            }
        }
    }

    readonly property var discoveredApplications: [
        {
            "storageId": "org.example.Zeta.desktop",
            "name": "Zeta",
            "icon": "zeta-icon"
        },
        {
            "storageId": "org.example.Alpha.desktop",
            "name": "Alpha",
            "icon": "alpha-icon"
        },
        {
            "storageId": "org.example.Zeta.desktop",
            "name": "Zeta duplicated"
        }
    ]

    function init() {
        failOnWarning(/.?/)
        panelPlayerSpy.clear()
        panelTextModeSpy.clear()
        panelDisplayModeSpy.clear()
        panelMinimizedSpy.clear()
        panelDelaySpy.clear()
        dialogPlayerSpy.clear()
    }

    function attachPanelSpies(panel) {
        panelPlayerSpy.target = panel
        panelTextModeSpy.target = panel
        panelDisplayModeSpy.target = panel
        panelMinimizedSpy.target = panel
        panelDelaySpy.target = panel
    }

    function selector(panel) {
        return findChild(panel, "mediaPlayerSelector")
    }

    function textModeSelector(panel) {
        return findChild(panel, "mediaTextModeSelector")
    }

    function displayModeSelector(panel) {
        return findChild(panel, "mediaDisplayModeSelector")
    }

    function delaySpinBox(panel) {
        return findChild(panel, "mediaAutoCollapseDelaySpinBox")
    }

    function optionValues(panel, property) {
        return panel[property].map(function(option) {
            return String(option.value)
        })
    }

    function optionTexts(panel, property) {
        return panel[property].map(function(option) {
            return String(option.text)
        })
    }

    function playerStorageIds(panel) {
        return panel.playerOptions.map(function(option) {
            return String(option.storageId)
        })
    }

    function verifySameValueColumn(reference, item, message) {
        tryVerify(function() {
            return Math.abs(Number(reference.x) - Number(item.x))
                <= Kirigami.Units.smallSpacing
        }, 2000, message)
    }

    function test_panelAndDialogOfferTheSameOptions() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        const dialog = host.dialog

        compare(optionValues(panel, "textModeOptions"),
            ["automatic", "always", "hidden"],
            "The panel owns the list of track-information modes")
        compare(optionTexts(panel, "textModeOptions"),
            ["Automatic (recommended)", "Always show", "Hide"])
        compare(optionValues(panel, "displayModeOptions"), ["normal", "compact"],
            "The panel owns the list of display modes")
        compare(optionTexts(panel, "displayModeOptions"),
            ["Normal (recommended)", "Compact"])
        compare(optionValues(dialog, "textModeOptions"),
            optionValues(panel, "textModeOptions"),
            "The dialog must not keep a second list of modes")
        compare(optionValues(dialog, "displayModeOptions"),
            optionValues(panel, "displayModeOptions"),
            "The dialog must not keep a second list of modes")
        compare(panel.playerOptions.length, 1,
            "Without discovered applications the panel offers Automatic only")
        compare(String(panel.playerOptions[0].text), "Automatic (active player)")
        compare(panel.selectedStorageId, "", "The default is the active player")
        compare(panel.mediaTextMode, "automatic")
        compare(panel.mediaDisplayMode, "normal")
        compare(panel.openPlayerMinimized, false)
        compare(panel.autoCollapseDelaySeconds, 3)
    }

    function test_layoutUsesRowsWhenWideAndStacksWhenNarrow() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        panel.applications = testCase.discoveredApplications
        panel.mediaDisplayMode = "compact"

        tryVerify(function() {
            return panel.wideMode
        }, 2000, "A dialog-sized panel must use label-control rows")

        const description = findChild(panel, "mediaPlayerDescription")
        const player = selector(panel)
        const minimized = findChild(panel, "openPlayerMinimizedCheckBox")
        const textMode = textModeSelector(panel)
        const textHelp = findChild(panel, "mediaTrackInformationHelp")
        const displayMode = displayModeSelector(panel)
        const delay = delaySpinBox(panel)
        const scopeHelp = findChild(panel, "mediaItemScopeHelp")

        tryVerify(function() {
            return delay.visible && scopeHelp.y > delay.y
        }, 2000, "The complete compact-mode form must be laid out")
        verifySameValueColumn(player, textMode,
            "Selectors must share the same value column")
        verifySameValueColumn(player, displayMode,
            "The display selector must share the value column")
        verifySameValueColumn(player, delay,
            "A conditionally visible control must use the value column")
        verifySameValueColumn(player, description,
            "The introduction must begin with the form values")
        verifySameValueColumn(player, textHelp,
            "Help must stay attached to the value it explains")
        verifySameValueColumn(player, scopeHelp,
            "The final help must stay in the value column")
        verify(description.y < player.y)
        verify(player.y < minimized.y)
        verify(minimized.y < textMode.y)
        verify(textMode.y < textHelp.y)
        verify(textHelp.y < displayMode.y)
        verify(displayMode.y < delay.y)
        verify(delay.y < scopeHelp.y)
        verify(scopeHelp.y + scopeHelp.height <= panel.implicitHeight + 1,
            "The panel's implicit height must include its final help row")

        panel.width = 300
        tryVerify(function() {
            return !panel.wideMode
        }, 2000, "A narrow panel must stack labels above their controls")
        const controls = [player, minimized, textMode, displayMode, delay]
        for (let index = 0; index < controls.length; index++) {
            tryVerify(function() {
                return controls[index].x >= 0
                    && controls[index].x + controls[index].width
                        <= panel.width + 1
            }, 2000, "A stacked control must not overflow the narrow panel")
        }
        verify(scopeHelp.y + scopeHelp.height <= panel.implicitHeight + 1,
            "The stacked form must still report its complete height")
    }

    function test_aLateListOfApplicationsRebuildsTheOptionsWithoutChoosing() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)
        panel.selectedStorageId = "org.example.Alpha.desktop"

        panel.applications = testCase.discoveredApplications
        tryVerify(function() {
            return panel.playerOptions.length === 3
        }, 2000, "The options must be rebuilt from the list that arrived")
        compare(playerStorageIds(panel),
            ["", "org.example.Alpha.desktop", "org.example.Zeta.desktop"],
            "The automatic entry comes first and the rest is sorted by name, "
            + "without duplicates")
        tryVerify(function() {
            return selector(panel).currentIndex === 1
        }, 2000, "The selection must follow the value that was already set")
        compare(panelPlayerSpy.count, 0,
            "A list that arrives late is not a choice of the user")
        compare(panel.selectedStorageId, "org.example.Alpha.desktop",
            "The panel writes nothing")
    }

    function test_userActivationAnnouncesExactlyOneIntention() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)
        panel.applications = testCase.discoveredApplications
        tryVerify(function() {
            return panel.playerOptions.length === 3
        }, 2000, "The options must be built before choosing")

        const combo = selector(panel)
        combo.activated(2)
        compare(panelPlayerSpy.count, 1, "One activation, one intention")
        const chosen = panelPlayerSpy.signalArguments[0][0]
        compare(String(chosen.storageId), "org.example.Zeta.desktop")
        compare(String(chosen.name), "Zeta")
        compare(panel.selectedStorageId, "",
            "The panel writes nothing: the value belongs to its caller")

        panel.selectedStorageId = "org.example.Zeta.desktop"
        tryVerify(function() {
            return combo.currentIndex === 2
        }, 2000, "Following the intention of the caller must not announce it again")
        compare(panelPlayerSpy.count, 1)

        combo.activated(0)
        compare(panelPlayerSpy.count, 2, "Choosing Automatic is an intention too")
        compare(panelPlayerSpy.signalArguments[1][0].storageId, undefined,
            "Automatic announces an empty application")
    }

    function test_externalValuesMoveTheControlsWithoutAnnouncing() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)

        panel.mediaTextMode = "hidden"
        compare(textModeSelector(panel).currentIndex, 2,
            "A value set from outside must reach the shown selection")
        compare(panelTextModeSpy.count, 0)

        panel.mediaDisplayMode = "compact"
        compare(displayModeSelector(panel).currentIndex, 1)
        compare(panelDisplayModeSpy.count, 0)
        compare(delaySpinBox(panel).visible, true,
            "The delay is only offered in compact mode")

        panel.autoCollapseDelaySeconds = 12
        compare(delaySpinBox(panel).value, 12,
            "A delay set from outside must reach the control")
        compare(panelDelaySpy.count, 0)

        panel.openPlayerMinimized = true
        compare(findChild(panel, "openPlayerMinimizedCheckBox").checked, true)
        compare(panelMinimizedSpy.count, 0)

        panel.mediaTextMode = "always"
        compare(textModeSelector(panel).currentIndex, 1)
        compare(panelTextModeSpy.count, 0)
    }

    function test_userInteractionAnnouncesEachValueOnce() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)

        // The control moves its own index before announcing the activation, so the
        // case reproduces that order: the intention reads the value it now shows.
        const textMode = textModeSelector(panel)
        textMode.currentIndex = 1
        textMode.activated(1)
        compare(panelTextModeSpy.count, 1)
        compare(panelTextModeSpy.signalArguments[0][0], "always")

        const displayMode = displayModeSelector(panel)
        displayMode.currentIndex = 1
        displayMode.activated(1)
        compare(panelDisplayModeSpy.count, 1)
        compare(panelDisplayModeSpy.signalArguments[0][0], "compact")

        panel.mediaDisplayMode = "compact"
        const spin = delaySpinBox(panel)
        compare(spin.visible, true, "The delay is offered in compact mode")
        compare(spin.value, 3)
        // A real interaction: the control announces a change only when the user
        // makes it, and the keyboard is one of those paths.
        host.requestActivate()
        tryVerify(function() {
            return host.active
        }, 2000, "The window must be active to receive keys")
        spin.forceActiveFocus()
        tryVerify(function() {
            return spin.activeFocus
        }, 2000, "The spin box must take the focus to be typed into")
        keyClick(Qt.Key_Up)
        compare(spin.value, 4, "The keyboard turns the value up")
        compare(panelDelaySpy.count, 1, "One interaction, one intention")
        compare(panelDelaySpy.signalArguments[0][0], 4)
        compare(panel.autoCollapseDelaySeconds, 3,
            "The panel writes nothing: the value belongs to its caller")

        const minimized = findChild(panel, "openPlayerMinimizedCheckBox")
        minimized.clicked()
        compare(panelMinimizedSpy.count, 1)
        compare(panelMinimizedSpy.signalArguments[0][0], false,
            "The switch announces the opposite of its current state")
    }

    function test_dialogKeepsItsPublicApiAndForwardsThePanel() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const dialog = host.dialog
        dialogPlayerSpy.target = dialog

        compare(dialog.title, "Configure media player",
            "The title the page sets is kept")
        compare(dialog.modal, true, "The dialog is still modal")
        compare(dialog.playerOptions.length, 1,
            "The dialog answers with the options of the panel")

        dialog.selectedStorageId = "org.example.Alpha.desktop"
        dialog.mediaTextMode = "hidden"
        dialog.mediaDisplayMode = "compact"
        dialog.openPlayerMinimized = true
        dialog.autoCollapseDelaySeconds = 9
        dialog.applications = testCase.discoveredApplications

        dialog.open()
        tryVerify(function() {
            return dialog.visible
        }, 2000, "The dialog must open")
        tryVerify(function() {
            return selector(dialog).currentIndex === 1
        }, 2000, "Opening must show the stored player")
        compare(textModeSelector(dialog).currentIndex, 2)
        compare(displayModeSelector(dialog).currentIndex, 1)
        compare(delaySpinBox(dialog).value, 9)

        selector(dialog).activated(2)
        compare(dialogPlayerSpy.count, 1,
            "The dialog must forward the intention of the panel exactly once")
        compare(dialog.selectedStorageId, "org.example.Zeta.desktop",
            "Choosing a player must also update the dialog")
        dialog.close()
    }

    function test_rebuildingTheOptionsIsIdempotent() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const dialog = host.dialog
        dialogPlayerSpy.target = dialog

        dialog.applications = testCase.discoveredApplications
        tryVerify(function() {
            return dialog.playerOptions.length === 3
        }, 2000, "The options must be built")
        dialog.rebuildOptions()
        dialog.syncSelection()
        dialog.syncTextModeSelection()
        dialog.syncDisplayModeSelection()
        compare(dialog.playerOptions.length, 3,
            "Rebuilding twice must not duplicate the entries")
        compare(dialogPlayerSpy.count, 0, "Rebuilding is not a choice")
    }

    function test_controlsStayInteractiveAndAccessible() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel

        const combo = selector(panel)
        compare(combo.Accessible.name, "Default media player")
        verify(String(combo.Accessible.description).length > 0,
            "The player selector must describe what it chooses")
        compare(combo.activeFocusOnTab, true,
            "The player selector stays reachable with the keyboard")
        compare(textModeSelector(panel).Accessible.name, "Track information visibility")
        compare(displayModeSelector(panel).Accessible.name, "Media item display mode")
        compare(delaySpinBox(panel).Accessible.name,
            "Media controls auto-collapse delay")

        mouseClick(combo)
        wait(20)
        verify(combo.popup.visible, "A click must open the list of players")
        combo.popup.close()
        wait(20)
    }
}
