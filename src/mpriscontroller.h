// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QHash>
#include <QObject>
#include <QString>
#include <QVariantMap>
#include <qqmlregistration.h>

class QTimer;

class MprisController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString applicationId READ applicationId WRITE setApplicationId NOTIFY applicationIdChanged)
    Q_PROPERTY(bool available READ available NOTIFY stateChanged)
    Q_PROPERTY(QString identity READ identity NOTIFY stateChanged)
    Q_PROPERTY(QString track READ track NOTIFY stateChanged)
    Q_PROPERTY(QString artist READ artist NOTIFY stateChanged)
    Q_PROPERTY(QString artUrl READ artUrl NOTIFY stateChanged)
    Q_PROPERTY(bool canGoPrevious READ canGoPrevious NOTIFY stateChanged)
    Q_PROPERTY(bool canPlay READ canPlay NOTIFY stateChanged)
    Q_PROPERTY(bool canPause READ canPause NOTIFY stateChanged)
    Q_PROPERTY(bool canGoNext READ canGoNext NOTIFY stateChanged)
    Q_PROPERTY(bool canControl READ canControl NOTIFY stateChanged)
    Q_PROPERTY(bool canSeek READ canSeek NOTIFY stateChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY stateChanged)
    Q_PROPERTY(qlonglong positionUs READ positionUs NOTIFY stateChanged)
    Q_PROPERTY(qlonglong lengthUs READ lengthUs NOTIFY stateChanged)
    Q_PROPERTY(bool shuffleAvailable READ shuffleAvailable NOTIFY stateChanged)
    Q_PROPERTY(bool shuffle READ shuffle NOTIFY stateChanged)
    Q_PROPERTY(QString loopStatus READ loopStatus NOTIFY stateChanged)
    Q_PROPERTY(bool volumeAvailable READ volumeAvailable NOTIFY stateChanged)
    Q_PROPERTY(double volume READ volume NOTIFY stateChanged)

public:
    explicit MprisController(QObject *parent = nullptr);

    QString applicationId() const;
    void setApplicationId(const QString &applicationId);
    bool available() const;
    QString identity() const;
    QString track() const;
    QString artist() const;
    QString artUrl() const;
    bool canGoPrevious() const;
    bool canPlay() const;
    bool canPause() const;
    bool canGoNext() const;
    bool canControl() const;
    bool canSeek() const;
    bool playing() const;
    qlonglong positionUs() const;
    qlonglong lengthUs() const;
    bool shuffleAvailable() const;
    bool shuffle() const;
    QString loopStatus() const;
    bool volumeAvailable() const;
    double volume() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void togglePlaying();
    Q_INVOKABLE void next();
    Q_INVOKABLE void setShuffle(bool enabled);
    Q_INVOKABLE void cycleLoopStatus();
    Q_INVOKABLE void setVolume(double volume);

Q_SIGNALS:
    void applicationIdChanged();
    void stateChanged();

private Q_SLOTS:
    void onServiceOwnerChanged(const QString &name, const QString &oldOwner, const QString &newOwner);
    void onPropertiesChanged(const QString &interfaceName, const QVariantMap &changedProperties, const QStringList &invalidatedProperties);

private:
    void requestPlayerProperties(const QString &service, quint64 generation);
    void completePropertyRequest(const QString &service, const QString &key, const QVariantMap &properties, quint64 generation);
    void selectBestCandidate();
    void clearState();
    void callPlayerMethod(const QString &method);
    void scheduleRefresh();

    QString m_applicationId;
    QString m_service;
    QString m_identity;
    QString m_track;
    QString m_artist;
    QString m_artUrl;
    QString m_mediaIdentity;
    bool m_available = false;
    bool m_canGoPrevious = false;
    bool m_canPlay = false;
    bool m_canPause = false;
    bool m_canGoNext = false;
    bool m_canControl = false;
    bool m_canSeek = false;
    bool m_playing = false;
    qlonglong m_positionUs = 0;
    qlonglong m_lengthUs = 0;
    bool m_shuffleAvailable = false;
    bool m_shuffle = false;
    QString m_loopStatus;
    bool m_volumeAvailable = false;
    double m_volume = 0.0;
    quint64 m_refreshGeneration = 0;
    int m_pendingPropertyRequests = 0;
    QHash<QString, QVariantMap> m_candidates;
    QTimer *m_refreshTimer = nullptr;
};
