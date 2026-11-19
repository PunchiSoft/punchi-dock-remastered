// SPDX-License-Identifier: GPL-3.0-or-later
//
// Plasma 6.8 changed the applet loader to return std::unique_ptr and the
// containment to consume it. Keep the fixtures building against older Plasma
// releases while adopting the new ownership contract.

#pragma once

#include <memory>

#include <Plasma/Applet>
#include <Plasma/Containment>
#include <Plasma/PluginLoader>
#include <Plasma/plasma_version.h>
#include <QtGlobal>

namespace PunchiTest {

inline std::unique_ptr<Plasma::Applet> loadOwnedApplet(const QString &name,
                                                       uint appletId = 0)
{
#if PLASMA_VERSION >= QT_VERSION_CHECK(6, 8, 0)
    return Plasma::PluginLoader::self()->loadApplet(name, appletId);
#else
    return std::unique_ptr<Plasma::Applet>(
        Plasma::PluginLoader::self()->loadApplet(name, appletId));
#endif
}

// Hands the applet to the containment and returns the raw pointer owned by it.
// The caller's unique_ptr is released in both branches.
inline Plasma::Applet *adoptApplet(Plasma::Containment *containment,
                                   std::unique_ptr<Plasma::Applet> &owner)
{
    if (!containment || !owner) {
        return nullptr;
    }
    Plasma::Applet *applet = owner.get();
#if PLASMA_VERSION >= QT_VERSION_CHECK(6, 8, 0)
    containment->addApplet(std::move(owner));
#else
    containment->addApplet(applet);
    owner.release();
#endif
    return applet;
}

inline Plasma::Applet *createApplet(Plasma::Containment *containment,
                                    const QString &name, uint appletId = 0)
{
    auto owner = loadOwnedApplet(name, appletId);
    return adoptApplet(containment, owner);
}

} // namespace PunchiTest
