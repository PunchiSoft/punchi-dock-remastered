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

public:
    explicit SystemDiscovery(QObject *parent = nullptr);

    QString distributionName() const;
    QString distributionLogo() const;

    Q_INVOKABLE void requestFolderEntries(const QString &path);
    Q_INVOKABLE void requestApplications(const QString &category = {});
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
    Q_INVOKABLE void launchApplication(const QString &storageId);
    Q_INVOKABLE QVariantMap createDesktopShortcut(const QString &storageId, const QString &command = QString());
    Q_INVOKABLE bool launchApplicationWithUrls(const QString &applicationId, const QString &command,
        const QString &launcherUrl, const QVariantList &urls);
    Q_INVOKABLE bool launchApplicationAction(const QString &applicationId, const QString &actionId);
    Q_INVOKABLE bool launchApplicationByCommand(const QString &command);
    Q_INVOKABLE void openUrl(const QString &url);

Q_SIGNALS:
    void folderEntriesReady(const QVariantList &entries);
    void applicationsReady(const QVariantList &applications);
    void applicationCatalogReady(const QVariantList &applications);
    void applicationReady(const QVariantMap &application);
    void applicationLaunchFinished(bool succeeded, const QString &message);
    void operationFailed(const QString &operation, const QString &message);
};
