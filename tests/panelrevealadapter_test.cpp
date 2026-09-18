// SPDX-License-Identifier: GPL-3.0-or-later

// Guards of the panel reveal adapter.
//
// The reveal itself needs a running plasmashell, so the real transition is
// validated in the user's session. These checks protect the paths that must
// never touch Plasma: no applet, a plain QObject, and repeated begin/end calls.

#include "panelrevealadapter.h"

#include <QObject>

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

    PanelRevealAdapter adapter;
    passed &= expect(adapter.applet() == nullptr, "no applet by default");
    passed &= expect(!adapter.revealing(), "the adapter starts idle");

    int changeCount = 0;
    QObject::connect(&adapter, &PanelRevealAdapter::revealingChanged, [&changeCount]() {
        ++changeCount;
    });

    passed &= expect(!adapter.beginReveal(), "a reveal without an applet is refused");
    passed &= expect(!adapter.revealing(), "a refused reveal keeps the adapter idle");
    passed &= expect(changeCount == 0, "a refused reveal does not notify a change");

    adapter.endReveal();
    passed &= expect(!adapter.revealing(), "ending without revealing is harmless");
    passed &= expect(changeCount == 0, "ending without revealing does not notify");

    // A plain QObject is not a Plasma applet.
    QObject stranger;
    adapter.setApplet(&stranger);
    passed &= expect(adapter.applet() == &stranger, "the applet pointer is stored");
    passed &= expect(!adapter.beginReveal(), "a non-applet object cannot reveal a panel");

    adapter.setApplet(nullptr);
    passed &= expect(!adapter.revealing(), "clearing the applet keeps the adapter idle");
    passed &= expect(changeCount == 0, "no reveal ever happened during the checks");

    if (passed) {
        std::cout << "PanelRevealAdapter: OK" << '\n';
    }
    return passed ? 0 : 1;
}
