// SPDX-License-Identifier: GPL-3.0-or-later

#include <QtQuickTest>
#include <PlasmaQuick/SharedQmlEngine>

// Keep Plasma's engine alive while Qt 6.8 executes the separate QtTest engine.
// Each fixture still destroys its actual pages and applets after every case.
static int runWithSharedPlasmaEngine(int argc, char **argv, const char *name,
                                    const char *sourceDirectory, QObject *setup)
{
    PlasmaQuick::SharedQmlEngine lifetime;
    return quick_test_main_with_setup(argc, argv, name, sourceDirectory, setup);
}

#define quick_test_main_with_setup runWithSharedPlasmaEngine
#include PUNCHI_ORIGINAL_RECENT_RUNNER
#undef quick_test_main_with_setup
