// SPDX-License-Identifier: GPL-3.0-or-later

#include "systemdiscovery.h"

#include <KIO/ApplicationLauncherJob>
#include <KIO/ListJob>
#include <KIO/OpenUrlJob>
#include <KIO/UDSEntry>
#include <KService>

#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSet>
#include <QUrl>

namespace
{
constexpr qsizetype maximumResults = 80;

QString normalizedApplicationId(QString applicationId)
{
    applicationId = applicationId.trimmed();
    if (applicationId.endsWith(QLatin1String(".desktop"))) {
        applicationId.chop(8);
    }
    return applicationId;
}

QVariantMap serviceMap(const KService::Ptr &service)
{
    if (!service) {
        return {};
    }

    return {
        {QStringLiteral("type"), QStringLiteral("app")},
        {QStringLiteral("name"), service->name()},
        {QStringLiteral("icon"), service->icon().isEmpty() ? QStringLiteral("application-x-executable") : service->icon()},
        {QStringLiteral("command"), service->exec()},
        {QStringLiteral("description"), service->comment()},
        {QStringLiteral("storageId"), service->storageId()},
        {QStringLiteral("appId"), normalizedApplicationId(service->storageId())},
    };
}

QString unquoteToken(QString text)
{
    if (text.size() >= 2
        && ((text.startsWith(QLatin1Char('"')) && text.endsWith(QLatin1Char('"')))
            || (text.startsWith(QLatin1Char('\'')) && text.endsWith(QLatin1Char('\''))))) {
        text = text.mid(1, text.size() - 2);
    }
    return text;
}

bool looksLikeApplicationId(const QString &text)
{
    static const QRegularExpression pattern(QStringLiteral("^[A-Za-z0-9][A-Za-z0-9_.-]*\\.[A-Za-z0-9_.-]+$"));
    return pattern.match(text).hasMatch();
}

QString commandLookupKey(QString command)
{
    command = command.trimmed();
    if (command.isEmpty()) {
        return {};
    }

    const QStringList parts = command.split(QRegularExpression(QStringLiteral("\\s+")), Qt::SkipEmptyParts);
    if (parts.isEmpty()) {
        return {};
    }

    QString executable = unquoteToken(parts.constFirst());

    const int slash = executable.lastIndexOf(QLatin1Char('/'));
    executable = slash >= 0 ? executable.mid(slash + 1) : executable;

    if (executable == QLatin1String("gtk-launch") && parts.size() > 1) {
        QString launcher = unquoteToken(parts.at(1));
        launcher.remove(QStringLiteral("applications:"));
        return normalizedApplicationId(launcher);
    }

    if (executable == QLatin1String("flatpak") && parts.size() > 2 && unquoteToken(parts.at(1)) == QLatin1String("run")) {
        for (int i = 2; i < parts.size(); ++i) {
            const QString part = unquoteToken(parts.at(i));
            if (part.isEmpty() || part.startsWith(QLatin1Char('-'))) {
                continue;
            }
            if (looksLikeApplicationId(part)) {
                return normalizedApplicationId(part);
            }
        }
    }

    return normalizedApplicationId(executable);
}

QString serviceExecLookupKey(const KService::Ptr &service)
{
    if (!service) {
        return {};
    }
    return commandLookupKey(service->exec());
}

KService::Ptr findApplicationService(const QString &query)
{
    const QString needle = normalizedApplicationId(query);
    if (needle.isEmpty()) {
        return {};
    }

    KService::Ptr best = KService::serviceByStorageId(needle);
    if (!best) {
        best = KService::serviceByDesktopName(needle);
    }

    if (best) {
        return best;
    }

    const KService::List services = KService::allServices();
    KService::Ptr exactNameMatch;
    KService::Ptr exactExecMatch;
    KService::Ptr partialNameMatch;
    KService::Ptr partialStorageIdMatch;

    for (const KService::Ptr &service : services) {
        if (!service || service->noDisplay() || !service->isApplication()) {
            continue;
        }

        const QString serviceName = service->name().trimmed();
        const QString serviceStorageId = normalizedApplicationId(service->storageId());
        const QString serviceDesktopName = normalizedApplicationId(service->desktopEntryName());
        const QString serviceExecKey = serviceExecLookupKey(service);

        if (serviceStorageId.compare(needle, Qt::CaseInsensitive) == 0
            || serviceDesktopName.compare(needle, Qt::CaseInsensitive) == 0) {
            return service;
        }

        if (!exactNameMatch && serviceName.compare(needle, Qt::CaseInsensitive) == 0) {
            exactNameMatch = service;
        }

        if (!exactExecMatch && serviceExecKey.compare(needle, Qt::CaseInsensitive) == 0) {
            exactExecMatch = service;
        }

        if (!partialNameMatch && serviceName.contains(needle, Qt::CaseInsensitive)) {
            partialNameMatch = service;
        }

        if (!partialStorageIdMatch && serviceStorageId.contains(needle, Qt::CaseInsensitive)) {
            partialStorageIdMatch = service;
        }
    }

    if (exactNameMatch) {
        return exactNameMatch;
    }
    if (exactExecMatch) {
        return exactExecMatch;
    }
    if (partialNameMatch) {
        return partialNameMatch;
    }
    if (partialStorageIdMatch) {
        return partialStorageIdMatch;
    }

    return {};
}
}

SystemDiscovery::SystemDiscovery(QObject *parent)
    : QObject(parent)
{
}

void SystemDiscovery::requestFolderEntries(const QString &path)
{
    const QUrl url = QUrl::fromUserInput(path, QDir::homePath(), QUrl::AssumeLocalFile);
    if (!url.isValid()) {
        Q_EMIT operationFailed(QStringLiteral("folder"), tr("The folder location is invalid."));
        return;
    }

    auto *job = KIO::listDir(url, KIO::HideProgressInfo);
    auto *entries = new QVariantList;
    entries->reserve(maximumResults);

    connect(job, &KIO::ListJob::entries, this, [entries, url](KIO::Job *, const KIO::UDSEntryList &batch) {
        for (const KIO::UDSEntry &entry : batch) {
            if (entries->size() >= maximumResults) {
                continue;
            }

            const QString name = entry.stringValue(KIO::UDSEntry::UDS_NAME);
            const bool hidden = entry.numberValue(KIO::UDSEntry::UDS_HIDDEN, name.startsWith(QLatin1Char('.'))) != 0;
            if (hidden || name == QLatin1String(".") || name == QLatin1String("..")) {
                continue;
            }

            QUrl entryUrl(url);
            entryUrl.setPath(QDir(url.path()).filePath(name));
            const bool directory = entry.isDir();
            entries->append(QVariantMap{
                {QStringLiteral("type"), QStringLiteral("app")},
                {QStringLiteral("name"), entry.stringValue(KIO::UDSEntry::UDS_DISPLAY_NAME).isEmpty()
                        ? name
                        : entry.stringValue(KIO::UDSEntry::UDS_DISPLAY_NAME)},
                {QStringLiteral("icon"), directory ? QStringLiteral("folder") : QStringLiteral("text-x-generic")},
                {QStringLiteral("url"), entryUrl.toString()},
            });
        }
    });

    connect(job, &KJob::result, this, [this, job, entries]() {
        if (job->error()) {
            Q_EMIT operationFailed(QStringLiteral("folder"), job->errorString());
        } else {
            Q_EMIT folderEntriesReady(*entries);
        }
        delete entries;
    });
}

void SystemDiscovery::requestApplications(const QString &category)
{
    QVariantList applications;
    applications.reserve(maximumResults);
    QSet<QString> seenStorageIds;

    const KService::List services = KService::allServices();
    for (const KService::Ptr &service : services) {
        if (!service || service->noDisplay() || !service->isApplication()) {
            continue;
        }
        if (!category.isEmpty() && !service->categories().contains(category, Qt::CaseInsensitive)) {
            continue;
        }
        if (seenStorageIds.contains(service->storageId())) {
            continue;
        }

        seenStorageIds.insert(service->storageId());
        applications.append(serviceMap(service));
        if (applications.size() >= maximumResults) {
            break;
        }
    }

    Q_EMIT applicationsReady(applications);
}

void SystemDiscovery::requestApplication(const QString &query)
{
    const KService::Ptr best = findApplicationService(query);
    if (!best) {
        Q_EMIT applicationReady({});
        return;
    }

    Q_EMIT applicationReady(serviceMap(best));
}

QString SystemDiscovery::iconForApplication(const QString &applicationId) const
{
    const QString normalizedId = normalizedApplicationId(applicationId);
    KService::Ptr service = KService::serviceByStorageId(normalizedId);
    if (!service) {
        service = KService::serviceByDesktopName(normalizedId);
    }
    return service ? service->icon() : QString{};
}

QString SystemDiscovery::applicationIdForCommand(const QString &command) const
{
    const KService::Ptr service = findApplicationService(commandLookupKey(command));
    return service ? normalizedApplicationId(service->storageId()) : QString{};
}

void SystemDiscovery::launchApplication(const QString &storageId)
{
    const KService::Ptr service = KService::serviceByStorageId(storageId);
    if (!service) {
        Q_EMIT operationFailed(QStringLiteral("launch"), tr("The application could not be found."));
        return;
    }

    auto *job = new KIO::ApplicationLauncherJob(service, this);
    job->setUiDelegate(nullptr);
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(QStringLiteral("launch"), job->errorString());
        }
    });
    job->start();
}

bool SystemDiscovery::launchApplicationByCommand(const QString &command)
{
    const KService::Ptr service = findApplicationService(commandLookupKey(command));
    if (!service) {
        return false;
    }

    auto *job = new KIO::ApplicationLauncherJob(service, this);
    job->setUiDelegate(nullptr);
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(QStringLiteral("launch"), job->errorString());
        }
    });
    job->start();
    return true;
}

void SystemDiscovery::openUrl(const QString &url)
{
    auto *job = new KIO::OpenUrlJob(QUrl::fromUserInput(url), QString(), this);
    job->setUiDelegate(nullptr);
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(QStringLiteral("openUrl"), job->errorString());
        }
    });
    job->start();
}
