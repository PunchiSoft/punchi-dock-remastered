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

}

class RecentApplicationsCountFullLoadTest : public QObject {
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
        for (int i = 1; i <= 8; ++i) {
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
    void quantityHotRefreshPopupPersistenceAndReload()
    {
        for (uint id : {2401U, 2402U}) {
            TestCorona corona;
            auto shell = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/Shell"));
            shell.setPath(QStringLiteral("org.kde.plasma.desktop"));
            QVERIFY(shell.isValid()); corona.setKPackage(shell);
            auto *containment = corona.createContainment(QStringLiteral("null"));
            QVERIFY(containment);
            const bool vertical = id == 2402U;
            containment->setFormFactor(vertical ? Plasma::Types::Vertical : Plasma::Types::Horizontal);
            containment->setLocation(vertical ? Plasma::Types::LeftEdge : Plasma::Types::BottomEdge);
            auto *applet = Plasma::PluginLoader::self()->loadApplet(QStringLiteral("org.kde.plasma.punchi-dock-remastered"), id);
            QVERIFY(applet); containment->addApplet(applet);
            QVERIFY(applet->launchErrorMessage().isEmpty());
            auto *config = applet->configuration();
            QCOMPARE(config->value(QStringLiteral("recentApplicationsCount")).toInt(), 5);
            config->insert(QStringLiteral("showActiveTasks"), false);
            config->insert(QStringLiteral("dockItemsJson"), QStringLiteral("[{\"type\":\"app\",\"name\":\"Pinned\",\"storageId\":\"org.example.Recent1.desktop\",\"icon\":\"system-run\"}]"));
            auto *item = PlasmaQuick::AppletQuickItem::itemForApplet(applet);
            QVERIFY(item); QPointer<PlasmaQuick::AppletQuickItem> guard(item);
            QQuickWindow window; window.resize(vertical ? 120 : 1000, vertical ? 1000 : 120);
            item->setWidth(window.width()); item->setHeight(window.height());
            item->setParentItem(window.contentItem()); window.show(); item->setExpanded(true);
            QTRY_VERIFY(item->fullRepresentationItem());
            auto *root = item->objectName() == QLatin1String("punchiDockRoot") ? item : item->findChild<QObject *>(QStringLiteral("punchiDockRoot"));
            QVERIFY(root);
            config->insert(QStringLiteral("showActiveTasks"), false);
            config->insert(QStringLiteral("dockItemsJson"), QStringLiteral("[{\"type\":\"app\",\"name\":\"Pinned\",\"storageId\":\"org.example.Recent1.desktop\",\"icon\":\"system-run\"}]"));
            QTRY_VERIFY(root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory")));
            auto *history = root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory"));
            // Let the isolated Activities consumer settle before injecting history.
            QTest::qWait(50);
            QStandardItemModel provider;
            provider.setItemRoleNames({{Qt::UserRole, "resource"}});
            for (int i = 1; i <= 8; ++i) {
                auto *row = new QStandardItem;
                row->setData(QStringLiteral("applications:org.example.Recent%1.desktop").arg(i), Qt::UserRole);
                provider.appendRow(row);
            }
            QVERIFY(history->setProperty("sourceModel", QVariant::fromValue<QAbstractItemModel *>(&provider)));
            auto *selection = root->findChild<QAbstractItemModel *>(QStringLiteral("recentApplicationsSelection"));
            QVERIFY(selection);
            QTRY_COMPARE(selection->rowCount(), 5);
            config->insert(QStringLiteral("recentApplicationsCount"), 6);
            QTRY_COMPARE(selection->rowCount(), 6);
            QTRY_COMPARE(root->property("visibleRecentApplicationCount").toInt(), 6);
            QCOMPARE(objectMap(root->property("recentContainerDescriptor")).value(QStringLiteral("apps")).toList().size(), 6);
            config->insert(QStringLiteral("recentApplicationsMode"), QStringLiteral("inline"));
            config->insert(QStringLiteral("recentApplicationsCount"), 7);
            QTRY_COMPARE(root->property("visibleRecentApplicationCount").toInt(), 7);
            QVERIFY(findVisual(item->fullRepresentationItem(), QStringLiteral("recentApplication-6")));
            config->insert(QStringLiteral("recentApplicationsCount"), 1);
            QTRY_COMPARE(root->property("visibleRecentApplicationCount").toInt(), 1);
            config->insert(QStringLiteral("recentApplicationsMode"), QStringLiteral("container"));
            QTRY_VERIFY(root->property("recentContainerVisible").toBool());
            auto *container = findVisual(item->fullRepresentationItem(), QStringLiteral("recentApplicationsContainer"));
            QVERIFY(container);
            QTRY_VERIFY(container->isVisible());
            QTest::qWait(20);
            QVERIFY(QMetaObject::invokeMethod(container, "itemClicked", Q_ARG(QString, QString())));
            auto *coordinator = findVisual(item->fullRepresentationItem(), QStringLiteral("popupCoordinator"));
            QVERIFY(coordinator);
            const auto toObject = [](const QVariant &value) { return value.canConvert<QJSValue>() ? value.value<QJSValue>().toQObject() : value.value<QObject *>(); };
            auto *dialog = toObject(coordinator->property("folderPopupDialogRef"));
            QVERIFY(dialog); QTRY_VERIFY(dialog->property("visible").toBool());
            auto *folder = dialog->findChild<QObject *>(QStringLiteral("folderPopupContent"));
            QVERIFY(folder);
            for (const QString &layout : {QStringLiteral("grid"), QStringLiteral("list"), QStringLiteral("detailed"), QStringLiteral("fan")}) {
                config->insert(QStringLiteral("recentApplicationsContainerLayout"), layout);
                QTRY_COMPARE(folder->property("layoutMode").toString(), layout);
                config->insert(QStringLiteral("recentApplicationsCount"), 2);
                QTRY_COMPARE(selection->rowCount(), 2);
                QTRY_COMPARE(folder->property("itemCount").toInt(), 2);
                config->insert(QStringLiteral("recentApplicationsCount"), 7);
                QTRY_COMPARE(folder->property("itemCount").toInt(), 7);
                if (layout == QLatin1String("fan")) {
                    config->insert(QStringLiteral("folderFanScrollEnabled"), false);
                    auto *fan = folder->findChild<QObject *>(QStringLiteral("folderFanView"));
                    QVERIFY(fan);
                    QVERIFY(fan->property("effectiveScrollEnabled").toBool());
                    QTRY_COMPARE(fan->property("displayedItemCount").toInt(), 7);
                }
            }
            QVERIFY(QMetaObject::invokeMethod(dialog, "closeSafely"));
            config->writeConfig();
            delete applet;
            QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
            QCoreApplication::processEvents(); QVERIFY(guard.isNull());
            auto *saved = Plasma::PluginLoader::self()->loadApplet(QStringLiteral("org.kde.plasma.punchi-dock-remastered"), id);
            QVERIFY(saved); containment->addApplet(saved);
            QCOMPARE(saved->configuration()->value(QStringLiteral("recentApplicationsCount")).toInt(), 7);
            auto *savedItem = PlasmaQuick::AppletQuickItem::itemForApplet(saved);
            QVERIFY(savedItem); QPointer<PlasmaQuick::AppletQuickItem> savedGuard(savedItem);
            savedItem->setParentItem(window.contentItem()); savedItem->setExpanded(true);
            QTRY_VERIFY(savedItem->fullRepresentationItem());
            QTRY_VERIFY(savedItem->findChild<QObject *>(QStringLiteral("recentApplicationsSelection")));
            auto *savedSelection = savedItem->findChild<QObject *>(QStringLiteral("recentApplicationsSelection"));
            QCOMPARE(savedSelection->property("maximumItems").toInt(), 7);
            delete saved;
            QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
            QCoreApplication::processEvents(); QVERIFY(savedGuard.isNull());
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
    // KIO includes the application name in its local socket path.
    application.setApplicationName(QStringLiteral("punchi-count-test"));
    RecentApplicationsCountFullLoadTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "recent_applications_count_full_load_test.moc"
