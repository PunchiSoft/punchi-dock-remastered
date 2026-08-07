// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include "dockitemsjsontransaction.h"

#include <QMetaObject>
#include <QObject>
#include <QPointer>
#include <QVariantMap>
#include <qqmlregistration.h>

class DockItemsPersistenceAdapter : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QObject *applet READ applet WRITE setApplet NOTIFY appletChanged)

public:
    explicit DockItemsPersistenceAdapter(QObject *parent = nullptr);

    [[nodiscard]] QObject *applet() const;
    void setApplet(QObject *applet);

    Q_INVOKABLE QVariantMap commitDockItemsJson(
        const QString &expectedRaw,
        const QString &nextRaw);
    Q_INVOKABLE QVariantMap reconcileDockItemsJson(
        const QString &expectedDurable);

Q_SIGNALS:
    void appletChanged();

private:
    QPointer<QObject> m_applet;
    QMetaObject::Connection m_appletDestroyedConnection;
    DockItemsJsonTransaction::State m_transactionState;
};
