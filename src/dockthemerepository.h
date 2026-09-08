// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QPointer>

class KJob;
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlregistration.h>

class DockThemeRepository : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool removalBusy READ removalBusy NOTIFY removalBusyChanged)
    Q_PROPERTY(QString themeId READ themeId WRITE setThemeId NOTIFY themeIdChanged)
    Q_PROPERTY(QVariantMap theme READ theme NOTIFY themeChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY themeChanged)
    Q_PROPERTY(QString themeName READ themeName NOTIFY themeChanged)
    Q_PROPERTY(QString errorCode READ errorCode NOTIFY errorCodeChanged)
    Q_PROPERTY(QVariantList availableThemes READ availableThemes NOTIFY themesChanged)
    Q_PROPERTY(bool customThemeDirectoryEnabled READ customThemeDirectoryEnabled WRITE setCustomThemeDirectoryEnabled NOTIFY customThemeDirectoryEnabledChanged)
    Q_PROPERTY(QString customThemeDirectory READ customThemeDirectory WRITE setCustomThemeDirectory NOTIFY customThemeDirectoryChanged)
    Q_PROPERTY(QString customThemeDirectoryDisplayName READ customThemeDirectoryDisplayName NOTIFY customThemeDirectoryChanged)

public:
    explicit DockThemeRepository(QObject *parent = nullptr);
    ~DockThemeRepository() override;
    bool removalBusy() const;

    QString themeId() const;
    void setThemeId(const QString &themeId);
    QVariantMap theme() const;
    bool valid() const;
    QString themeName() const;
    QString errorCode() const;
    QVariantList availableThemes() const;

    bool customThemeDirectoryEnabled() const;
    void setCustomThemeDirectoryEnabled(bool enabled);
    QString customThemeDirectory() const;
    void setCustomThemeDirectory(const QString &directory);
    QString customThemeDirectoryDisplayName() const;

    Q_INVOKABLE QString importTheme(const QUrl &sourceUrl);
    Q_INVOKABLE QVariantMap importThemeDirectory(const QUrl &sourceDirectoryUrl);
    Q_INVOKABLE QVariantMap prepareRemoval(const QString &themeId = QString());
    Q_INVOKABLE bool confirmRemoval();
    Q_INVOKABLE void cancelRemoval();
    Q_INVOKABLE void refreshThemes();
    Q_INVOKABLE void clearError();

Q_SIGNALS:
    void removalBusyChanged();
    void removalFinished(int movedCount, int failedCount);
    void themeIdChanged();
    void themeChanged();
    void errorCodeChanged();
    void themesChanged();
    void customThemeDirectoryEnabledChanged();
    void customThemeDirectoryChanged();

protected:
    // Allows deterministic failure tests without touching the user's Trash.
    virtual KJob *createTrashJob(const QUrl &url);

private:
    QVariantList removalInventory() const;
    void trashNextTheme();
    void finishRemoval();
    void refreshPeerRepositories();
    QString storeTheme(const QVariantMap &theme, bool *created = nullptr);
    QString managedThemeFilePath(const QString &themeId) const;
    QString managedThemeDirectoryPath(const QVariantMap &theme) const;
    bool loadTheme(const QString &themeId);
    void clearTheme();
    void setErrorCode(const QString &errorCode);
    QString themesDirectoryPath() const;

    bool m_removalBusy = false;
    QVariantList m_pendingInventory;
    QVariantList m_pendingRemoval;
    QString m_removalRoot;
    int m_removalIndex = 0;
    int m_movedCount = 0;
    int m_failedCount = 0;
    QPointer<KJob> m_trashJob;

    QString m_themeId;
    QVariantMap m_theme;
    QString m_errorCode;
    QVariantList m_availableThemes;
    bool m_customThemeDirectoryEnabled = false;
    QString m_customThemeDirectory;
};
