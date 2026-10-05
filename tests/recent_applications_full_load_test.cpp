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
QObject *objectPointer(const QVariant &value)
{
    return value.canConvert<QJSValue>() ? value.value<QJSValue>().toQObject() : value.value<QObject *>();
}
KConfigGroup storedGroup(KConfig *config, const KConfigGroup &source)
{
    const auto parent = source.parent();
    if (parent.name() == QLatin1String("<default>")) { return config->group(source.name()); }
    return storedGroup(config, parent).group(source.name());
}
}

class RecentApplicationsFullLoadTest : public QObject {
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
    void hotRefreshBothPresentationsAndDestroyTwice()
    {
        for (uint id : {2101U, 2102U, 2103U, 2104U}) {
            const bool vertical = id >= 2103U;
            const auto edge = !vertical ? Plasma::Types::BottomEdge
                : id == 2103U ? Plasma::Types::LeftEdge : Plasma::Types::RightEdge;
            TestCorona corona;
            auto shell = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/Shell"));
            shell.setPath(QStringLiteral("org.kde.plasma.desktop"));
            QVERIFY(shell.isValid());
            corona.setKPackage(shell);
            auto *containment = corona.createContainment(QStringLiteral("null"));
            QVERIFY(containment);
            containment->setFormFactor(vertical ? Plasma::Types::Vertical : Plasma::Types::Horizontal);
            containment->setLocation(edge);
            auto *applet = Plasma::PluginLoader::self()->loadApplet(QStringLiteral("org.kde.plasma.punchi-dock-remastered"), id);
            QVERIFY(applet);
            QPointer<Plasma::Applet> appletGuard(applet);
            containment->addApplet(applet);
            QVERIFY(applet->launchErrorMessage().isEmpty());
            auto *config = applet->configuration();
            QVERIFY(config);
            QCOMPARE(config->value(QStringLiteral("showRecentApplications")).toBool(), true);
            QCOMPARE(config->value(QStringLiteral("recentApplicationsMode")).toString(), QStringLiteral("container"));
            QCOMPARE(config->value(QStringLiteral("recentApplicationsContainerLayout")).toString(), QStringLiteral("grid"));
            config->insert(QStringLiteral("showActiveTasks"), false);
            const QString pinned = QStringLiteral("[{\"type\":\"app\",\"name\":\"Pinned Fixture\",\"icon\":\"system-run\",\"storageId\":\"org.example.Recent1.desktop\"}]");
            config->insert(QStringLiteral("dockItemsJson"), pinned);
            auto *item = PlasmaQuick::AppletQuickItem::itemForApplet(applet);
            QVERIFY(item);
            item->setWidth(vertical ? 120 : 900);
            item->setHeight(vertical ? 900 : 120);
            QPointer<PlasmaQuick::AppletQuickItem> itemGuard(item);
            QQuickWindow window;
            item->setParentItem(window.contentItem());
            window.resize(vertical ? 120 : 900, vertical ? 900 : 120);
            window.show();
            item->setExpanded(true);
            QTRY_VERIFY(item->fullRepresentationItem());
            QObject *root = item->objectName() == QLatin1String("punchiDockRoot")
                ? item : item->findChild<QObject *>(QStringLiteral("punchiDockRoot"));
            QVERIFY(root);
            config->insert(QStringLiteral("showActiveTasks"), false);
            config->insert(QStringLiteral("dockItemsJson"), pinned);
            QCOMPARE(root->property("visibleRecentApplicationCount").toInt(), 0);
            QTRY_VERIFY(root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory")));
            config->insert(QStringLiteral("showRecentApplications"), false);
            QTRY_VERIFY(!root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory")));
            // Preserve coverage of the previous inline presentation and activation path.
            config->insert(QStringLiteral("recentApplicationsMode"), QStringLiteral("inline"));
            config->insert(QStringLiteral("showRecentApplications"), true);
            QTRY_VERIFY(root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory")));
            auto *history = root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory"));
            QTest::qWait(50);
            QStandardItemModel provider;
            provider.setItemRoleNames({{Qt::UserRole, "resource"}});
            for (int i = 1; i <= 5; ++i) {
                auto *row = new QStandardItem;
                row->setData(QStringLiteral("applications:org.example.Recent%1.desktop").arg(i), Qt::UserRole);
                provider.appendRow(row);
            }
            QVERIFY(history->setProperty("sourceModel", QVariant::fromValue<QAbstractItemModel *>(&provider)));
            auto *historyModel = qobject_cast<QAbstractItemModel *>(history);
            QVERIFY(historyModel);
            QCOMPARE(historyModel->rowCount(), 5);
            QCOMPARE(historyModel->index(1, 0).data(Qt::UserRole + 100).toString(), QStringLiteral("org.example.Recent2.desktop"));
            auto *selection = root->findChild<QAbstractItemModel *>(QStringLiteral("recentApplicationsSelection"));
            QVERIFY(selection);
            QTRY_COMPARE(selection->rowCount(), 3);
            QVERIFY2(root->property("visibleRecentApplicationCount").toInt() == 3,
                qPrintable(QStringLiteral("Presentation state: capacity=%1, controllerItems=%2")
                    .arg(root->property("recentApplicationCapacity").toInt())
                    .arg(root->property("recentApplications").value<QJSValue>().property(QStringLiteral("length")).toInt())));
            auto *representation = item->fullRepresentationItem();
            auto *recentIcon = findVisual(representation, QStringLiteral("recentApplication-0"));
            QVERIFY(recentIcon);
            const QVariantMap app = objectMap(recentIcon->property("descriptor"));
            QCOMPARE(app.value(QStringLiteral("storageId")).toString(), QStringLiteral("org.example.Recent2.desktop"));
            QVERIFY(recentIcon->property("visible").toBool());
            config->insert(QStringLiteral("recentApplicationsMode"), QStringLiteral("container"));
            QTRY_VERIFY(root->property("recentContainerVisible").toBool());
            QVERIFY(!recentIcon->property("visible").toBool());
            auto *container = findVisual(representation, QStringLiteral("recentApplicationsContainer"));
            QVERIFY(container);
            QCOMPARE(container->property("iconName").toString(), QStringLiteral("folder-temp"));
            QVERIFY(QMetaObject::invokeMethod(container, "itemClicked", Q_ARG(QString, QString())));
            QTest::qWait(20);
            provider.removeRow(1);
            QTRY_COMPARE(root->property("visibleRecentApplicationCount").toInt(), 3);
            auto *context = root->findChild<QObject *>(QStringLiteral("dockContextActionsController"));
            auto *coordinator = findVisual(representation, QStringLiteral("popupCoordinator"));
            QVERIFY(context);
            QVERIFY(coordinator);
            auto *folderDialog = objectPointer(coordinator->property("folderPopupDialogRef"));
            QVERIFY(folderDialog);
            auto *folder = folderDialog->findChild<QObject *>(QStringLiteral("folderPopupContent"));
            QVERIFY(folder);
            auto *spacing = objectPointer(folderDialog->property("popupSpacing"));
            QVERIFY(spacing);
            QVERIFY(spacing->property("preserveHorizontalAnchorCenter").toBool());
            QVERIFY(spacing->property("preserveVerticalAnchorCenter").toBool());
            auto *surface = qobject_cast<QQuickItem *>(objectPointer(spacing->property("targetSurface")));
            QVERIFY(surface);
            QVERIFY(container->property("supportsContextMenu").toBool());
            auto *input = container->nextItemInFocusChain(true);
            QVERIFY(container->isAncestorOf(input));
            // Exercise the real key handler without assuming offscreen shell focus.
            QKeyEvent menuKey(QEvent::KeyPress, Qt::Key_Menu, Qt::NoModifier);
            QCoreApplication::sendEvent(input, &menuKey);
            QVERIFY(menuKey.isAccepted());
            QTRY_COMPARE(objectMap(coordinator->property("activeAppContextMenuData"))
                .value(QStringLiteral("name")).toString(), QStringLiteral("Recent applications"));
            const auto actions = objectMap(coordinator->property("activeAppContextMenuData"))
                .value(QStringLiteral("actions")).toList();
            QVariantList views;
            QVariantMap disable;
            for (const auto &entry : actions) {
                const auto action = entry.toMap();
                if (action.value(QStringLiteral("kind")).toString() == QLatin1String("submenu")) {
                    QCOMPARE(action.value(QStringLiteral("name")).toString(), QStringLiteral("Container view"));
                    views = action.value(QStringLiteral("children")).toList();
                } else if (action.value(QStringLiteral("kind")).toString() == QLatin1String("disableRecentApplications")) {
                    disable = action;
                }
            }
            QCOMPARE(views.size(), 4);
            QVERIFY(!disable.isEmpty());
            QVERIFY(QMetaObject::invokeMethod(container, "itemClicked", Q_ARG(QString, QString())));
            for (const auto &view : views) {
                const auto action = view.toMap();
                const auto layout = action.value(QStringLiteral("layout")).toString();
                QCOMPARE(action.value(QStringLiteral("kind")).toString(), QStringLiteral("setRecentContainerView"));
                QVariant result;
                QVERIFY(QMetaObject::invokeMethod(context, "triggerAction", Q_RETURN_ARG(QVariant, result), Q_ARG(QVariant, view)));
                QVERIFY(result.toBool());
                QTRY_COMPARE(folder->property("layoutMode").toString(), layout);
                QCOMPARE(config->value(QStringLiteral("recentApplicationsContainerLayout")).toString(), layout);
                QCOMPARE(objectMap(root->property("recentContainerDescriptor")).value(QStringLiteral("layout")).toString(), layout);
                QCOMPARE(root->property("visibleRecentApplicationCount").toInt(), 3);
                QCOMPARE(config->value(QStringLiteral("dockItemsJson")).toString(), pinned);
                KConfig stored(applet->config().config()->name(), KConfig::SimpleConfig);
                const KConfigGroup general = storedGroup(&stored, applet->config()).group(QStringLiteral("General"));
                QCOMPARE(general.readEntry(QStringLiteral("recentApplicationsContainerLayout"), QStringLiteral("grid")), layout);
            }
            if (vertical) {
                config->insert(QStringLiteral("recentApplicationsContainerLayout"), QStringLiteral("grid"));
                QTRY_VERIFY(root->property("recentContainerVisible").toBool());
                QTest::qWait(50);
                QVERIFY(QMetaObject::invokeMethod(folderDialog, "closeSafely"));
                QVERIFY(QMetaObject::invokeMethod(container, "itemClicked", Q_ARG(QString, QString())));
                QTRY_VERIFY2(folderDialog->property("visible").toBool(), qPrintable(
                    QStringLiteral("Vertical popup: edge=%1, preparing=%2, geometry=%3, anchor=%4, containerVisible=%5")
                        .arg(int(edge))
                        .arg(folderDialog->property("preparingToShow").toBool())
                        .arg(folderDialog->property("hasPositiveContentGeometry").toBool())
                        .arg(spacing->property("sourceAnchor").isNull())
                        .arg(container->isVisible())));
                QTRY_COMPARE(folderDialog->property("location").toInt(), int(edge));
                QVERIFY(spacing->property("centerVertically").toBool());
                QVERIFY(surface->property("constrainEdgeTailTip").toBool());
                QTRY_VERIFY(std::isfinite(surface->property("edgeTailTipOffset").toDouble()));
                const auto mapped = container->mapToItem(surface, QPointF(container->width() / 2, container->height() / 2));
                QVERIFY(qAbs(surface->property("edgeTailTipOffset").toDouble() - mapped.y()) < 0.1);
                QCOMPARE(config->value(QStringLiteral("dockItemsJson")).toString(), pinned);
            }
            QVERIFY(QMetaObject::invokeMethod(folderDialog, "closeSafely"));
            config->insert(QStringLiteral("recentApplicationsContainerLayout"), QStringLiteral("fan"));
            config->insert(QStringLiteral("recentApplicationsMode"), QStringLiteral("inline"));
            QTRY_VERIFY(!root->property("recentContainerVisible").toBool());
            config->insert(QStringLiteral("recentApplicationsMode"), QStringLiteral("container"));
            QTRY_VERIFY(root->property("recentContainerVisible").toBool());
            QVERIFY(QMetaObject::invokeMethod(container, "itemClicked", Q_ARG(QString, QString())));
            QVariant disabled;
            QVERIFY(QMetaObject::invokeMethod(context, "triggerAction", Q_RETURN_ARG(QVariant, disabled), Q_ARG(QVariant, QVariant(disable))));
            QVERIFY(disabled.toBool());
            QTRY_VERIFY(!folderDialog->property("visible").toBool());
            QTRY_VERIFY(!root->property("recentContainerVisible").toBool());
            QTRY_COMPARE(root->property("visibleRecentApplicationCount").toInt(), 0);
            QTRY_VERIFY(!root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory")));
            KConfig stored(applet->config().config()->name(), KConfig::SimpleConfig);
            const KConfigGroup general = storedGroup(&stored, applet->config()).group(QStringLiteral("General"));
            QVERIFY(general.hasKey(QStringLiteral("showRecentApplications")));
            QCOMPARE(general.readEntry(QStringLiteral("showRecentApplications"), true), false);
            config->insert(QStringLiteral("showRecentApplications"), false);
            QTRY_COMPARE(root->property("visibleRecentApplicationCount").toInt(), 0);
            QTRY_VERIFY(!root->findChild<QObject *>(QStringLiteral("recentApplicationsHistory")));
            QCOMPARE(config->value(QStringLiteral("dockItemsJson")).toString(), pinned);
            config->insert(QStringLiteral("recentApplicationsMode"), QStringLiteral("inline"));
            config->writeConfig();
            delete applet;
            QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
            QCoreApplication::processEvents();
            QVERIFY(appletGuard.isNull());
            QVERIFY(itemGuard.isNull());
            auto *reloaded = Plasma::PluginLoader::self()->loadApplet(QStringLiteral("org.kde.plasma.punchi-dock-remastered"), id);
            QVERIFY(reloaded);
            QPointer<Plasma::Applet> reloadedGuard(reloaded);
            containment->addApplet(reloaded);
            QVERIFY(reloaded->launchErrorMessage().isEmpty());
            auto *savedConfig = reloaded->configuration();
            QVERIFY(savedConfig);
            QCOMPARE(savedConfig->value(QStringLiteral("showRecentApplications")).toBool(), false);
            QCOMPARE(savedConfig->value(QStringLiteral("recentApplicationsMode")).toString(), QStringLiteral("inline"));
            QCOMPARE(savedConfig->value(QStringLiteral("recentApplicationsContainerLayout")).toString(), QStringLiteral("fan"));
            QCOMPARE(savedConfig->value(QStringLiteral("dockItemsJson")).toString(), pinned);
            auto *savedItem = PlasmaQuick::AppletQuickItem::itemForApplet(reloaded);
            QVERIFY(savedItem);
            QPointer<PlasmaQuick::AppletQuickItem> savedItemGuard(savedItem);
            savedItem->setParentItem(window.contentItem());
            savedItem->setExpanded(true);
            QTRY_VERIFY(savedItem->fullRepresentationItem());
            QObject *savedRoot = savedItem->objectName() == QLatin1String("punchiDockRoot")
                ? savedItem : savedItem->findChild<QObject *>(QStringLiteral("punchiDockRoot"));
            QVERIFY(savedRoot);
            QCOMPARE(savedRoot->property("recentContainerVisible").toBool(), false);
            QCOMPARE(savedRoot->property("visibleRecentApplicationCount").toInt(), 0);
            QVERIFY(!savedRoot->findChild<QObject *>(QStringLiteral("recentApplicationsHistory")));
            delete reloaded;
            QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
            QCoreApplication::processEvents();
            QVERIFY(reloadedGuard.isNull());
            QVERIFY(savedItemGuard.isNull());
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
    RecentApplicationsFullLoadTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "recent_applications_full_load_test.moc"
