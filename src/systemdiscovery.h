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

public:
    explicit SystemDiscovery(QObject *parent = nullptr);

    Q_INVOKABLE void requestFolderEntries(const QString &path);
    Q_INVOKABLE void requestApplications(const QString &category = {});
    Q_INVOKABLE void requestApplication(const QString &query);
    Q_INVOKABLE QString iconForApplication(const QString &applicationId) const;
    Q_INVOKABLE QString iconForCategory(const QString &category) const;
    Q_INVOKABLE QString applicationIdForCommand(const QString &command) const;
    Q_INVOKABLE void launchApplication(const QString &storageId);
    Q_INVOKABLE bool launchApplicationByCommand(const QString &command);
    Q_INVOKABLE void openUrl(const QString &url);

Q_SIGNALS:
    void folderEntriesReady(const QVariantList &entries);
    void applicationsReady(const QVariantList &applications);
    void applicationReady(const QVariantMap &application);
    void operationFailed(const QString &operation, const QString &message);
};
