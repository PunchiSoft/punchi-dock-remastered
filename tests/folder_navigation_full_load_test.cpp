// SPDX-License-Identifier: GPL-3.0-or-later

#include <QAbstractItemModel>
#include <KConfig>
#include <KConfigGroup>
#include <KConfigPropertyMap>
#include <KPackage/Package>
#include <KPackage/PackageLoader>
#include <Plasma/Applet>
#include <Plasma/Containment>
#include <Plasma/Corona>
#include <Plasma/PluginLoader>
#include <PlasmaQuick/AppletQuickItem>
#include <QDirIterator>
#include <QFile>
#include <QGuiApplication>
#include <QJSValue>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QKeyEvent>
#include <QMutex>
#include <QMutexLocker>
#include <QPointer>
#include <QProcess>
#include <QQuickItem>
#include <QQuickWindow>
#include <QStandardItemModel>
#include <QStandardPaths>
#include <QTest>
#include <cmath>

namespace {
QStringList warnings;
QMutex warningMutex;
QtMessageHandler previousHandler = nullptr;
void capture(QtMsgType type, const QMessageLogContext &context, const QString &message)
{
    const QString category = QString::fromUtf8(context.category);
    // Same exact offscreen limitations as the established full-load fixture.
    const bool expected = type == QtWarningMsg && (
        (category == QLatin1String("kf.windowsystem") && message == QLatin1String("Could not find any platform plugin"))
        || (category == QLatin1String("qt.qml.propertyCache.append") && message == QLatin1String("Member visible of the object PlasmaQuick::Dialog overrides a member of the base object. Consider renaming it or adding final or override specifier"))
        || (category == QLatin1String("kf.plasma.quick") && message.startsWith(QLatin1String("Couldn't create KWindowShadow for ")) && message.endsWith(QLatin1Char(')')))
        || (category == QLatin1String("org.kde.plasma.libtaskmanager") && message == QLatin1String("Failed to determine whether virtual desktop navigation wrapping is enabled:  \"The name org.kde.KWin was not provided by any .service files\""))
        || (category == QLatin1String("default") && (message == QLatin1String("This plugin does not support setting window masks")
            || message == QLatin1String("This plugin does not support raise()") || message == QLatin1String("This plugin does not support setting window opacity")
            || message == QLatin1String("This plugin does not support propagateSizeHints()"))));
    if ((type == QtWarningMsg || type == QtCriticalMsg || type == QtFatalMsg) && !expected) {
        QMutexLocker locker(&warningMutex);
        warnings.append(message);
    }
    if (previousHandler) { previousHandler(type, context, message); }
}
class TestCorona final : public Plasma::Corona {
public:
    int numScreens() const override { return 1; }
    QRect screenGeometry(int screen) const override { return screen == 0 ? QRect(0, 0, 1920, 1080) : QRect(); }
};
bool copyFile(const QString &source, const QString &target)
{
    return QDir().mkpath(QFileInfo(target).absolutePath()) && QFile::copy(source, target);
}
QQuickItem *findVisual(QQuickItem *item, const QString &name)
{
    if (item->objectName() == name) { return item; }
    for (auto *child : item->childItems()) {
        if (auto *match = findVisual(child, name)) { return match; }
    }
    return nullptr;
}
QVariantMap objectMap(const QVariant &value)
{
    return value.canConvert<QJSValue>() ? value.value<QJSValue>().toVariant().toMap() : value.toMap();
}
QQuickItem *findContainer(QQuickItem *item)
{
    if (objectMap(item->property("modelData")).value(QStringLiteral("name")).toString() == QLatin1String("Navigation Fixture")) { return item; }
    for (auto *child : item->childItems()) { if (auto *match = findContainer(child)) { return match; } }
    return nullptr;
}
}

class FolderNavigationFullLoadTest : public QObject {
    Q_OBJECT
private Q_SLOTS:
    void initTestCase()
    {
        const QString root = QFile::decodeName(qgetenv("PUNCHI_TEST_ENVIRONMENT_ROOT"));
        const QString package = root + QStringLiteral("/data/plasma/plasmoids/org.kde.plasma.punchi-dock-remastered");
        const QString source = QStringLiteral(PUNCHI_PROJECT_SOURCE_DIR);
        QVERIFY(copyFile(source + QStringLiteral("/metadata.json"), package + QStringLiteral("/metadata.json")));
        QDirIterator files(source + QStringLiteral("/contents"), QDir::Files, QDirIterator::Subdirectories);
        while (files.hasNext()) {
            const QString path = files.next();
            const QString relative = QDir(source).relativeFilePath(path);
            if (relative.startsWith(QLatin1String("contents/ui/org/"))) { continue; }
            QVERIFY(copyFile(path, package + QLatin1Char('/') + relative));
        }
        const QString module = package + QStringLiteral("/contents/ui/org/punchi/dock/");
        QVERIFY(copyFile(QStringLiteral(PUNCHI_INTEGRATION_LIBRARY), module + QStringLiteral("libpunchidockintegration.so")));
        QVERIFY(copyFile(QStringLiteral(PUNCHI_INTEGRATION_PLUGIN), module + QStringLiteral("libpunchidockintegrationplugin.so")));
        QVERIFY(copyFile(QStringLiteral(PUNCHI_INTEGRATION_QMLDIR), module + QStringLiteral("qmldir")));
        QVERIFY(copyFile(QStringLiteral(PUNCHI_INTEGRATION_QMLTYPES), module + QStringLiteral("punchidockintegration.qmltypes")));
        const QString applications = QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
        QVERIFY(QDir().mkpath(applications));
        for (int i = 1; i <= 5; ++i) {
            QFile fixture(applications + QStringLiteral("/org.example.Recent%1.desktop").arg(i));
            QVERIFY(fixture.open(QIODevice::WriteOnly));
            const QByteArray entry = "[Desktop Entry]\nType=Application\nName=Recent Fixture\nIcon=system-run\nExec=/bin/true\n";
            QCOMPARE(fixture.write(entry), entry.size());
        }
        QProcess builder;
        builder.start(QStandardPaths::findExecutable(QStringLiteral("kbuildsycoca6")), {QStringLiteral("--noincremental")});
        QVERIFY(builder.waitForFinished(10000));
        QCOMPARE(builder.exitCode(), 0);
        previousHandler = qInstallMessageHandler(capture);
    }
    void navigateHotRefreshAndDestroyTwice()
    {
        const QString directory = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation) + QStringLiteral("/navigation-root");
        QVERIFY(QDir().mkpath(directory + QStringLiteral("/one/two")));
        QVariantMap descriptor{{QStringLiteral("type"), QStringLiteral("folder")},
            {QStringLiteral("name"), QStringLiteral("Navigation Fixture")},
            {QStringLiteral("icon"), QStringLiteral("folder")},
            {QStringLiteral("sourceType"), QStringLiteral("folder")},
            {QStringLiteral("sourcePath"), directory},
            {QStringLiteral("browseSubfolders"), true},
            {QStringLiteral("layout"), QStringLiteral("list")},
            {QStringLiteral("apps"), QVariantList{}}};
        for (uint id : {2301U, 2302U}) {
            TestCorona corona;
            auto shell = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/Shell"));
            shell.setPath(QStringLiteral("org.kde.plasma.desktop"));
            QVERIFY(shell.isValid());
            corona.setKPackage(shell);
            auto *containment = corona.createContainment(QStringLiteral("null"));
            QVERIFY(containment);
            containment->setFormFactor(Plasma::Types::Horizontal);
            containment->setLocation(Plasma::Types::BottomEdge);
            auto *applet = Plasma::PluginLoader::self()->loadApplet(QStringLiteral("org.kde.plasma.punchi-dock-remastered"), id);
            QVERIFY(applet);
            containment->addApplet(applet);
            QVERIFY(applet->launchErrorMessage().isEmpty());
            auto *config = applet->configuration();
            config->insert(QStringLiteral("showActiveTasks"), false);
            config->insert(QStringLiteral("showRecentApplications"), false);
            const auto json = [](const QVariantMap &item) {
                return QString::fromUtf8(QJsonDocument(QJsonArray{QJsonObject::fromVariantMap(item)}).toJson(QJsonDocument::Compact));
            };
            config->insert(QStringLiteral("dockItemsJson"), json(descriptor));
            auto *item = PlasmaQuick::AppletQuickItem::itemForApplet(applet);
            QVERIFY(item);
            QPointer<PlasmaQuick::AppletQuickItem> guard(item);
            QQuickWindow window;
            window.resize(900, 120);
            item->setWidth(900); item->setHeight(120);
            item->setParentItem(window.contentItem());
            window.show(); item->setExpanded(true);
            QTRY_VERIFY(item->fullRepresentationItem());
            auto *representation = item->fullRepresentationItem();
            auto *coordinator = findVisual(representation, QStringLiteral("popupCoordinator"));
            QVERIFY(coordinator);
            QQuickItem *anchor = nullptr;
            QTRY_VERIFY((anchor = findContainer(representation)));
            QCOMPARE(anchor->property("index").toInt(), 0);
            QVERIFY(QMetaObject::invokeMethod(coordinator, "openFolderPopup",
                Q_ARG(QVariant, QVariant(descriptor)), Q_ARG(QVariant, QVariant::fromValue(anchor))));
            QCOMPARE(coordinator->property("activeFolderModelIndex").toInt(), 0);
            const auto toObject = [](const QVariant &value) {
                return value.canConvert<QJSValue>() ? value.value<QJSValue>().toQObject() : value.value<QObject *>();
            };
            auto *dialog = toObject(coordinator->property("folderPopupDialogRef"));
            QVERIFY(dialog);
            QTRY_VERIFY(dialog->property("visible").toBool());
            auto *folder = dialog->findChild<QObject *>(QStringLiteral("folderPopupContent"));
            QVERIFY(folder);
            QTRY_VERIFY(folder->property("navigationActive").toBool());
            auto *controller = toObject(folder->property("navigationController"));
            QVERIFY(controller);
            auto *model = toObject(controller->property("rootModel"));
            QVERIFY(model);
            QTRY_VERIFY(!model->property("loading").toBool());
            QTRY_COMPARE(model->property("count").toInt(), 1);
            QVariantMap entry;
            QVERIFY(QMetaObject::invokeMethod(model, "get", Q_RETURN_ARG(QVariantMap, entry), Q_ARG(int, 0)));
            QVERIFY(entry.value(QStringLiteral("navigable")).toBool());
            QVERIFY(QMetaObject::invokeMethod(folder, "directoryActivated",
                Q_ARG(QVariant, QVariant(entry)), Q_ARG(int, 0), Q_ARG(double, 0.0)));
            QTRY_COMPARE(folder->property("navigationDepth").toInt(), 1);
            auto updated = descriptor;
            updated.insert(QStringLiteral("browseSubfolders"), false);
            config->insert(QStringLiteral("dockItemsJson"), json(updated));
            QVERIFY(QMetaObject::invokeMethod(applet, "configChanged"));
            QTRY_VERIFY(!folder->property("navigationActive").toBool());
            QTRY_COMPARE(folder->property("navigationDepth").toInt(), 0);
            config->insert(QStringLiteral("dockItemsJson"), json(descriptor));
            QVERIFY(QMetaObject::invokeMethod(applet, "configChanged"));
            QTRY_VERIFY(folder->property("navigationActive").toBool());
            QTRY_VERIFY(!model->property("loading").toBool());
            QVERIFY(QMetaObject::invokeMethod(dialog, "closeSafely"));
            QTRY_VERIFY(!folder->property("sessionActive").toBool());
            QTRY_COMPARE(model->property("count").toInt(), 0);
            delete applet;
            QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
            QCoreApplication::processEvents();
            QVERIFY(guard.isNull());
        }
        QStringList captured;
        { QMutexLocker locker(&warningMutex); captured = warnings; }
        QVERIFY2(captured.isEmpty(), qPrintable(captured.join(QLatin1Char('\n'))));
    }
    void cleanupTestCase() { qInstallMessageHandler(previousHandler); }
};

int main(int argc, char **argv)
{
    const QString root = QFile::decodeName(qgetenv("PUNCHI_TEST_ENVIRONMENT_ROOT"));
    if (root.isEmpty() || !QDir(root).exists()) { return 1; }
    for (const auto &[variable, name] : QList<QPair<QByteArray, QString>>{
             {"XDG_DATA_HOME", QStringLiteral("data")}, {"XDG_CONFIG_HOME", QStringLiteral("config")},
             {"XDG_CACHE_HOME", QStringLiteral("cache")}, {"XDG_RUNTIME_DIR", QStringLiteral("runtime")}}) {
        const QString path = root + QLatin1Char('/') + name;
        if (!QDir().mkpath(path) || !QFile::setPermissions(path, QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner)) { return 1; }
        qputenv(variable.constData(), QFile::encodeName(path));
    }
    QFile plasmaConfig(root + QStringLiteral("/config/plasmarc"));
    if (!plasmaConfig.open(QIODevice::WriteOnly) || plasmaConfig.write("[Theme]\nname=default\n") <= 0) { return 1; }
    plasmaConfig.close();
    QFile kdeConfig(root + QStringLiteral("/config/kdeglobals"));
    if (!kdeConfig.open(QIODevice::WriteOnly) || kdeConfig.write("[Icons]\nTheme=breeze\n") <= 0) { return 1; }
    kdeConfig.close();
    qputenv("QT_QPA_PLATFORM", "offscreen");
    qputenv("QT_QUICK_BACKEND", "software");
    qputenv("LANGUAGE", "en");
    QGuiApplication application(argc, argv);
    FolderNavigationFullLoadTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "folder_navigation_full_load_test.moc"
