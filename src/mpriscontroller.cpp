// SPDX-License-Identifier: GPL-3.0-or-later

#include "mpriscontroller.h"

#include "mediaartworkresolver.h"
#include "mprisplayerselection.h"

#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusVariant>
#include <QTimer>
#include <QUrl>

#include <algorithm>

namespace
{
constexpr auto mprisPrefix = "org.mpris.MediaPlayer2.";
constexpr auto mprisPath = "/org/mpris/MediaPlayer2";
constexpr auto rootInterface = "org.mpris.MediaPlayer2";
constexpr auto playerInterface = "org.mpris.MediaPlayer2.Player";
constexpr auto propertiesInterface = "org.freedesktop.DBus.Properties";
constexpr double mutedVolumeThreshold = 0.001;
constexpr double defaultRestoredVolume = 0.5;
constexpr qsizetype maximumMetadataTextLength = 512;
constexpr qsizetype maximumMetadataUrlLength = 4096;
constexpr qlonglong maximumMediaDurationUs = 7LL * 24 * 60 * 60 * 1000000;
constexpr int minimumPendingPlayTimeoutMs = 1000;
constexpr int maximumPendingPlayTimeoutMs = 30000;

QString boundedText(const QVariant &value, qsizetype maximumLength = maximumMetadataTextLength)
{
    return value.toString().trimmed().left(maximumLength);
}

QVariantMap mapValue(const QVariant &value)
{
    if (value.metaType() == QMetaType::fromType<QDBusArgument>()) {
        return qdbus_cast<QVariantMap>(value.value<QDBusArgument>());
    }
    return value.toMap();
}

QString artistValue(const QVariant &value)
{
    const QStringList artists = value.toStringList();
    if (!artists.isEmpty()) {
        return artists.join(QStringLiteral(", ")).trimmed().left(maximumMetadataTextLength);
    }

    const QVariantList artistVariants = value.toList();
    QStringList converted;
    converted.reserve(artistVariants.size());
    for (const QVariant &artist : artistVariants) {
        const QString text = artist.toString().trimmed();
        if (!text.isEmpty()) {
            converted.append(text);
        }
    }
    return converted.join(QStringLiteral(", ")).left(maximumMetadataTextLength);
}
}

MprisController::MprisController(QObject *parent)
    : QObject(parent)
    , m_refreshTimer(new QTimer(this))
    , m_pendingPlayTimer(new QTimer(this))
{
    m_refreshTimer->setSingleShot(true);
    m_refreshTimer->setInterval(80);
    connect(m_refreshTimer, &QTimer::timeout, this, &MprisController::refresh);
    m_pendingPlayTimer->setSingleShot(true);
    connect(m_pendingPlayTimer, &QTimer::timeout, this, [this]() {
        m_playWhenAvailablePending = false;
    });

    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.connect(QStringLiteral("org.freedesktop.DBus"),
                QStringLiteral("/org/freedesktop/DBus"),
                QStringLiteral("org.freedesktop.DBus"),
                QStringLiteral("NameOwnerChanged"),
                this,
                SLOT(onServiceOwnerChanged(QString,QString,QString)));
    bus.connect(QString(),
                QString::fromLatin1(mprisPath),
                QString::fromLatin1(propertiesInterface),
                QStringLiteral("PropertiesChanged"),
                this,
                SLOT(onPropertiesChanged(QString,QVariantMap,QStringList)));
}

QString MprisController::applicationId() const
{
    return m_applicationId;
}

void MprisController::setApplicationId(const QString &applicationId)
{
    const QString normalized = applicationId.trimmed();
    if (m_applicationId == normalized) {
        refresh();
        return;
    }
    cancelPlayWhenAvailable();
    m_applicationId = normalized;
    Q_EMIT applicationIdChanged();
    if (!selectionAvailable()) {
        clearState();
    } else {
        if (m_selectionMode == QLatin1String("application")) {
            clearState();
        }
        refresh();
    }
}

QString MprisController::selectionMode() const
{
    return m_selectionMode;
}

void MprisController::setSelectionMode(const QString &selectionMode)
{
    const QString normalized = selectionMode == QLatin1String("activePlayer")
        ? QStringLiteral("activePlayer")
        : QStringLiteral("application");
    if (m_selectionMode == normalized) {
        if (selectionAvailable()) {
            refresh();
        }
        return;
    }

    cancelPlayWhenAvailable();
    m_selectionMode = normalized;
    Q_EMIT selectionModeChanged();
    clearState();
    if (selectionAvailable()) {
        refresh();
    }
}

bool MprisController::available() const { return m_available; }
QString MprisController::identity() const { return m_identity; }
QString MprisController::track() const { return m_track; }
QString MprisController::artist() const { return m_artist; }
QString MprisController::artUrl() const { return m_artUrl; }
bool MprisController::canGoPrevious() const { return m_canGoPrevious; }
bool MprisController::canPlay() const { return m_canPlay; }
bool MprisController::canPause() const { return m_canPause; }
bool MprisController::canGoNext() const { return m_canGoNext; }
bool MprisController::canControl() const { return m_canControl; }
bool MprisController::canSeek() const { return m_canSeek; }
bool MprisController::playing() const { return m_playing; }
qlonglong MprisController::positionUs() const { return m_positionUs; }
qlonglong MprisController::lengthUs() const { return m_lengthUs; }
bool MprisController::shuffleAvailable() const { return m_shuffleAvailable; }
bool MprisController::shuffle() const { return m_shuffle; }
QString MprisController::loopStatus() const { return m_loopStatus; }
bool MprisController::volumeAvailable() const { return m_volumeAvailable; }
double MprisController::volume() const { return m_volume; }

void MprisController::refresh()
{
    m_refreshTimer->stop();
    const quint64 generation = ++m_refreshGeneration;
    m_candidates.clear();
    m_pendingPropertyRequests = 0;

    if (!selectionAvailable()) {
        clearState();
        return;
    }

    QDBusInterface dbus(QStringLiteral("org.freedesktop.DBus"),
                        QStringLiteral("/org/freedesktop/DBus"),
                        QStringLiteral("org.freedesktop.DBus"),
                        QDBusConnection::sessionBus());
    auto *watcher = new QDBusPendingCallWatcher(dbus.asyncCall(QStringLiteral("ListNames")), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher, generation]() {
        const QDBusPendingReply<QStringList> reply = *watcher;
        watcher->deleteLater();
        if (generation != m_refreshGeneration || reply.isError()) {
            if (generation == m_refreshGeneration) {
                clearState();
            }
            return;
        }

        QStringList services;
        for (const QString &service : reply.value()) {
            if (service.startsWith(QLatin1String(mprisPrefix))) {
                services.append(service);
            }
        }
        if (services.isEmpty()) {
            clearState();
            return;
        }

        m_pendingPropertyRequests = services.size() * 2;
        for (const QString &service : std::as_const(services)) {
            m_candidates.insert(service, QVariantMap{{QStringLiteral("service"), service}});
            requestPlayerProperties(service, generation);
        }
    });
}

void MprisController::requestPlayerProperties(const QString &service, quint64 generation)
{
    for (const QString &interfaceName : {QString::fromLatin1(rootInterface), QString::fromLatin1(playerInterface)}) {
        QDBusInterface properties(service,
                                  QString::fromLatin1(mprisPath),
                                  QString::fromLatin1(propertiesInterface),
                                  QDBusConnection::sessionBus());
        auto *watcher = new QDBusPendingCallWatcher(properties.asyncCall(QStringLiteral("GetAll"), interfaceName), this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher, service, interfaceName, generation]() {
            const QDBusPendingReply<QVariantMap> reply = *watcher;
            watcher->deleteLater();
            completePropertyRequest(service,
                                    interfaceName == QLatin1String(rootInterface) ? QStringLiteral("root") : QStringLiteral("player"),
                                    reply.isError() ? QVariantMap{} : reply.value(),
                                    generation);
        });
    }
}

void MprisController::completePropertyRequest(const QString &service,
                                              const QString &key,
                                              const QVariantMap &properties,
                                              quint64 generation)
{
    if (generation != m_refreshGeneration || !m_candidates.contains(service)) {
        return;
    }
    QVariantMap candidate = m_candidates.value(service);
    candidate.insert(key, properties);
    m_candidates.insert(service, candidate);
    m_pendingPropertyRequests = std::max(0, m_pendingPropertyRequests - 1);
    if (m_pendingPropertyRequests == 0) {
        selectBestCandidate();
    }
}

void MprisController::selectBestCandidate()
{
    QList<MprisPlayerSelection::Candidate> selectableCandidates;
    for (auto it = m_candidates.cbegin(); it != m_candidates.cend(); ++it) {
        const QVariantMap candidate = it.value();
        const QVariantMap root = candidate.value(QStringLiteral("root")).toMap();
        const QVariantMap player = candidate.value(QStringLiteral("player")).toMap();
        if (player.isEmpty()) {
            continue;
        }
        selectableCandidates.append({
            candidate.value(QStringLiteral("service")).toString(),
            boundedText(root.value(QStringLiteral("DesktopEntry"))),
            boundedText(root.value(QStringLiteral("Identity"))),
            boundedText(player.value(QStringLiteral("PlaybackStatus")), 32),
            player.value(QStringLiteral("CanControl")).toBool(),
        });
    }

    const auto mode = m_selectionMode == QLatin1String("activePlayer")
        ? MprisPlayerSelection::Mode::ActivePlayer
        : MprisPlayerSelection::Mode::Application;
    const QString selectedService = MprisPlayerSelection::selectService(
        selectableCandidates, mode, m_applicationId, m_service);
    const QVariantMap best = m_candidates.value(selectedService);
    if (selectedService.isEmpty() || best.isEmpty()) {
        clearState();
        return;
    }

    const QVariantMap root = best.value(QStringLiteral("root")).toMap();
    const QVariantMap player = best.value(QStringLiteral("player")).toMap();
    const QVariantMap metadata = mapValue(player.value(QStringLiteral("Metadata")));
    const QString service = best.value(QStringLiteral("service")).toString();
    const QString track = boundedText(metadata.value(QStringLiteral("xesam:title")));
    const QString artist = artistValue(metadata.value(QStringLiteral("xesam:artist")));
    const QString mediaUrl = boundedText(
        metadata.value(QStringLiteral("xesam:url")), maximumMetadataUrlLength);
    const QString mediaIdentity =
        MediaArtworkResolver::mediaIdentityKey(service, track, artist, mediaUrl);
    const QString artworkUrl = MediaArtworkResolver::stabilizedArtworkUrl(
        boundedText(metadata.value(QStringLiteral("mpris:artUrl")), maximumMetadataUrlLength),
        mediaUrl,
        mediaIdentity,
        m_mediaIdentity,
        m_artUrl);

    m_service = service;
    m_identity = boundedText(root.value(QStringLiteral("Identity")));
    m_track = track;
    m_artist = artist;
    m_artUrl = artworkUrl;
    m_mediaIdentity = mediaIdentity;
    m_canGoPrevious = player.value(QStringLiteral("CanGoPrevious")).toBool();
    m_canPlay = player.value(QStringLiteral("CanPlay")).toBool();
    m_canPause = player.value(QStringLiteral("CanPause")).toBool();
    m_canGoNext = player.value(QStringLiteral("CanGoNext")).toBool();
    m_canControl = player.value(QStringLiteral("CanControl")).toBool();
    m_canSeek = player.value(QStringLiteral("CanSeek")).toBool();
    m_playing = player.value(QStringLiteral("PlaybackStatus")).toString() == QLatin1String("Playing");
    m_lengthUs = std::clamp<qlonglong>(
        metadata.value(QStringLiteral("mpris:length")).toLongLong(),
        0,
        maximumMediaDurationUs);
    m_positionUs = std::clamp<qlonglong>(
        player.value(QStringLiteral("Position")).toLongLong(),
        0,
        m_lengthUs > 0 ? m_lengthUs : maximumMediaDurationUs);
    m_shuffleAvailable = player.contains(QStringLiteral("Shuffle"));
    m_shuffle = player.value(QStringLiteral("Shuffle")).toBool();
    const QString loopStatus = player.value(QStringLiteral("LoopStatus")).toString();
    m_loopStatus = loopStatus == QLatin1String("Playlist")
            || loopStatus == QLatin1String("Track")
            || loopStatus == QLatin1String("None")
        ? loopStatus
        : QString();
    m_volumeAvailable = player.contains(QStringLiteral("Volume"))
        && m_canControl;
    m_volume = std::clamp(player.value(QStringLiteral("Volume")).toDouble(), 0.0, 1.0);
    if (m_volume > mutedVolumeThreshold) {
        m_lastAudibleVolume = m_volume;
    }
    m_available = true;
    Q_EMIT stateChanged();
    completePendingPlayRequest();
}

void MprisController::clearState()
{
    const bool changed = m_available || !m_service.isEmpty() || !m_track.isEmpty() || !m_artist.isEmpty();
    m_service.clear();
    m_identity.clear();
    m_track.clear();
    m_artist.clear();
    m_artUrl.clear();
    m_mediaIdentity.clear();
    m_available = false;
    m_canGoPrevious = false;
    m_canPlay = false;
    m_canPause = false;
    m_canGoNext = false;
    m_canControl = false;
    m_canSeek = false;
    m_playing = false;
    m_positionUs = 0;
    m_lengthUs = 0;
    m_shuffleAvailable = false;
    m_shuffle = false;
    m_loopStatus.clear();
    m_volumeAvailable = false;
    m_volume = 0.0;
    m_lastAudibleVolume = defaultRestoredVolume;
    if (changed) {
        Q_EMIT stateChanged();
    }
}

void MprisController::previous()
{
    if (m_canGoPrevious) {
        callPlayerMethod(QStringLiteral("Previous"));
    }
}

void MprisController::togglePlaying()
{
    if (m_playing && m_canPause) {
        callPlayerMethod(QStringLiteral("Pause"));
    } else if (!m_playing && m_canPlay) {
        callPlayerMethod(QStringLiteral("Play"));
    }
}

void MprisController::requestPlayWhenAvailable(int timeoutMs)
{
    cancelPlayWhenAvailable();
    if (!selectionAvailable() || (m_available && m_playing)) {
        return;
    }

    m_playWhenAvailablePending = true;
    m_pendingPlayTimer->start(std::clamp(timeoutMs,
                                         minimumPendingPlayTimeoutMs,
                                         maximumPendingPlayTimeoutMs));
    completePendingPlayRequest();
    if (m_playWhenAvailablePending) {
        refresh();
    }
}

void MprisController::cancelPlayWhenAvailable()
{
    m_playWhenAvailablePending = false;
    m_pendingPlayTimer->stop();
}

void MprisController::next()
{
    if (m_canGoNext) {
        callPlayerMethod(QStringLiteral("Next"));
    }
}

void MprisController::setShuffle(bool enabled)
{
    if (!m_available || !m_canControl || !m_shuffleAvailable || m_service.isEmpty()) {
        return;
    }

    if (m_shuffle == enabled) {
        return;
    }

    m_shuffle = enabled;
    Q_EMIT stateChanged();

    QDBusInterface properties(m_service,
                              QString::fromLatin1(mprisPath),
                              QString::fromLatin1(propertiesInterface),
                              QDBusConnection::sessionBus());
    properties.asyncCall(QStringLiteral("Set"),
                         QString::fromLatin1(playerInterface),
                         QStringLiteral("Shuffle"),
                         QVariant::fromValue(QDBusVariant(QVariant(enabled))));
    QTimer::singleShot(120, this, &MprisController::scheduleRefresh);
}

void MprisController::cycleLoopStatus()
{
    if (!m_available || !m_canControl || m_loopStatus.isEmpty() || m_service.isEmpty()) {
        return;
    }

    QString nextStatus = QStringLiteral("Playlist");
    if (m_loopStatus == QLatin1String("Playlist")) {
        nextStatus = QStringLiteral("Track");
    } else if (m_loopStatus == QLatin1String("Track")) {
        nextStatus = QStringLiteral("None");
    }

    if (m_loopStatus == nextStatus) {
        return;
    }

    m_loopStatus = nextStatus;
    Q_EMIT stateChanged();

    QDBusInterface properties(m_service,
                              QString::fromLatin1(mprisPath),
                              QString::fromLatin1(propertiesInterface),
                              QDBusConnection::sessionBus());
    properties.asyncCall(QStringLiteral("Set"),
                         QString::fromLatin1(playerInterface),
                         QStringLiteral("LoopStatus"),
                         QVariant::fromValue(QDBusVariant(QVariant(nextStatus))));
    QTimer::singleShot(120, this, &MprisController::scheduleRefresh);
}

void MprisController::setVolume(double volume)
{
    if (!m_available || !m_volumeAvailable || m_service.isEmpty()) {
        return;
    }

    const double safeVolume = std::clamp(volume, 0.0, 1.0);
    if (qFuzzyCompare(m_volume, safeVolume)) {
        return;
    }

    if (safeVolume > mutedVolumeThreshold) {
        m_lastAudibleVolume = safeVolume;
    }
    m_volume = safeVolume;
    Q_EMIT stateChanged();

    QDBusInterface properties(m_service,
                              QString::fromLatin1(mprisPath),
                              QString::fromLatin1(propertiesInterface),
                              QDBusConnection::sessionBus());
    properties.asyncCall(QStringLiteral("Set"),
                         QString::fromLatin1(playerInterface),
                         QStringLiteral("Volume"),
                         QVariant::fromValue(QDBusVariant(safeVolume)));
    QTimer::singleShot(120, this, &MprisController::scheduleRefresh);
}

void MprisController::toggleMute()
{
    if (!m_available || !m_volumeAvailable || m_service.isEmpty()) {
        return;
    }

    if (m_volume > mutedVolumeThreshold) {
        m_lastAudibleVolume = m_volume;
        setVolume(0.0);
        return;
    }

    setVolume(std::max(mutedVolumeThreshold, m_lastAudibleVolume));
}

void MprisController::callPlayerMethod(const QString &method)
{
    if (!m_available || m_service.isEmpty()) {
        return;
    }
    QDBusInterface player(m_service,
                          QString::fromLatin1(mprisPath),
                          QString::fromLatin1(playerInterface),
                          QDBusConnection::sessionBus());
    player.asyncCall(method);
    QTimer::singleShot(120, this, &MprisController::scheduleRefresh);
}

void MprisController::completePendingPlayRequest()
{
    if (!m_playWhenAvailablePending || !m_available) {
        return;
    }
    if (m_playing) {
        cancelPlayWhenAvailable();
        return;
    }
    if (!m_canPlay) {
        return;
    }

    cancelPlayWhenAvailable();
    callPlayerMethod(QStringLiteral("Play"));
}

void MprisController::scheduleRefresh()
{
    if (selectionAvailable()) {
        m_refreshTimer->start();
    }
}

bool MprisController::selectionAvailable() const
{
    return m_selectionMode == QLatin1String("activePlayer") || !m_applicationId.isEmpty();
}

void MprisController::onServiceOwnerChanged(const QString &name, const QString &, const QString &)
{
    if (name.startsWith(QLatin1String(mprisPrefix))) {
        scheduleRefresh();
    }
}

void MprisController::onPropertiesChanged(const QString &interfaceName, const QVariantMap &, const QStringList &)
{
    if (interfaceName == QLatin1String(rootInterface) || interfaceName == QLatin1String(playerInterface)) {
        scheduleRefresh();
    }
}
