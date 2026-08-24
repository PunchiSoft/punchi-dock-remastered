/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QEvent>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJSValue>
#include <QMutex>
#include <QMutexLocker>
#include <QPointer>
#include <QQuickItem>
#include <QSet>
#include <QTemporaryDir>
#include <QTest>

#include <KPluginMetaData>
#include <KPackage/Package>
#include <KPackage/PackageLoader>

#include <Plasma/Applet>
#include <Plasma/Containment>
#include <Plasma/Corona>
#include <Plasma/PluginLoader>
#include <PlasmaQuick/AppletQuickItem>

#include <algorithm>
#include <memory>
#include <utility>

namespace
{
constexpr auto s_pluginId = "org.kde.plasma.punchi-dock-remastered";

QMutex s_messageMutex;
QStringList s_runtimeMessages;
bool s_captureRuntimeMessages = false;
QtMessageHandler s_previousMessageHandler = nullptr;

QString messageTypeName(QtMsgType type)
{
    switch (type) {
    case QtDebugMsg:
        return QStringLiteral("debug");
    case QtInfoMsg:
        return QStringLiteral("info");
    case QtWarningMsg:
        return QStringLiteral("warning");
    case QtCriticalMsg:
        return QStringLiteral("critical");
    case QtFatalMsg:
        return QStringLiteral("fatal");
    }

    return QStringLiteral("unknown");
}

void runtimeMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &message)
{
    if (type == QtWarningMsg || type == QtCriticalMsg || type == QtFatalMsg) {
        QMutexLocker locker(&s_messageMutex);
        const QString category = QString::fromUtf8(context.category ? context.category : "default");
        // These exact warnings are emitted by the system Plasma/Qt stack when
        // windows are instantiated on the offscreen platform without KWin.
        // Critical and fatal messages are never allowlisted.
        const bool expectedOffscreenDiagnostic = type == QtWarningMsg
            && ((category == QLatin1StringView("kf.windowsystem")
             && message == QLatin1StringView("Could not find any platform plugin"))
            || (category == QLatin1StringView("qt.qml.propertyCache.append")
                && message == QLatin1StringView("Member visible of the object PlasmaQuick::Dialog overrides a member of the base object. Consider renaming it or adding final or override specifier"))
            || (category == QLatin1StringView("kf.plasma.quick")
                && message.startsWith(QLatin1StringView("Couldn't create KWindowShadow for PlasmaQuick::"))
                && message.endsWith(QLatin1Char(')')))
            || (category == QLatin1StringView("org.kde.plasma.libtaskmanager")
                && message == QLatin1StringView("Failed to determine whether virtual desktop navigation wrapping is enabled:  \"The name org.kde.KWin was not provided by any .service files\""))
            || (category == QLatin1StringView("default")
                && message == QLatin1StringView("This plugin does not support setting window masks")));

        if (s_captureRuntimeMessages && !expectedOffscreenDiagnostic) {
            const QString file = QString::fromUtf8(context.file ? context.file : "unknown");
            s_runtimeMessages.append(QStringLiteral("%1 [%2] %3 (%4:%5)")
                                         .arg(messageTypeName(type), category, message, file)
                                         .arg(context.line));
        }
    }

    if (s_previousMessageHandler) {
        s_previousMessageHandler(type, context, message);
    }
}

void beginRuntimeMessageCapture()
{
    QMutexLocker locker(&s_messageMutex);
    s_runtimeMessages.clear();
    s_captureRuntimeMessages = true;
}

QStringList endRuntimeMessageCapture()
{
    QMutexLocker locker(&s_messageMutex);
    s_captureRuntimeMessages = false;
    return s_runtimeMessages;
}

void drainDeferredEvents()
{
    for (int iteration = 0; iteration < 10; ++iteration) {
        QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
        QCoreApplication::processEvents(QEventLoop::AllEvents, 10);
    }
}

bool copyFile(const QString &sourcePath, const QString &destinationPath, QString *error)
{
    const QFileInfo sourceInfo(sourcePath);
    if (!sourceInfo.isFile() || sourceInfo.size() <= 0) {
        *error = QStringLiteral("Required source file is missing or empty: %1").arg(sourcePath);
        return false;
    }

    if (!QDir().mkpath(QFileInfo(destinationPath).absolutePath())) {
        *error = QStringLiteral("Could not create destination directory for: %1").arg(destinationPath);
        return false;
    }

    if (!QFile::copy(sourcePath, destinationPath)) {
        *error = QStringLiteral("Could not copy %1 to %2").arg(sourcePath, destinationPath);
        return false;
    }

    return true;
}

bool copyPackageContents(const QString &sourcePath, const QString &destinationPath, QString *error)
{
    const QDir sourceDirectory(sourcePath);
    if (!sourceDirectory.exists()) {
        *error = QStringLiteral("Package source directory does not exist: %1").arg(sourcePath);
        return false;
    }

    if (!QDir().mkpath(destinationPath)) {
        *error = QStringLiteral("Could not create package destination: %1").arg(destinationPath);
        return false;
    }

    const QSet<QString> generatedModuleFiles{
        QStringLiteral("ui/org/punchi/dock/libpunchidockintegration.so"),
        QStringLiteral("ui/org/punchi/dock/libpunchidockintegrationplugin.so"),
        QStringLiteral("ui/org/punchi/dock/punchidockintegration.qmltypes"),
        QStringLiteral("ui/org/punchi/dock/qmldir"),
    };

    QDirIterator iterator(sourcePath,
                          QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot,
                          QDirIterator::Subdirectories);
    while (iterator.hasNext()) {
        iterator.next();
        const QString relativePath = sourceDirectory.relativeFilePath(iterator.filePath());
        if (generatedModuleFiles.contains(relativePath)) {
            continue;
        }

        const QString destination = QDir(destinationPath).filePath(relativePath);
        if (iterator.fileInfo().isDir()) {
            if (!QDir().mkpath(destination)) {
                *error = QStringLiteral("Could not create package directory: %1").arg(destination);
                return false;
            }
            continue;
        }

        if (!copyFile(iterator.filePath(), destination, error)) {
            return false;
        }
    }

    return true;
}

struct LoadResult {
    bool appletLoaded = false;
    bool appletDestroyed = false;
    bool containmentAssigned = false;
    bool quickItemLoaded = false;
    bool quickItemDestroyed = false;
    bool fullRepresentationDeclared = false;
    bool compactMatchesFull = false;
    bool preferredMatchesFull = false;
    bool fullRepresentationItemLoaded = false;
    bool dockItemsControllerAvailable = false;
    int dockItemCount = -1;
    QString pluginName;
    QString launchError;
    QStringList runtimeMessages;
};

class TestCorona final : public Plasma::Corona
{
public:
    using Plasma::Corona::Corona;

    int numScreens() const override
    {
        return 1;
    }

    QRect screenGeometry(int screen) const override
    {
        return screen == 0 ? QRect(0, 0, 1920, 1080) : QRect();
    }
};
}

class PlasmoidFullLoadTest : public QObject
{
    Q_OBJECT

public:
    explicit PlasmoidFullLoadTest(QString environmentRoot)
        : m_environmentRoot(std::move(environmentRoot))
    {
    }

private Q_SLOTS:
    void initTestCase()
    {
        const QString sourceRoot = QStringLiteral(PUNCHI_PROJECT_SOURCE_DIR);
        m_packageRoot = QDir(m_environmentRoot)
                            .filePath(QStringLiteral("data/plasma/plasmoids/%1").arg(QString::fromLatin1(s_pluginId)));

        QString error;
        QVERIFY2(QDir().mkpath(m_packageRoot), qPrintable(QStringLiteral("Could not create %1").arg(m_packageRoot)));
        QVERIFY2(copyFile(QDir(sourceRoot).filePath(QStringLiteral("metadata.json")),
                          QDir(m_packageRoot).filePath(QStringLiteral("metadata.json")),
                          &error),
                 qPrintable(error));
        QVERIFY2(copyPackageContents(QDir(sourceRoot).filePath(QStringLiteral("contents")),
                                     QDir(m_packageRoot).filePath(QStringLiteral("contents")),
                                     &error),
                 qPrintable(error));

        const QString moduleRoot = QDir(m_packageRoot).filePath(QStringLiteral("contents/ui/org/punchi/dock"));
        const QList<QPair<QString, QString>> generatedFiles{
            {QStringLiteral(PUNCHI_INTEGRATION_LIBRARY), QStringLiteral("libpunchidockintegration.so")},
            {QStringLiteral(PUNCHI_INTEGRATION_PLUGIN), QStringLiteral("libpunchidockintegrationplugin.so")},
            {QStringLiteral(PUNCHI_INTEGRATION_QMLDIR), QStringLiteral("qmldir")},
            {QStringLiteral(PUNCHI_INTEGRATION_QMLTYPES), QStringLiteral("punchidockintegration.qmltypes")},
        };

        for (const auto &[source, fileName] : generatedFiles) {
            QVERIFY2(copyFile(source, QDir(moduleRoot).filePath(fileName), &error), qPrintable(error));
        }

        const auto metadata = Plasma::PluginLoader::self()->listAppletMetaData(QString());
        const auto packageEntry = std::find_if(metadata.cbegin(), metadata.cend(), [](const KPluginMetaData &entry) {
            return entry.pluginId() == QLatin1StringView(s_pluginId);
        });
        QVERIFY2(packageEntry != metadata.cend(), "The isolated Punchi Dock package was not discovered by Plasma");

        const QString metadataPath = QFileInfo(packageEntry->fileName()).canonicalFilePath();
        const QString canonicalPackageRoot = QFileInfo(m_packageRoot).canonicalFilePath();
        QVERIFY2(metadataPath.startsWith(canonicalPackageRoot + QLatin1Char('/')),
                 qPrintable(QStringLiteral("Plasma selected a package outside the isolated fixture: %1").arg(metadataPath)));

        m_corona = std::make_unique<TestCorona>();
        KPackage::Package shellPackage = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/Shell"));
        shellPackage.setPath(QStringLiteral("org.kde.plasma.desktop"));
        QVERIFY2(shellPackage.isValid(), "The system Plasma shell package is unavailable");
        m_corona->setKPackage(shellPackage);
        m_containment = m_corona->createContainment(QStringLiteral("null"));
        QVERIFY2(m_containment, "Could not create the isolated test containment");
        m_containment->setFormFactor(Plasma::Types::Horizontal);
        m_containment->setLocation(Plasma::Types::BottomEdge);

        s_previousMessageHandler = qInstallMessageHandler(runtimeMessageHandler);
    }

    void fullRepresentationLoadsTwiceWithoutRuntimeWarnings()
    {
        for (uint appletId : {1001U, 1002U}) {
            const LoadResult result = loadAndDestroy(appletId);
            QVERIFY2(result.appletLoaded, "Plasma::PluginLoader did not return an applet");
            QVERIFY2(result.containmentAssigned, "The applet was not assigned to the isolated containment");
            QCOMPARE(result.pluginName, QString::fromLatin1(s_pluginId));
            QVERIFY2(result.launchError.isEmpty(), qPrintable(result.launchError));
            QVERIFY2(result.quickItemLoaded, "Plasma did not create an AppletQuickItem");
            QVERIFY2(result.fullRepresentationDeclared, "The full representation component is missing");
            QVERIFY2(result.compactMatchesFull, "The compact representation no longer aliases the full representation");
            QVERIFY2(result.preferredMatchesFull, "The preferred representation is not the full representation");
            QVERIFY2(result.fullRepresentationItemLoaded, "The full representation item was not instantiated");
            QVERIFY2(result.dockItemsControllerAvailable, "The dock items controller is unavailable");
            QVERIFY2(result.dockItemCount > 0, "A clean first run did not load the default dock items");
            QVERIFY2(result.appletDestroyed, "The applet survived its explicit teardown");
            QVERIFY2(result.quickItemDestroyed, "The AppletQuickItem survived applet teardown");
            QVERIFY2(result.runtimeMessages.isEmpty(), qPrintable(result.runtimeMessages.join(QLatin1Char('\n'))));
        }
    }

    void cleanupTestCase()
    {
        m_containment = nullptr;
        m_corona.reset();
        drainDeferredEvents();
        qInstallMessageHandler(s_previousMessageHandler);
        s_previousMessageHandler = nullptr;
    }

private:
    LoadResult loadAndDestroy(uint appletId)
    {
        LoadResult result;
        beginRuntimeMessageCapture();

        Plasma::Applet *applet = Plasma::PluginLoader::self()->loadApplet(QString::fromLatin1(s_pluginId), appletId);
        QPointer<Plasma::Applet> appletGuard(applet);
        result.appletLoaded = applet != nullptr;

        QPointer<PlasmaQuick::AppletQuickItem> itemGuard;
        if (applet) {
            m_containment->addApplet(applet);
            result.containmentAssigned = applet->containment() == m_containment;
            result.pluginName = applet->pluginName();
            result.launchError = applet->launchErrorMessage();

            PlasmaQuick::AppletQuickItem *item = PlasmaQuick::AppletQuickItem::itemForApplet(applet);
            itemGuard = item;
            result.quickItemLoaded = item != nullptr;
            if (item) {
                QQmlComponent *fullRepresentation = item->fullRepresentation();
                result.fullRepresentationDeclared = fullRepresentation != nullptr;
                result.compactMatchesFull = item->compactRepresentation() == fullRepresentation;
                result.preferredMatchesFull = item->preferredRepresentation() == fullRepresentation;

                item->setExpanded(true);
                drainDeferredEvents();
                QQuickItem *fullRepresentationItem = item->fullRepresentationItem();
                result.fullRepresentationItemLoaded = fullRepresentationItem != nullptr;
                if (fullRepresentationItem) {
                    const QVariant controllerValue =
                        fullRepresentationItem->property("dockItemsControllerService");
                    QObject *controller = qvariant_cast<QObject *>(controllerValue);
                    if (!controller && controllerValue.canConvert<QJSValue>()) {
                        controller = controllerValue.value<QJSValue>().toQObject();
                    }
                    if (!controller) {
                        controller = item->findChild<QObject *>(
                            QStringLiteral("dockItemsController"));
                    }
                    result.dockItemsControllerAvailable = controller != nullptr;
                    if (controller) {
                        const QVariant dockItems = controller->property("dockItems");
                        if (dockItems.canConvert<QJSValue>()) {
                            result.dockItemCount = dockItems.value<QJSValue>()
                                                       .property(QStringLiteral("length"))
                                                       .toInt();
                        } else {
                            result.dockItemCount = dockItems.toList().size();
                        }
                    }
                }
            }

            delete applet;
            drainDeferredEvents();
        }

        result.appletDestroyed = appletGuard.isNull();
        result.quickItemDestroyed = itemGuard.isNull();
        result.runtimeMessages = endRuntimeMessageCapture();
        return result;
    }

    QString m_environmentRoot;
    QString m_packageRoot;
    std::unique_ptr<TestCorona> m_corona;
    Plasma::Containment *m_containment = nullptr;
};

int main(int argc, char **argv)
{
    QTemporaryDir environment(QStringLiteral("/tmp/punchi-full-load-test-XXXXXX"));
    if (!environment.isValid()) {
        return 1;
    }

    const QList<QPair<QByteArray, QString>> isolatedLocations{
        {QByteArrayLiteral("XDG_DATA_HOME"), QStringLiteral("data")},
        {QByteArrayLiteral("XDG_CONFIG_HOME"), QStringLiteral("config")},
        {QByteArrayLiteral("XDG_CACHE_HOME"), QStringLiteral("cache")},
        {QByteArrayLiteral("XDG_RUNTIME_DIR"), QStringLiteral("runtime")},
    };
    for (const auto &[variable, directory] : isolatedLocations) {
        const QString path = QDir(environment.path()).filePath(directory);
        if (!QDir().mkpath(path)) {
            return 1;
        }
        if (variable == QByteArrayLiteral("XDG_RUNTIME_DIR")
            && !QFile::setPermissions(path, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner)) {
            return 1;
        }
        qputenv(variable.constData(), QFile::encodeName(path));
    }

    qputenv("QT_QPA_PLATFORM", "offscreen");
    qputenv("QT_QUICK_BACKEND", "software");

    QGuiApplication application(argc, argv);
    PlasmoidFullLoadTest test(environment.path());
    const int result = QTest::qExec(&test, argc, argv);
    return result;
}

#include "plasmoid_full_load_test.moc"
