// SPDX-License-Identifier: GPL-2.0-or-later

#include "controlcenternightlightadapter.h"

#include <KConfigGroup>

#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusServiceWatcher>
#include <QtMath>

namespace
{
constexpr auto s_service = "org.kde.KWin.NightLight";
constexpr auto s_path = "/org/kde/KWin/NightLight";
constexpr auto s_interface = "org.kde.KWin.NightLight";
constexpr auto s_propertiesInterface = "org.freedesktop.DBus.Properties";
constexpr auto s_kwinService = "org.kde.KWin";
constexpr auto s_kwinPath = "/KWin";
constexpr auto s_kwinInterface = "org.kde.KWin";
constexpr auto s_configGroup = "NightColor";
constexpr int s_constantMode = 0;
constexpr int s_minimumTemperature = 1000;
constexpr int s_maximumTemperature = 6500;
constexpr int s_defaultTemperature = 4500;
constexpr int s_temperatureStep = 100;

QDBusMessage nightLightCall(const QString &method)
{
    return QDBusMessage::createMethodCall(QString::fromLatin1(s_service), QString::fromLatin1(s_path), QString::fromLatin1(s_interface), method);
}
}

ControlCenterNightLightAdapter::ControlCenterNightLightAdapter(QObject *parent)
    : QObject(parent)
    , m_serviceWatcher(new QDBusServiceWatcher(QString::fromLatin1(s_service),
                                               QDBusConnection::sessionBus(),
                                               QDBusServiceWatcher::WatchForRegistration | QDBusServiceWatcher::WatchForUnregistration,
                                               this))
    , m_config(KSharedConfig::openConfig(QStringLiteral("kwinrc")))
    , m_configWatcher(KConfigWatcher::create(m_config))
{
    connect(m_serviceWatcher, &QDBusServiceWatcher::serviceRegistered, this, [this]() {
        refresh();
    });
    connect(m_serviceWatcher, &QDBusServiceWatcher::serviceUnregistered, this, [this]() {
        m_inhibitionCookie = 0;
        resetState();
    });

    QDBusConnection::sessionBus().connect(QString::fromLatin1(s_service),
                                          QString::fromLatin1(s_path),
                                          QString::fromLatin1(s_propertiesInterface),
                                          QStringLiteral("PropertiesChanged"),
                                          this,
                                          SLOT(handlePropertiesChanged(QString,QVariantMap,QStringList)));
    connect(m_configWatcher.data(), &KConfigWatcher::configChanged, this, [this](const KConfigGroup &group, const QByteArrayList &keys) {
        if (group.name() == QLatin1String(s_configGroup)
            && (keys.isEmpty() || keys.contains(QByteArrayLiteral("NightTemperature")))) {
            readConfiguration();
        }
    });
    readConfiguration();
    refresh();
}

ControlCenterNightLightAdapter::~ControlCenterNightLightAdapter()
{
    if (m_inhibitionCookie == 0 || !QDBusConnection::sessionBus().isConnected()) {
        return;
    }

    QDBusMessage message = nightLightCall(QStringLiteral("uninhibit"));
    message << m_inhibitionCookie;
    QDBusConnection::sessionBus().call(message, QDBus::NoBlock);
}

bool ControlCenterNightLightAdapter::available() const
{
    return m_available;
}

bool ControlCenterNightLightAdapter::configured() const
{
    return m_configured;
}

bool ControlCenterNightLightAdapter::running() const
{
    return m_running;
}

bool ControlCenterNightLightAdapter::inhibited() const
{
    return m_inhibited;
}

bool ControlCenterNightLightAdapter::ownsInhibition() const
{
    return m_inhibitionCookie != 0;
}

bool ControlCenterNightLightAdapter::busy() const
{
    return m_busy;
}

int ControlCenterNightLightAdapter::strength() const
{
    return m_strength;
}

int ControlCenterNightLightAdapter::strengthForTemperature(int temperature)
{
    const int boundedTemperature = qBound(s_minimumTemperature, temperature, s_maximumTemperature);
    return qRound((s_maximumTemperature - boundedTemperature) * 100.0
                  / (s_maximumTemperature - s_minimumTemperature));
}

int ControlCenterNightLightAdapter::temperatureForStrength(int strength)
{
    const int boundedStrength = qBound(0, strength, 100);
    const qreal unroundedTemperature = s_maximumTemperature
        - boundedStrength * (s_maximumTemperature - s_minimumTemperature) / 100.0;
    const int steppedTemperature = qRound(unroundedTemperature / s_temperatureStep) * s_temperatureStep;
    return qBound(s_minimumTemperature, steppedTemperature, s_maximumTemperature);
}

bool ControlCenterNightLightAdapter::toggleEnabled()
{
    if (!m_available || m_busy) {
        return false;
    }

    KConfigGroup group(m_config, QString::fromLatin1(s_configGroup));
    if (group.isEntryImmutable("Active")
        || (!m_configured && group.isEntryImmutable("Mode"))) {
        return false;
    }
    if (m_configured) {
        group.writeEntry("Active", false, KConfig::Notify);
    } else {
        group.writeEntry("Mode", s_constantMode, KConfig::Notify);
        group.writeEntry("Active", true, KConfig::Notify);
    }
    group.sync();

    m_configured = !m_configured;
    Q_EMIT stateChanged();
    requestKWinReconfigure();
    return true;
}

bool ControlCenterNightLightAdapter::toggleSuspended()
{
    if (!m_available || !m_configured || m_busy) {
        return false;
    }

    if (m_inhibitionCookie != 0) {
        releaseInhibition();
        return true;
    }

    if (m_inhibited) {
        return false;
    }

    requestInhibition();
    return true;
}

bool ControlCenterNightLightAdapter::previewStrength(int strength)
{
    if (!m_available || !m_configured || m_inhibited) {
        return false;
    }

    QDBusMessage message = nightLightCall(QStringLiteral("preview"));
    message << static_cast<quint32>(temperatureForStrength(strength));
    return QDBusConnection::sessionBus().send(message);
}

bool ControlCenterNightLightAdapter::setStrength(int strength)
{
    if (!m_available || !m_configured || m_busy) {
        return false;
    }

    const int temperature = temperatureForStrength(strength);
    KConfigGroup group(m_config, QString::fromLatin1(s_configGroup));
    if (group.isEntryImmutable("NightTemperature")) {
        return false;
    }
    group.writeEntry("NightTemperature", temperature, KConfig::Notify);
    group.sync();

    const int updatedStrength = strengthForTemperature(temperature);
    if (m_strength != updatedStrength) {
        m_strength = updatedStrength;
        Q_EMIT stateChanged();
    }
    requestKWinReconfigure();
    return true;
}

void ControlCenterNightLightAdapter::stopPreview()
{
    if (!m_available) {
        return;
    }
    QDBusConnection::sessionBus().send(nightLightCall(QStringLiteral("stopPreview")));
}

void ControlCenterNightLightAdapter::refresh()
{
    readConfiguration();
    const QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected() || !bus.interface()
        || !bus.interface()->isServiceRegistered(QString::fromLatin1(s_service))) {
        resetState();
        return;
    }

    const quint64 generation = ++m_refreshGeneration;
    QDBusMessage message = QDBusMessage::createMethodCall(QString::fromLatin1(s_service),
                                                          QString::fromLatin1(s_path),
                                                          QString::fromLatin1(s_propertiesInterface),
                                                          QStringLiteral("GetAll"));
    message << QString::fromLatin1(s_interface);
    auto *watcher = new QDBusPendingCallWatcher(bus.asyncCall(message), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, generation](QDBusPendingCallWatcher *finishedWatcher) {
        const QDBusPendingReply<QVariantMap> reply = *finishedWatcher;
        finishedWatcher->deleteLater();
        if (generation != m_refreshGeneration) {
            return;
        }
        if (reply.isError()) {
            resetState();
            return;
        }
        updateState(reply.value());
    });
}

void ControlCenterNightLightAdapter::handlePropertiesChanged(const QString &interfaceName,
                                                              const QVariantMap &changedProperties,
                                                              const QStringList &invalidatedProperties)
{
    if (interfaceName != QLatin1String(s_interface)) {
        return;
    }

    readConfiguration();

    if (!invalidatedProperties.isEmpty()) {
        refresh();
        return;
    }

    QVariantMap properties;
    properties.insert(QStringLiteral("available"), m_available);
    properties.insert(QStringLiteral("enabled"), m_configured);
    properties.insert(QStringLiteral("running"), m_running);
    properties.insert(QStringLiteral("inhibited"), m_inhibited);
    for (auto it = changedProperties.cbegin(); it != changedProperties.cend(); ++it) {
        properties.insert(it.key(), it.value());
    }
    updateState(properties);
}

void ControlCenterNightLightAdapter::requestInhibition()
{
    setBusy(true);
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(nightLightCall(QStringLiteral("inhibit"))), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *finishedWatcher) {
        const QDBusPendingReply<quint32> reply = *finishedWatcher;
        finishedWatcher->deleteLater();
        if (!reply.isError()) {
            m_inhibitionCookie = reply.value();
        }
        setBusy(false);
        refresh();
    });
}

void ControlCenterNightLightAdapter::releaseInhibition()
{
    const quint32 cookie = m_inhibitionCookie;
    setBusy(true);
    QDBusMessage message = nightLightCall(QStringLiteral("uninhibit"));
    message << cookie;
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(message), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, cookie](QDBusPendingCallWatcher *finishedWatcher) {
        const QDBusPendingReply<> reply = *finishedWatcher;
        finishedWatcher->deleteLater();
        if (!reply.isError() && m_inhibitionCookie == cookie) {
            m_inhibitionCookie = 0;
        }
        setBusy(false);
        refresh();
    });
}

void ControlCenterNightLightAdapter::readConfiguration()
{
    m_config->reparseConfiguration();
    const KConfigGroup group(m_config, QString::fromLatin1(s_configGroup));
    const int updatedStrength = strengthForTemperature(
        group.readEntry("NightTemperature", s_defaultTemperature));
    if (m_strength == updatedStrength) {
        return;
    }
    m_strength = updatedStrength;
    Q_EMIT stateChanged();
}

void ControlCenterNightLightAdapter::requestKWinReconfigure()
{
    setBusy(true);
    const QDBusMessage message = QDBusMessage::createMethodCall(
        QString::fromLatin1(s_kwinService),
        QString::fromLatin1(s_kwinPath),
        QString::fromLatin1(s_kwinInterface),
        QStringLiteral("reconfigure"));
    auto *watcher = new QDBusPendingCallWatcher(
        QDBusConnection::sessionBus().asyncCall(message), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this](QDBusPendingCallWatcher *finishedWatcher) {
        finishedWatcher->deleteLater();
        setBusy(false);
        refresh();
    });
}

void ControlCenterNightLightAdapter::resetState()
{
    ++m_refreshGeneration;
    if (!m_available && !m_configured && !m_running && !m_inhibited && !m_busy) {
        return;
    }
    m_available = false;
    m_configured = false;
    m_running = false;
    m_inhibited = false;
    m_busy = false;
    Q_EMIT stateChanged();
}

void ControlCenterNightLightAdapter::updateState(const QVariantMap &properties)
{
    const bool available = properties.value(QStringLiteral("available")).toBool();
    const bool configured = properties.value(QStringLiteral("enabled")).toBool();
    const bool running = properties.value(QStringLiteral("running")).toBool();
    const bool inhibited = properties.value(QStringLiteral("inhibited")).toBool();
    if (m_available == available && m_configured == configured && m_running == running && m_inhibited == inhibited) {
        return;
    }
    m_available = available;
    m_configured = configured;
    m_running = running;
    m_inhibited = inhibited;
    Q_EMIT stateChanged();
}

void ControlCenterNightLightAdapter::setBusy(bool busy)
{
    if (m_busy == busy) {
        return;
    }
    m_busy = busy;
    Q_EMIT stateChanged();
}
