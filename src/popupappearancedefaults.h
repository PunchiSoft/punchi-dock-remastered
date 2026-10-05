// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QPointer>
#include <QVersionNumber>
#include <qqmlregistration.h>

class KCoreConfigSkeleton;
class KConfigPropertyMap;

class PopupAppearanceDefaults : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QObject *applet READ applet WRITE setApplet NOTIFY appletChanged)
    Q_PROPERTY(bool opaquePopupsByDefault READ opaquePopupsByDefault CONSTANT)
    Q_PROPERTY(int popupOpacityPercent READ popupOpacityPercent CONSTANT)

public:
    explicit PopupAppearanceDefaults(QObject *parent = nullptr);
    QObject *applet() const;
    void setApplet(QObject *applet);
    bool opaquePopupsByDefault() const;
    int popupOpacityPercent() const;
    static void apply(KCoreConfigSkeleton *configuration, KConfigPropertyMap *map,
                      const QVersionNumber &qtVersion);

Q_SIGNALS:
    void appletChanged();

private:
    QPointer<QObject> m_applet;
    QMetaObject::Connection m_reloadConnection;
};
