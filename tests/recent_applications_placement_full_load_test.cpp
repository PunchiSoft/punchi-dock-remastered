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
#include <QKeyEvent>
#include <QMutex>
#include <QMutexLocker>
#include <QPointer>
#include <QProcess>
#include <QQuickItem>
#include <QQuickWindow>
#include <QStandardItemModel>
#include <QStandardPaths>
#include <QStyleHints>
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
KConfigGroup storedGroup(KConfig *config, const KConfigGroup &source)
{
    const auto parent = source.parent();
    if (parent.name() == QLatin1String("<default>")) { return config->group(source.name()); }
    return storedGroup(config, parent).group(source.name());
}
}

class RecentApplicationsPlacementFullLoadTest : public QObject {
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
        for (int i = 1; i <= 6; ++i) {
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
    void placementAndContainerDragAcrossOrientations_data()
    {
        QTest::addColumn<uint>("id");
        QTest::newRow("horizontal-panel") << 4201U;
        QTest::newRow("vertical-panel") << 4202U;
        QTest::newRow("horizontal-floating") << 4203U;
        QTest::newRow("vertical-floating") << 4204U;
        QTest::newRow("horizontal-panel-media") << 4205U;
        QTest::newRow("vertical-panel-media") << 4206U;
        QTest::newRow("horizontal-floating-media") << 4207U;
        QTest::newRow("vertical-floating-media") << 4208U;
    }
    void placementAndContainerDragAcrossOrientations()
    {
        QFETCH(uint, id);
        {
            const bool vertical = id % 2 == 0;
            const bool withMedia = id >= 4205U;
            const bool floating = (withMedia ? id - 4 : id) >= 4203U;
            TestCorona corona;
            auto shell = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/Shell"));
            shell.setPath(QStringLiteral("org.kde.plasma.desktop"));
            QVERIFY(shell.isValid());
            corona.setKPackage(shell);
            auto *containment = corona.createContainment(QStringLiteral("null"));
            QVERIFY(containment);
            containment->setFormFactor(floating ? Plasma::Types::Planar
                : vertical ? Plasma::Types::Vertical : Plasma::Types::Horizontal);
            containment->setLocation(vertical ? Plasma::Types::LeftEdge : Plasma::Types::BottomEdge);
            auto *applet = Plasma::PluginLoader::self()->loadApplet(QStringLiteral("org.kde.plasma.punchi-dock-remastered"), id);
            QVERIFY(applet);
            QPointer<Plasma::Applet> guard(applet);
            containment->addApplet(applet);
            QVERIFY(applet->launchErrorMessage().isEmpty());
            auto *config = applet->configuration();
            const QString base = QStringLiteral("[{\"type\":\"app\",\"name\":\"Pinned Fixture\",\"icon\":\"system-run\",\"storageId\":\"org.example.Recent1.desktop\"},{\"type\":\"dynamic-applications\",\"name\":\"Open applications\"},{\"type\":\"trash\",\"name\":\"Trash\"}]");
            const QString fixture = withMedia
                ? QString(base).replace(QStringLiteral("{\"type\":\"trash\",\"name\":\"Trash\"}"),
                    QStringLiteral("{\"type\":\"media\",\"name\":\"Media\"}"))
                : base;
            config->insert(QStringLiteral("dockItemsJson"), fixture);
            config->insert(QStringLiteral("floatingDockOrientation"), vertical ? QStringLiteral("vertical") : QStringLiteral("horizontal"));
            auto *item = PlasmaQuick::AppletQuickItem::itemForApplet(applet);
            QVERIFY(item);
            QQuickWindow window;
            item->setParentItem(window.contentItem());
            item->setWidth(vertical ? 120 : 900);
            item->setHeight(vertical ? 900 : 120);
            window.resize(vertical ? 120 : 900, vertical ? 900 : 120);
            window.show();
            item->setExpanded(true);
            QTRY_VERIFY(item->fullRepresentationItem());
            QObject *root = item->objectName() == QLatin1String("punchiDockRoot")
                ? item : item->findChild<QObject *>(QStringLiteral("punchiDockRoot"));
            QVERIFY(root);
            QCOMPARE(root->property("inPanel").toBool(), !floating);
            QCOMPARE(root->property("floatingVertical").toBool(), floating && vertical);
            QTRY_COMPARE(root->property("recentApplicationsMarkerIndex").toInt(), 3);
            auto *controller = root->findChild<QObject *>(QStringLiteral("dockItemsController"));
            QVERIFY(controller);
            QTRY_VERIFY(root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory")));
            auto *history = root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory"));
            QTest::qWait(50);
            QStandardItemModel provider;
            provider.setItemRoleNames({{Qt::UserRole, "resource"}});
            for (int i = 1; i <= 6; ++i) {
                auto *row = new QStandardItem;
                row->setData(QStringLiteral("applications:org.example.Recent%1.desktop").arg(i), Qt::UserRole);
                provider.appendRow(row);
            }
            QVERIFY(history->setProperty("sourceModel", QVariant::fromValue<QAbstractItemModel *>(&provider)));
            QTRY_COMPARE(root->property("visibleRecentApplicationCount").toInt(), 5);
            auto *container = findVisual(item->fullRepresentationItem(), QStringLiteral("recentApplicationsContainer"));
            QVERIFY(container);
            QVERIFY(container->property("persistentReorderEnabled").toBool());
            auto move = [&](int source, int target) {
                const QJSValue items = controller->property("dockItems").value<QJSValue>();
                QVariant expected;
                if (!QMetaObject::invokeMethod(controller, "canonicalJsonText", Q_RETURN_ARG(QVariant, expected),
                        Q_ARG(QVariant, QVariant::fromValue(items.property(source))))) {
                    return false;
                }
                QVariant result;
                const bool invoked = QMetaObject::invokeMethod(controller, "movePersistentItem", Q_RETURN_ARG(QVariant, result),
                    Q_ARG(QVariant, source), Q_ARG(QVariant, target), Q_ARG(QVariant, expected));
                return invoked && result.toBool();
            };
            QVERIFY(move(3, 0));
            QTRY_COMPARE(root->property("recentApplicationsMarkerIndex").toInt(), 0);
            QTRY_VERIFY(!root->property("recentSeparatorVisible").toBool());
            QVariant recentStart;
            QVERIFY(QMetaObject::invokeMethod(root, "recentVisualIndex", Q_RETURN_ARG(QVariant, recentStart), Q_ARG(QVariant, 0)));
            QCOMPARE(recentStart.toInt(), 0);
            QVERIFY(move(0, 2));
            QTRY_COMPARE(root->property("recentApplicationsMarkerIndex").toInt(), 2);
            QTRY_VERIFY(root->property("recentSeparatorVisible").toBool());
            auto *separator = findVisual(item->fullRepresentationItem(), QStringLiteral("recentApplicationsSeparator"));
            QVERIFY(separator);
            QVERIFY(separator->isVisible());
            const int slotsWithSeparator = root->property("recentPresentationItems").value<QJSValue>().property(QStringLiteral("length")).toInt();
            config->insert(QStringLiteral("recentApplicationsShowSeparator"), false);
            QTRY_VERIFY(!root->property("recentSeparatorVisible").toBool());
            QTRY_VERIFY(!separator->isVisible());
            QCOMPARE(root->property("recentPresentationItems").value<QJSValue>().property(QStringLiteral("length")).toInt(), slotsWithSeparator - 1);
            config->insert(QStringLiteral("recentApplicationsMode"), QStringLiteral("inline"));
            config->insert(QStringLiteral("recentApplicationsShowSeparator"), true);
            QTRY_VERIFY(root->property("recentSeparatorVisible").toBool());
            QTRY_VERIFY(separator->isVisible());
            config->insert(QStringLiteral("recentApplicationsSeparatorAppearanceSource"), QStringLiteral("item"));
            config->insert(QStringLiteral("recentApplicationsSeparatorStyle"), QStringLiteral("diamond"));
            config->insert(QStringLiteral("recentApplicationsSeparatorThickness"), 7);
            config->insert(QStringLiteral("recentApplicationsSeparatorLengthRatio"), 0.85);
            config->insert(QStringLiteral("recentApplicationsSeparatorOpacity"), 0.65);
            config->insert(QStringLiteral("recentApplicationsSeparatorGlowEnabled"), true);
            QTRY_COMPARE(separator->property("separatorAppearanceSourceSetting").toString(), QStringLiteral("item"));
            QTRY_COMPARE(separator->property("separatorStyleSetting").toString(), QStringLiteral("diamond"));
            QTRY_COMPARE(separator->property("separatorThicknessSetting").toInt(), 7);
            QTRY_COMPARE(separator->property("separatorLengthRatioSetting").toDouble(), 0.85);
            QTRY_COMPARE(separator->property("separatorOpacitySetting").toDouble(), 0.65);
            QTRY_VERIFY(separator->property("separatorGlowSetting").toBool());
            QPointer<QObject> previousHistory(history);
            config->insert(QStringLiteral("showRecentApplications"), false);
            QTRY_VERIFY(!separator->isVisible());
            QTRY_VERIFY(previousHistory.isNull());
            QTRY_COMPARE(root->property("recentApplicationsMarkerIndex").toInt(), -1);
            config->insert(QStringLiteral("showRecentApplications"), true);
            QTRY_COMPARE(root->property("recentApplicationsMarkerIndex").toInt(), 2);
            QTRY_VERIFY(root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory")));
            history = root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory"));
            QVERIFY(history->setProperty("sourceModel", QVariant::fromValue<QAbstractItemModel *>(&provider)));
            QTRY_COMPARE(root->property("visibleRecentApplicationCount").toInt(), 5);
            QTRY_VERIFY(separator->isVisible());
            QCOMPARE(separator->property("separatorStyleSetting").toString(), QStringLiteral("diamond"));
            config->insert(QStringLiteral("recentApplicationsMode"), QStringLiteral("container"));
            config->insert(QStringLiteral("recentApplicationsShowSeparator"), false);
            // The configuration adapter is the same immediate writer used by
            // both recent context menus.
            QObject *configState = separator->property("configState").value<QObject *>();
            QVERIFY(configState);
            QVariant toggled;
            QVERIFY(QMetaObject::invokeMethod(configState, "setRecentApplicationsSeparatorVisible",
                Q_RETURN_ARG(QVariant, toggled), Q_ARG(QVariant, true)));
            QVERIFY(toggled.toBool());
            QTRY_VERIFY(separator->isVisible());
            // The ordinary container gesture emits the same signals as other
            // persistent dock items, carrying the virtual marker's model index.
            config->insert(QStringLiteral("enableFloatingItemDragReordering"), true);
            QVERIFY(QMetaObject::invokeMethod(container, "persistentKeyboardMoveRequested",
                Q_ARG(int, 2), Q_ARG(int, 1)));
            QTRY_COMPARE(root->property("recentApplicationsMarkerIndex").toInt(), 3);
            QVERIFY(QMetaObject::invokeMethod(container, "persistentReorderStarted",
                Q_ARG(int, 3), Q_ARG(QVariant, QVariant::fromValue<QObject *>(container))));
            QVERIFY(QMetaObject::invokeMethod(container, "persistentReorderMoved", Q_ARG(qreal, -10000), Q_ARG(qreal, -10000)));
            QVERIFY(QMetaObject::invokeMethod(container, "persistentReorderFinished"));
            QTRY_VERIFY(root->property("recentApplicationsMarkerIndex").toInt() < 3);
            // Exercise MouseArea, including the source-state binding that
            // direct signal invocation cannot validate.
            QVERIFY(move(root->property("recentApplicationsMarkerIndex").toInt(), 3));
            QTRY_COMPARE(root->property("recentApplicationsMarkerIndex").toInt(), 3);
            QTest::qWait(100);
            QPoint pressPoint = container->mapToScene(
                QPointF(container->width() / 2, container->height() / 2)).toPoint();
            QTest::mouseMove(&window, pressPoint);
            QTest::qWait(250);
            pressPoint = container->mapToScene(
                QPointF(container->width() / 2, container->height() / 2)).toPoint();
            QTest::mouseMove(&window, pressPoint);
            QTest::mousePress(&window, Qt::LeftButton, Qt::NoModifier, pressPoint);
            QVERIFY(window.mouseGrabberItem());
            QCOMPARE(window.mouseGrabberItem()->parentItem(), container);
            QTest::qWait(QGuiApplication::styleHints()->mousePressAndHoldInterval() + 100);
            QTRY_VERIFY(container->property("persistentReorderSource").toBool());
            QVERIFY(container->property("persistentReorderActive").toBool());
            QVERIFY(!container->property("showAnyTooltip").toBool());
            auto *layout = container->property("layoutController").value<QObject *>();
            QVERIFY(layout);
            QCOMPARE(layout->property("persistentDragIconName").toString(),
                container->property("iconName").toString());
            const QPointF initialPointer = layout->property("persistentDragPointerPosition").toPointF();
            QVERIFY(initialPointer != QPointF());
            const QPoint dropPoint = container->mapToScene(vertical
                ? QPointF(container->width() / 2, -container->y() + 1)
                : QPointF(-container->x() + 1, container->height() / 2)).toPoint();
            QTest::mouseMove(&window, dropPoint);
            QTRY_COMPARE(layout->property("persistentDragTargetIndex").toInt(), 0);
            QVERIFY(layout->property("persistentDragPointerPosition").toPointF() != initialPointer);
            QTest::mouseRelease(&window, Qt::LeftButton, Qt::NoModifier, dropPoint);
            QTRY_VERIFY(!container->property("persistentReorderActive").toBool());
            QVERIFY(!container->property("persistentReorderSource").toBool());
            QTRY_COMPARE(root->property("recentApplicationsMarkerIndex").toInt(), 0);
            const int position = root->property("recentApplicationsMarkerIndex").toInt();
            const QString memory = config->value(QStringLiteral("recentApplicationsPosition")).toString();
            QVERIFY(!memory.isEmpty());
            config->insert(QStringLiteral("recentApplicationsMode"), QStringLiteral("inline"));
            QTRY_VERIFY(!root->property("recentContainerVisible").toBool());
            QCOMPARE(root->property("recentApplicationsMarkerIndex").toInt(), position);
            auto *icon = findVisual(item->fullRepresentationItem(), QStringLiteral("recentApplication-0"));
            QVERIFY(icon);
            QVERIFY(!icon->property("persistentReorderEnabled").toBool());
            provider.clear();
            QTRY_COMPARE(root->property("visibleRecentApplicationCount").toInt(), 0);
            QVERIFY(!root->property("recentSeparatorVisible").toBool());
            QCOMPARE(root->property("recentApplicationsMarkerIndex").toInt(), position);
            config->insert(QStringLiteral("showRecentApplications"), false);
            QTRY_COMPARE(root->property("recentApplicationsMarkerIndex").toInt(), -1);
            QCOMPARE(config->value(QStringLiteral("recentApplicationsPosition")).toString(), memory);
            QCOMPARE(config->value(QStringLiteral("dockItemsJson")).toString(), fixture);
            config->writeConfig();
            delete applet;
            QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
            QCoreApplication::processEvents();
            QVERIFY(guard.isNull());
            auto *saved = Plasma::PluginLoader::self()->loadApplet(QStringLiteral("org.kde.plasma.punchi-dock-remastered"), id);
            QVERIFY(saved);
            containment->addApplet(saved);
            QCOMPARE(saved->configuration()->value(QStringLiteral("recentApplicationsPosition")).toString(), memory);
            auto *savedItem = PlasmaQuick::AppletQuickItem::itemForApplet(saved);
            QVERIFY(savedItem);
            savedItem->setParentItem(window.contentItem());
            savedItem->setExpanded(true);
            QTRY_VERIFY(savedItem->fullRepresentationItem());
            QObject *savedRoot = savedItem->objectName() == QLatin1String("punchiDockRoot")
                ? savedItem : savedItem->findChild<QObject *>(QStringLiteral("punchiDockRoot"));
            QVERIFY(savedRoot);
            QCOMPARE(savedRoot->property("recentApplicationsMarkerIndex").toInt(), -1);
            saved->configuration()->insert(QStringLiteral("showRecentApplications"), true);
            QTRY_COMPARE(savedRoot->property("recentApplicationsMarkerIndex").toInt(), position);
            delete saved;
            QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
            QCoreApplication::processEvents();
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
    // KIO includes the application name in Unix socket paths. Keep the name
    // short enough for the parent-owned runtime directory and its socket suffix.
    QCoreApplication::setApplicationName(QStringLiteral("punchi-recent-placement"));
    RecentApplicationsPlacementFullLoadTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "recent_applications_placement_full_load_test.moc"
