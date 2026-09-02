// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KConfigWatcher>
#include <KSharedConfig>

#include <QObject>
#include <qqmlregistration.h>

class ControlCenterVolumeOsdAdapter : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool osdVisible READ osdVisible NOTIFY stateChanged)
    Q_PROPERTY(bool writable READ writable NOTIFY stateChanged)

public:
    explicit ControlCenterVolumeOsdAdapter(QObject *parent = nullptr);
    explicit ControlCenterVolumeOsdAdapter(const KSharedConfig::Ptr &config, QObject *parent = nullptr);

    bool osdVisible() const;
    bool writable() const;

    Q_INVOKABLE bool toggleOsd();
    Q_INVOKABLE void refresh();

Q_SIGNALS:
    void stateChanged();

private:
    void updateState(bool osdVisible, bool writable);

    KSharedConfig::Ptr m_config;
    KConfigWatcher::Ptr m_configWatcher;
    bool m_osdVisible = true;
    bool m_writable = false;
};
