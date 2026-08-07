// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockitemspersistenceadapter.h"

#include "dockitemsjsontransaction.h"

#include <KConfigLoader>
#include <Plasma/Applet>

DockItemsPersistenceAdapter::DockItemsPersistenceAdapter(QObject *parent)
    : QObject(parent)
{
}

QObject *DockItemsPersistenceAdapter::applet() const
{
    return m_applet.data();
}

void DockItemsPersistenceAdapter::setApplet(QObject *applet)
{
    Plasma::Applet *const plasmaApplet = qobject_cast<Plasma::Applet *>(applet);
    if (m_applet == plasmaApplet) {
        return;
    }

    QObject::disconnect(m_appletDestroyedConnection);
    m_applet = plasmaApplet;
    m_transactionState = {};
    if (m_applet) {
        m_appletDestroyedConnection = connect(
            m_applet.data(),
            &QObject::destroyed,
            this,
            [this]() {
                m_applet = nullptr;
                m_transactionState = {};
                Q_EMIT appletChanged();
            });
    } else {
        m_appletDestroyedConnection = {};
    }
    Q_EMIT appletChanged();
}

QVariantMap DockItemsPersistenceAdapter::commitDockItemsJson(
    const QString &expectedRaw,
    const QString &nextRaw)
{
    Plasma::Applet *const plasmaApplet = qobject_cast<Plasma::Applet *>(
        m_applet.data());
    KCoreConfigSkeleton *configuration = plasmaApplet
        ? plasmaApplet->configScheme()
        : nullptr;
    return DockItemsJsonTransaction::commit(
        configuration, m_transactionState,
        expectedRaw, nextRaw).toVariantMap();
}

QVariantMap DockItemsPersistenceAdapter::reconcileDockItemsJson(
    const QString &expectedDurable)
{
    Plasma::Applet *const plasmaApplet = qobject_cast<Plasma::Applet *>(
        m_applet.data());
    KCoreConfigSkeleton *configuration = plasmaApplet
        ? plasmaApplet->configScheme()
        : nullptr;
    return DockItemsJsonTransaction::reconcile(
        configuration, m_transactionState,
        expectedDurable).toVariantMap();
}
