// SPDX-License-Identifier: GPL-3.0-or-later

#include "commandclassification.h"

#include <array>
#include <iostream>

namespace
{
struct TestCase {
    const char *name;
    const char *command;
    bool expected;
};
}

int main()
{
    const std::array tests = {
        TestCase{"bare executable", "konsole", true},
        TestCase{"absolute executable", "/usr/bin/konsole", true},
        TestCase{"quoted executable", "'/opt/My Terminal/bin/terminal'", true},
        TestCase{"desktop id", "org.kde.konsole.desktop", true},
        TestCase{"empty", "   ", false},
        TestCase{"arguments", "konsole -e htop", false},
        TestCase{"quoted argument", "firefox 'https://example.com/a b'", false},
        TestCase{"flatpak invocation", "flatpak run org.example.App", false},
        TestCase{"environment assignment", "PROFILE=test firefox", false},
        TestCase{"variable expansion", "firefox $HOME", false},
        TestCase{"pipeline", "first | second", false},
        TestCase{"command chain", "first && second", false},
        TestCase{"redirection", "first > output.txt", false},
        TestCase{"invalid quoting", "konsole 'unterminated", false},
    };

    bool passed = true;
    for (const TestCase &test : tests) {
        const bool result = CommandClassification::canResolveToDesktopService(QString::fromUtf8(test.command));
        if (result != test.expected) {
            std::cerr << "FAILED: " << test.name << '\n';
            passed = false;
        }
    }
    return passed ? 0 : 1;
}
