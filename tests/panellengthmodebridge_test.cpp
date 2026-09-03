// SPDX-License-Identifier: GPL-3.0-or-later

#include "panellengthmodebridge.h"

#include <iostream>

namespace
{
bool expect(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
    }
    return condition;
}
}

int main()
{
    bool passed = true;

    // Instance A (representing main.qml in panel)
    PanelLengthModeBridge mainBridge;
    mainBridge.setContainmentId(101);

    // Instance B (representing ConfigGeneral.qml in KCM dialog)
    PanelLengthModeBridge configBridge;
    configBridge.setContainmentId(101);

    // Initial state
    passed &= expect(configBridge.panelFloatingMode() == -1,
        "initial floating mode is unknown (-1)");

    // Report live floating state from main to bridge
    mainBridge.setReportedPanelFloatingMode(2); // 2: panelAndApplets

    passed &= expect(configBridge.panelFloatingMode() == 2,
        "configBridge receives panelAndApplets (2) reported by mainBridge");

    // Report state change to disabled
    mainBridge.setReportedPanelFloatingMode(0); // 0: disabled
    passed &= expect(configBridge.panelFloatingMode() == 0,
        "configBridge updates to disabled (0) when mainBridge changes");

    // Report state change to appletsOnly
    mainBridge.setReportedPanelFloatingMode(1); // 1: appletsOnly
    passed &= expect(configBridge.panelFloatingMode() == 1,
        "configBridge updates to appletsOnly (1) when mainBridge changes");

    // Different containment ID should be isolated
    PanelLengthModeBridge otherBridge;
    otherBridge.setContainmentId(202);
    passed &= expect(otherBridge.panelFloatingMode() == -1,
        "isolated containment id has independent state");

    // Visibility mode testing
    passed &= expect(configBridge.panelVisibilityMode() == -1,
        "initial visibility mode is unknown (-1)");

    mainBridge.setReportedPanelVisibilityMode(2); // 2: dodgeWindows
    passed &= expect(configBridge.panelVisibilityMode() == 2,
        "configBridge receives dodgeWindows (2) reported by mainBridge");

    mainBridge.setReportedPanelVisibilityMode(0); // 0: alwaysVisible
    passed &= expect(configBridge.panelVisibilityMode() == 0,
        "configBridge updates to alwaysVisible (0) when mainBridge changes");

    mainBridge.setReportedPanelVisibilityMode(1); // 1: autoHide
    passed &= expect(configBridge.panelVisibilityMode() == 1,
        "configBridge updates to autoHide (1) when mainBridge changes");

    mainBridge.setReportedPanelVisibilityMode(3); // 3: windowsGoBelow
    passed &= expect(configBridge.panelVisibilityMode() == 3,
        "configBridge updates to windowsGoBelow (3) when mainBridge changes");

    passed &= expect(otherBridge.panelVisibilityMode() == -1,
        "isolated containment id has independent visibility mode");

    // Length mode testing
    passed &= expect(configBridge.panelLengthMode() == -1,
        "initial length mode is unknown (-1)");

    mainBridge.setReportedPanelLengthMode(1); // 1: fitContent
    passed &= expect(configBridge.panelLengthMode() == 1 && !configBridge.fillAvailable(),
        "configBridge receives fitContent (1) and fillAvailable is false");

    mainBridge.setReportedPanelLengthMode(0); // 0: fillAvailable
    passed &= expect(configBridge.panelLengthMode() == 0 && configBridge.fillAvailable(),
        "configBridge receives fillAvailable (0) and fillAvailable is true");

    mainBridge.setReportedPanelLengthMode(2); // 2: custom
    passed &= expect(configBridge.panelLengthMode() == 2 && !configBridge.fillAvailable(),
        "configBridge receives custom (2) and fillAvailable is false");

    passed &= expect(otherBridge.panelLengthMode() == -1,
        "isolated containment id has independent length mode");

    // Alignment testing
    passed &= expect(configBridge.panelAlignment() == -1,
        "initial alignment is unknown (-1)");

    mainBridge.setReportedPanelAlignment(1); // 1: center
    passed &= expect(configBridge.panelAlignment() == 1,
        "configBridge receives center (1) reported by mainBridge");

    mainBridge.setReportedPanelAlignment(0); // 0: start / left / top
    passed &= expect(configBridge.panelAlignment() == 0,
        "configBridge updates to start (0) when mainBridge changes");

    mainBridge.setReportedPanelAlignment(2); // 2: end / right / bottom
    passed &= expect(configBridge.panelAlignment() == 2,
        "configBridge updates to end (2) when mainBridge changes");

    passed &= expect(otherBridge.panelAlignment() == -1,
        "isolated containment id has independent alignment");

    // Thickness testing
    passed &= expect(configBridge.panelThickness() == 0,
        "initial thickness is 0");

    mainBridge.setReportedPanelThickness(64);
    passed &= expect(configBridge.panelThickness() == 64,
        "configBridge receives thickness 64 reported by mainBridge");

    mainBridge.setReportedPanelThickness(48);
    passed &= expect(configBridge.panelThickness() == 48,
        "configBridge updates to thickness 48 when mainBridge changes");

    passed &= expect(otherBridge.panelThickness() == 0,
        "isolated containment id has independent thickness");

    return passed ? 0 : 1;
}
