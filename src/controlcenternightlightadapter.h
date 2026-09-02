// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KConfigWatcher>
#include <KSharedConfig>

#include <QObject>
#include <QVariantMap>
#include <qqmlregistration.h>

class QDBusServiceWatcher;

class ControlCenterNightLightAdapter : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool available READ available NOTIFY stateChanged)
    Q_PROPERTY(bool configured READ configured NOTIFY stateChanged)
    Q_PROPERTY(bool running READ running NOTIFY stateChanged)
    Q_PROPERTY(bool inhibited READ inhibited NOTIFY stateChanged)
    Q_PROPERTY(bool ownsInhibition READ ownsInhibition NOTIFY stateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY stateChanged)
    Q_PROPERTY(int strength READ strength NOTIFY stateChanged)

public:
    explicit ControlCenterNightLightAdapter(QObject *parent = nullptr);
    ~ControlCenterNightLightAdapter() override;

    bool available() const;
    bool configured() const;
    bool running() const;
    bool inhibited() const;
    bool ownsInhibition() const;
    bool busy() const;
    int strength() const;

    Q_INVOKABLE bool toggleEnabled();
    Q_INVOKABLE bool toggleSuspended();
    Q_INVOKABLE bool previewStrength(int strength);
    Q_INVOKABLE bool setStrength(int strength);
    Q_INVOKABLE void stopPreview();
    Q_INVOKABLE void refresh();

    static int strengthForTemperature(int temperature);
    static int temperatureForStrength(int strength);

Q_SIGNALS:
    void stateChanged();

private Q_SLOTS:
    void handlePropertiesChanged(const QString &interfaceName, const QVariantMap &changedProperties, const QStringList &invalidatedProperties);

private:
    void requestInhibition();
    void releaseInhibition();
    void readConfiguration();
    void requestKWinReconfigure();
    void resetState();
    void updateState(const QVariantMap &properties);
    void setBusy(bool busy);

    QDBusServiceWatcher *m_serviceWatcher = nullptr;
    KSharedConfig::Ptr m_config;
    KConfigWatcher::Ptr m_configWatcher;
    quint32 m_inhibitionCookie = 0;
    quint64 m_refreshGeneration = 0;
    bool m_available = false;
    bool m_configured = false;
    bool m_running = false;
    bool m_inhibited = false;
    bool m_busy = false;
    int m_strength = 36;
};
