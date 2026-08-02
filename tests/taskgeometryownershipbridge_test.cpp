// SPDX-License-Identifier: GPL-3.0-or-later

#include "taskgeometryownershipbridge.h"

#include <iostream>
#include <memory>

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

    TaskGeometryOwnershipBridge floating;
    floating.setInstanceId(20);
    passed &= expect(floating.ownsTaskGeometry(),
        "the first eligible floating instance owns task geometry");

    TaskGeometryOwnershipBridge panel;
    panel.setInstanceId(30);
    panel.setPanel(true);
    passed &= expect(panel.ownsTaskGeometry() && !floating.ownsTaskGeometry(),
        "a panel instance takes ownership from a floating instance");

    auto preferredPanel = std::make_unique<TaskGeometryOwnershipBridge>();
    preferredPanel->setInstanceId(10);
    preferredPanel->setPanel(true);
    passed &= expect(preferredPanel->ownsTaskGeometry() && !panel.ownsTaskGeometry(),
        "the lowest panel instance id wins the deterministic tie break");

    preferredPanel->setEligible(false);
    passed &= expect(panel.ownsTaskGeometry(),
        "ownership transfers when the preferred panel becomes ineligible");

    panel.setEligible(false);
    passed &= expect(floating.ownsTaskGeometry(),
        "an eligible floating instance is the fallback without an eligible panel");

    panel.setEligible(true);
    passed &= expect(panel.ownsTaskGeometry(),
        "an eligible panel reclaims ownership from the floating fallback");

    preferredPanel->setEligible(true);
    passed &= expect(preferredPanel->ownsTaskGeometry(),
        "the preferred panel can reclaim ownership");
    preferredPanel.reset();
    passed &= expect(panel.ownsTaskGeometry(),
        "destroying the owner transfers ownership to the next panel");

    return passed ? 0 : 1;
}
