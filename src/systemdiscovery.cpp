// SPDX-License-Identifier: GPL-3.0-or-later

#include "systemdiscovery.h"

#include <KLocalizedString>
#include <KNotificationJobUiDelegate>

#include "commandclassification.h"
#include "dropurlpolicy.h"

#include <KApplicationTrader>
#include <KIO/ApplicationLauncherJob>
#include <KIO/ListJob>
#include <KIO/OpenUrlJob>
#include <KIO/UDSEntry>
#include <KService>
#include <KServiceAction>

#include <QDir>
#include <QFileInfo>
#include <QSettings>
#include <QRegularExpression>
#include <QSet>
#include <QStandardPaths>
#include <QUrl>

namespace
{
constexpr auto TranslationDomain = "plasma_applet_org.kde.plasma.punchi-dock-remastered";

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

KService::Ptr findLauncherService(const QString &applicationId, const QString &launcherUrlText)
{
    KService::Ptr service;
    const QUrl launcherUrl(launcherUrlText.trimmed());

    // Match libtaskmanager's launcher resolution: applications: URLs carry a
    // KService menu id, while local launcher URLs point at a desktop file.
    if (launcherUrl.scheme() == QLatin1String("applications")) {
        service = KService::serviceByMenuId(launcherUrl.path());
    } else if (launcherUrl.isLocalFile()) {
        service = KService::serviceByDesktopPath(launcherUrl.toLocalFile());
    }

    if (!service) {
        const QString normalizedId = normalizedApplicationId(applicationId);
        if (!normalizedId.isEmpty()) {
            service = KService::serviceByStorageId(normalizedId);
            if (!service) {
                service = KService::serviceByDesktopName(normalizedId);
            }
        }
    }

    return service && service->isApplication() ? service : KService::Ptr{};
}

QString iconFromDesktopDirectory(const QStringList &fileNames)
{
    const QStringList searchDirs = QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation);
    for (const QString &baseDir : searchDirs) {
        const QString directoryPath = baseDir + QStringLiteral("/desktop-directories");
        for (const QString &fileName : fileNames) {
            const QString fullPath = directoryPath + QLatin1Char('/') + fileName;
            if (!QFileInfo::exists(fullPath)) {
                continue;
            }

            QSettings desktopFile(fullPath, QSettings::IniFormat);
            desktopFile.beginGroup(QStringLiteral("Desktop Entry"));
            const QString icon = desktopFile.value(QStringLiteral("Icon")).toString().trimmed();
            desktopFile.endGroup();
            if (!icon.isEmpty()) {
                return icon;
            }
        }
    }
    return {};
}

QString desktopDirectoryIconForCategory(const QString &category)
{
    const QString normalizedCategory = category.trimmed();
    if (normalizedCategory.isEmpty()) {
        return {};
    }

    if (normalizedCategory.compare(QStringLiteral("Development"), Qt::CaseInsensitive) == 0) {
        return iconFromDesktopDirectory({QStringLiteral("kf5-development.directory"), QStringLiteral("Development-More.directory")});
    }
    if (normalizedCategory.compare(QStringLiteral("Game"), Qt::CaseInsensitive) == 0) {
        return iconFromDesktopDirectory({QStringLiteral("kf5-games.directory"), QStringLiteral("Games-More.directory")});
    }
    if (normalizedCategory.compare(QStringLiteral("AudioVideo"), Qt::CaseInsensitive) == 0) {
        return iconFromDesktopDirectory({QStringLiteral("kf5-multimedia.directory"), QStringLiteral("Multimedia-More.directory")});
    }
    if (normalizedCategory.compare(QStringLiteral("Network"), Qt::CaseInsensitive) == 0) {
        return iconFromDesktopDirectory({QStringLiteral("kf5-internet.directory"), QStringLiteral("kf5-network.directory"), QStringLiteral("Internet-More.directory")});
    }
    if (normalizedCategory.compare(QStringLiteral("Office"), Qt::CaseInsensitive) == 0) {
        return iconFromDesktopDirectory({QStringLiteral("kf5-office.directory"), QStringLiteral("Office-More.directory")});
    }
    if (normalizedCategory.compare(QStringLiteral("System"), Qt::CaseInsensitive) == 0) {
        return iconFromDesktopDirectory({QStringLiteral("kf5-system.directory"), QStringLiteral("System-More.directory")});
    }
    if (normalizedCategory.compare(QStringLiteral("Utility"), Qt::CaseInsensitive) == 0) {
        return iconFromDesktopDirectory({QStringLiteral("kf5-utilities.directory"), QStringLiteral("Utilities.directory"), QStringLiteral("Utilities-More.directory")});
    }
    if (normalizedCategory.compare(QStringLiteral("Graphics"), Qt::CaseInsensitive) == 0) {
        return iconFromDesktopDirectory({QStringLiteral("kf5-graphics.directory"), QStringLiteral("Graphics-More.directory")});
    }

    return {};
}

bool isCategoryMatch(const QStringList &serviceCategories, const QString &requestedCategory)
{
    const QString trimmedRequested = requestedCategory.trimmed();
    if (trimmedRequested.isEmpty()) {
        return true;
    }

    static const QHash<QString, QStringList> categoryFamilies = {
        {QStringLiteral("AudioVideo"),  {QStringLiteral("AudioVideo"), QStringLiteral("Audio"), QStringLiteral("Video"), QStringLiteral("Player"), QStringLiteral("Music"), QStringLiteral("Recorder"), QStringLiteral("TV"), QStringLiteral("AudioVideoEditing")}},
        {QStringLiteral("Network"),     {QStringLiteral("Network"), QStringLiteral("WebBrowser"), QStringLiteral("Email"), QStringLiteral("IRCClient"), QStringLiteral("Feed"), QStringLiteral("FileTransfer"), QStringLiteral("RemoteAccess"), QStringLiteral("Internet")}},
        {QStringLiteral("Development"), {QStringLiteral("Development"), QStringLiteral("IDE"), QStringLiteral("Building"), QStringLiteral("Debugger"), QStringLiteral("TextEditor"), QStringLiteral("RevisionControl"), QStringLiteral("WebDevelopment")}},
        {QStringLiteral("Graphics"),    {QStringLiteral("Graphics"), QStringLiteral("VectorGraphics"), QStringLiteral("RasterGraphics"), QStringLiteral("3DGraphics"), QStringLiteral("Photography"), QStringLiteral("Viewer"), QStringLiteral("Paint")}},
        {QStringLiteral("Office"),      {QStringLiteral("Office"), QStringLiteral("WordProcessor"), QStringLiteral("Spreadsheet"), QStringLiteral("Presentation"), QStringLiteral("Publishing"), QStringLiteral("Finance"), QStringLiteral("Calendar"), QStringLiteral("Calculator")}},
        {QStringLiteral("System"),      {QStringLiteral("System"), QStringLiteral("Monitor"), QStringLiteral("Security"), QStringLiteral("Settings"), QStringLiteral("PackageManager"), QStringLiteral("TerminalEmulator")}},
        {QStringLiteral("Utility"),     {QStringLiteral("Utility"), QStringLiteral("Utilities"), QStringLiteral("FileTools"), QStringLiteral("Archiving"), QStringLiteral("Clock"), QStringLiteral("TextEditor")}},
        {QStringLiteral("Game"),        {QStringLiteral("Game"), QStringLiteral("ActionGame"), QStringLiteral("AdventureGame"), QStringLiteral("ArcadeGame"), QStringLiteral("BoardGame"), QStringLiteral("CardGame"), QStringLiteral("BlocksGame"), QStringLiteral("Emulator")}},
        {QStringLiteral("Education"),   {QStringLiteral("Education"), QStringLiteral("Science"), QStringLiteral("Math"), QStringLiteral("History"), QStringLiteral("Geography")}}
    };

    const QStringList targetSubcategories = categoryFamilies.value(trimmedRequested, QStringList{trimmedRequested});
    for (const QString &subCat : targetSubcategories) {
        for (const QString &serviceCat : serviceCategories) {
            if (serviceCat.compare(subCat, Qt::CaseInsensitive) == 0) {
                return true;
            }
        }
    }

    return false;
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
        Q_EMIT operationFailed(QStringLiteral("folder"), i18nd(TranslationDomain, "The folder location is invalid."));
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

    const KService::List services = KApplicationTrader::query([&category](const KService::Ptr &service) {
        if (!service || service->noDisplay() || !service->isApplication()) {
            return false;
        }
        return isCategoryMatch(service->categories(), category);
    });

    for (const KService::Ptr &service : services) {
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

QString SystemDiscovery::iconForCategory(const QString &category) const
{
    return desktopDirectoryIconForCategory(category);
}

QString SystemDiscovery::applicationIdForCommand(const QString &command) const
{
    const KService::Ptr service = findApplicationService(commandLookupKey(command));
    return service ? normalizedApplicationId(service->storageId()) : QString{};
}

QVariantMap SystemDiscovery::applicationForLauncher(const QString &applicationId, const QString &launcherUrl) const
{
    return serviceMap(findLauncherService(applicationId, launcherUrl));
}

QVariantList SystemDiscovery::applicationActions(const QString &applicationId) const
{
    QVariantList result;
    const KService::Ptr service = findApplicationService(applicationId);
    if (!service) {
        return result;
    }

    const QList<KServiceAction> actions = service->actions();
    result.reserve(actions.size());
    for (const KServiceAction &action : actions) {
        if (action.noDisplay() || action.isSeparator() || action.name().isEmpty() || action.text().isEmpty()) {
            continue;
        }

        result.append(QVariantMap{
            {QStringLiteral("kind"), QStringLiteral("desktopAction")},
            {QStringLiteral("name"), action.text()},
            {QStringLiteral("icon"), action.icon().isEmpty() ? QStringLiteral("system-run") : action.icon()},
            {QStringLiteral("applicationId"), normalizedApplicationId(service->storageId())},
            {QStringLiteral("actionId"), action.name()},
            {QStringLiteral("enabled"), true},
        });
    }
    return result;
}

QVariantMap SystemDiscovery::validateDroppedUrls(const QVariantList &urls) const
{
    const DropUrlPolicy::Result result = DropUrlPolicy::validate(urls);
    QVariantList normalizedUrls;
    normalizedUrls.reserve(result.urls.size());
    for (const QUrl &url : result.urls) {
        normalizedUrls.append(QVariant::fromValue(url));
    }

    return {
        {QStringLiteral("accepted"), result.accepted()},
        {QStringLiteral("errorCode"), result.errorCode},
        {QStringLiteral("urls"), normalizedUrls},
        {QStringLiteral("maximumUrlCount"), DropUrlPolicy::maximumUrlCount},
        {QStringLiteral("maximumUrlBytes"), DropUrlPolicy::maximumUrlBytes},
        {QStringLiteral("maximumBatchBytes"), DropUrlPolicy::maximumBatchBytes},
    };
}

void SystemDiscovery::launchApplication(const QString &storageId)
{
    KService::Ptr service = KService::serviceByStorageId(storageId);
    if (!service) {
        service = findApplicationService(storageId);
    }
    if (!service) {
        const QString message = i18nd(TranslationDomain, "The application could not be found.");
        Q_EMIT applicationLaunchFinished(false, message);
        Q_EMIT operationFailed(QStringLiteral("launch"), message);
        return;
    }

    auto *job = new KIO::ApplicationLauncherJob(service, this);
    job->setUiDelegate(nullptr);
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT applicationLaunchFinished(false, job->errorString());
            Q_EMIT operationFailed(QStringLiteral("launch"), job->errorString());
        } else {
            Q_EMIT applicationLaunchFinished(true, QString());
        }
    });
    job->start();
}

bool SystemDiscovery::launchApplicationWithUrls(const QString &applicationId, const QString &command,
    const QString &launcherUrl, const QVariantList &urls)
{
    const DropUrlPolicy::Result validatedUrls = DropUrlPolicy::validate(urls);
    if (!validatedUrls.accepted()) {
        return false;
    }

    const QString rawId = applicationId.trimmed();
    const QString normalizedId = normalizedApplicationId(rawId);
    KService::Ptr service;
    if (!rawId.isEmpty()) {
        service = KService::serviceByStorageId(rawId);
    }
    if (!service && !normalizedId.isEmpty()) {
        service = KService::serviceByStorageId(normalizedId);
        if (!service) {
            service = KService::serviceByDesktopName(normalizedId);
        }
    }
    if (!service) {
        service = findLauncherService(rawId, launcherUrl);
    }
    if (!service && CommandClassification::canResolveToDesktopService(command)) {
        service = findApplicationService(commandLookupKey(command));
    }
    if (!service || !service->isApplication()) {
        return false;
    }

    auto *job = new KIO::ApplicationLauncherJob(service, this);
    job->setUrls(validatedUrls.urls);
    job->setUiDelegate(new KNotificationJobUiDelegate(KJobUiDelegate::AutoErrorHandlingEnabled));
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(QStringLiteral("dropLaunch"), job->errorString());
        }
    });
    job->start();
    return true;
}

bool SystemDiscovery::launchApplicationAction(const QString &applicationId, const QString &actionId)
{
    const KService::Ptr service = findApplicationService(applicationId);
    if (!service || actionId.trimmed().isEmpty()) {
        return false;
    }

    const QList<KServiceAction> actions = service->actions();
    for (const KServiceAction &action : actions) {
        if (action.noDisplay() || action.isSeparator() || action.name() != actionId) {
            continue;
        }

        auto *job = new KIO::ApplicationLauncherJob(action, this);
        job->setUiDelegate(nullptr);
        connect(job, &KJob::result, this, [this, job]() {
            if (job->error()) {
                Q_EMIT operationFailed(QStringLiteral("launchAction"), job->errorString());
            }
        });
        job->start();
        return true;
    }

    Q_EMIT operationFailed(QStringLiteral("launchAction"), i18nd(TranslationDomain, "The application action could not be found."));
    return false;
}

bool SystemDiscovery::launchApplicationByCommand(const QString &command)
{
    if (!CommandClassification::canResolveToDesktopService(command)) {
        return false;
    }

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
