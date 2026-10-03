// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlregistration.h>

namespace KIO
{
class Job;
}

class SystemDiscovery : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString distributionName READ distributionName CONSTANT)
    Q_PROPERTY(QString distributionLogo READ distributionLogo CONSTANT)
    // Name of the file manager the desktop hands folders to. It lets the fan name
    // where a container opens instead of hardcoding one application.
    Q_PROPERTY(QString folderOpenerName READ folderOpenerName CONSTANT)

public:
    explicit SystemDiscovery(QObject *parent = nullptr);

    QString distributionName() const;
    QString distributionLogo() const;
    QString folderOpenerName() const;

    Q_INVOKABLE void requestFolderEntries(const QString &path);
    Q_INVOKABLE void requestApplications(const QString &category = {});
    // Synchronous variant used while the initial dock items are built, so the
    // first install can seed a category container before the dock is exposed.
    [[nodiscard]] Q_INVOKABLE QVariantList applicationsForCategory(
        const QString &category) const;
    Q_INVOKABLE void requestApplicationCatalog();
    Q_INVOKABLE void requestApplication(const QString &query);
    Q_INVOKABLE QString iconForApplication(const QString &applicationId) const;
    Q_INVOKABLE QString iconForCategory(const QString &category) const;
    Q_INVOKABLE QString applicationIdForCommand(const QString &command) const;
    Q_INVOKABLE QVariantMap applicationForLauncher(const QString &applicationId, const QString &launcherUrl) const;
    Q_INVOKABLE QVariantMap resolveApplication(const QString &storageId, const QString &command = QString(),
        const QString &launcherUrl = QString()) const;
    Q_INVOKABLE QVariantList applicationActions(const QString &applicationId) const;
    Q_INVOKABLE QVariantMap validateDroppedUrls(const QVariantList &urls) const;
    Q_INVOKABLE QVariantMap validateApplicationLauncherDrop(const QVariantList &urls) const;
    Q_INVOKABLE void launchApplication(const QString &storageId);
    Q_INVOKABLE QVariantMap createDesktopShortcut(const QString &storageId, const QString &command = QString());
    Q_INVOKABLE bool launchApplicationWithUrls(const QString &applicationId, const QString &command,
        const QString &launcherUrl, const QVariantList &urls);
    Q_INVOKABLE bool launchApplicationAction(const QString &applicationId, const QString &actionId);
    Q_INVOKABLE bool launchApplicationByCommand(const QString &command);
    Q_INVOKABLE void openUrl(const QString &url);
    // Opens a folder with the user's file manager. Unlike openUrl, it does not
    // ask which application handles the file: a location is always opened by the
    // file manager the desktop is configured with.
    Q_INVOKABLE void openLocation(const QString &path);

Q_SIGNALS:
    void folderEntriesReady(const QVariantList &entries);
    void applicationsReady(const QVariantList &applications);
    void applicationCatalogReady(const QVariantList &applications);
    void applicationReady(const QVariantMap &application);
    void applicationLaunchFinished(bool succeeded, const QString &message);
    void applicationAccessed(const QString &storageId);
    void operationFailed(const QString &operation, const QString &message);
};
