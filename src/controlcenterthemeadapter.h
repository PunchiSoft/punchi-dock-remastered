// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KConfigWatcher>
#include <KSharedConfig>

#include <QObject>
#include <qqmlregistration.h>

class QProcess;

class ControlCenterThemeAdapter : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool available READ available NOTIFY stateChanged)
    Q_PROPERTY(bool darkMode READ darkMode NOTIFY stateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY stateChanged)
    Q_PROPERTY(QString lightThemeId READ lightThemeId NOTIFY stateChanged)
    Q_PROPERTY(QString darkThemeId READ darkThemeId NOTIFY stateChanged)

public:
    explicit ControlCenterThemeAdapter(QObject *parent = nullptr);

    bool available() const;
    bool darkMode() const;
    bool busy() const;
    QString lightThemeId() const;
    QString darkThemeId() const;

    Q_INVOKABLE bool toggleMode();

Q_SIGNALS:
    void stateChanged();

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    void refresh();
    bool packageAvailable(const QString &packageId) const;

    KSharedConfig::Ptr m_config;
    KConfigWatcher::Ptr m_configWatcher;
    QProcess *m_process = nullptr;
    QString m_executablePath;
    QString m_lightThemeId;
    QString m_darkThemeId;
    bool m_available = false;
    bool m_darkMode = false;
    bool m_busy = false;
};
