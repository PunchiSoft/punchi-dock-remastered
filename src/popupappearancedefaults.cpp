// SPDX-License-Identifier: GPL-3.0-or-later
#include "popupappearancedefaults.h"

#include <KConfigGroup>
#include <KConfigLoader>
#include <KConfigPropertyMap>
#include <Plasma/Applet>
#include <QLibraryInfo>

namespace {
bool usesOpaqueDefaults(const QVersionNumber &version)
{
    return version.majorVersion() == 6 && version.minorVersion() == 8;
}

template<class Item, class Value>
void updateDefault(KCoreConfigSkeleton *configuration, KConfigPropertyMap *map,
                   const QString &key, const Value &value)
{
    auto *item = dynamic_cast<Item *>(configuration->findItem(key));
    if (!item) {
        return;
    }
    item->setDefaultValue(value);
    map->insert(key + QStringLiteral("Default"), value);
    // Saved choices, including an explicit value equal to the old default,
    // remain untouched. This changes the in-memory default without saving it.
    const KConfigGroup group(configuration->config(), item->group());
    if (!group.hasKey(item->key()) && !item->isImmutable()) {
        item->setDefault();
        map->insert(key, item->property());
    }
}
}

PopupAppearanceDefaults::PopupAppearanceDefaults(QObject *parent) : QObject(parent) {}
QObject *PopupAppearanceDefaults::applet() const { return m_applet.data(); }
bool PopupAppearanceDefaults::opaquePopupsByDefault() const
{
    return usesOpaqueDefaults(QLibraryInfo::version());
}
int PopupAppearanceDefaults::popupOpacityPercent() const
{
    return opaquePopupsByDefault() ? 100 : 75;
}

void PopupAppearanceDefaults::apply(KCoreConfigSkeleton *configuration,
                                   KConfigPropertyMap *map,
                                   const QVersionNumber &qtVersion)
{
    if (!configuration || !map || !usesOpaqueDefaults(qtVersion)) {
        return;
    }
    for (const QString &key : {QStringLiteral("folderPopupBackgroundOpacityPercent"),
                              QStringLiteral("windowPreviewBackgroundOpacityPercent"),
                              QStringLiteral("mediaCardBackgroundOpacityPercent")}) {
        updateDefault<KCoreConfigSkeleton::ItemInt>(configuration, map, key, 100);
    }
    updateDefault<KCoreConfigSkeleton::ItemBool>(configuration, map,
                                               QStringLiteral("popupBackgroundBlurEnabled"), false);
}

void PopupAppearanceDefaults::setApplet(QObject *applet)
{
    auto *plasmaApplet = qobject_cast<Plasma::Applet *>(applet);
    if (m_applet == plasmaApplet) {
        return;
    }
    QObject::disconnect(m_reloadConnection);
    m_applet = plasmaApplet;
    if (plasmaApplet) {
        auto *configuration = plasmaApplet->configScheme();
        auto *map = plasmaApplet->configuration();
        apply(configuration, map, QLibraryInfo::version());
        // KConfigLoader rereads builtin XML defaults on a reload. Restore the
        // runtime-specific defaults after the property map has refreshed.
        m_reloadConnection = connect(configuration, &KCoreConfigSkeleton::configChanged,
                                     this, [this]() {
            if (auto *current = qobject_cast<Plasma::Applet *>(m_applet.data())) {
                apply(current->configScheme(), current->configuration(), QLibraryInfo::version());
            }
        });
    }
    Q_EMIT appletChanged();
}
