// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlregistration.h>

class DockThemeRepository : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString themeId READ themeId WRITE setThemeId NOTIFY themeIdChanged)
    Q_PROPERTY(QVariantMap theme READ theme NOTIFY themeChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY themeChanged)
    Q_PROPERTY(QString themeName READ themeName NOTIFY themeChanged)
    Q_PROPERTY(QString errorCode READ errorCode NOTIFY errorCodeChanged)
    Q_PROPERTY(QVariantList availableThemes READ availableThemes NOTIFY themesChanged)

public:
    explicit DockThemeRepository(QObject *parent = nullptr);

    QString themeId() const;
    void setThemeId(const QString &themeId);
    QVariantMap theme() const;
    bool valid() const;
    QString themeName() const;
    QString errorCode() const;
    QVariantList availableThemes() const;

    Q_INVOKABLE QString importTheme(const QUrl &sourceUrl);
    Q_INVOKABLE QVariantMap importThemeDirectory(const QUrl &sourceDirectoryUrl);
    Q_INVOKABLE bool removeTheme(const QString &themeId);
    Q_INVOKABLE void refreshThemes();
    Q_INVOKABLE void clearError();

Q_SIGNALS:
    void themeIdChanged();
    void themeChanged();
    void errorCodeChanged();
    void themesChanged();

private:
    QString storeTheme(const QVariantMap &theme, bool *created = nullptr);
    QString managedThemeFilePath(const QString &themeId) const;
    QString managedThemeDirectoryPath(const QVariantMap &theme) const;
    void removeEmptyThemeDirectories(const QString &filePath);
    bool loadTheme(const QString &themeId);
    void clearTheme();
    void setErrorCode(const QString &errorCode);
    QString themesDirectoryPath() const;

    QString m_themeId;
    QVariantMap m_theme;
    QString m_errorCode;
    QVariantList m_availableThemes;
};
