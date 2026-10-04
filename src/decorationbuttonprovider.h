// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <KConfigWatcher>
#include <KSharedConfig>

#include <QFileSystemWatcher>
#include <QObject>
#include <QSizeF>
#include <QVariantMap>
#include <qqmlregistration.h>

// Read-only adapter for the selected Aurorae SVG decoration, not the Plasma style.
class DecorationButtonProvider : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString closeButtonPath READ closeButtonPath NOTIFY appearanceChanged)
    Q_PROPERTY(QVariantMap buttonPaths READ buttonPaths NOTIFY appearanceChanged)
    Q_PROPERTY(QSizeF buttonSize READ buttonSize NOTIFY appearanceChanged)
    Q_PROPERTY(QString themeName READ themeName NOTIFY appearanceChanged)

public:
    explicit DecorationButtonProvider(QObject *parent = nullptr);

    QString closeButtonPath() const { return m_buttonPaths.value(QStringLiteral("close")).toString(); }
    QVariantMap buttonPaths() const { return m_buttonPaths; }
    QSizeF buttonSize() const { return m_buttonSize; }
    QString themeName() const { return m_themeName; }

    Q_INVOKABLE void refresh();

Q_SIGNALS:
    void appearanceChanged();

private:
    // Roles are resolved from a closed list: QML may ask for a known role, never
    // for an arbitrary file name inside the theme directory.
    static const QHash<QString, QString> &roleFiles();

    KSharedConfig::Ptr m_config;
    KConfigWatcher::Ptr m_configWatcher;
    QFileSystemWatcher m_files;
    QVariantMap m_buttonPaths;
    QString m_themeName;
    QSizeF m_buttonSize = QSizeF(16, 16);
};
