// SPDX-License-Identifier: GPL-3.0-or-later

#ifdef PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
#include <KLocalizedQmlContext>
#else
#include <KLocalizedContext>
#endif
#include <Plasma/Applet>
#include <Plasma/PluginLoader>
#include <Plasma/Containment>
#include <Plasma/Corona>
#include <PlasmaQuick/AppletQuickItem>
#include <KPackage/PackageLoader>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QPointer>
#include <QQmlContext>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickItem>
#include <QtQuickTest>
#include <memory>
#include <vector>

namespace {
QtMessageHandler previousMessageHandler = nullptr;
void offscreenPlatformMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &message)
{
    // The offscreen backend has no KWindowSystem platform integration.
    // Match the exact environment limitation used by the full-load tests.
    if (type == QtWarningMsg && QByteArray(context.category) == "kf.windowsystem"
        && message == QLatin1String("Could not find any platform plugin")) { return; }
    if (previousMessageHandler) { previousMessageHandler(type, context, message); }
}
}

class FixtureCorona : public Plasma::Corona
{
public:
    int numScreens() const override { return 1; }
    QRect screenGeometry(int screen) const override { return screen == 0 ? QRect(0, 0, 1920, 1080) : QRect(); }
};

class RecentGeneralTestSupport : public QObject
{
    Q_OBJECT
public:
    RecentGeneralTestSupport()
    {
        auto shell = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/Shell"));
        shell.setPath(QStringLiteral("org.kde.plasma.desktop"));
        corona.setKPackage(shell);
        containment = corona.createContainment(QStringLiteral("null"));
    }
    Q_INVOKABLE QQuickItem *createPage(QQuickItem *parent)
    {
        if (qgetenv("QT_QPA_PLATFORM") == "offscreen") {
            const auto previous = qInstallMessageHandler(offscreenPlatformMessageHandler);
            if (previous != offscreenPlatformMessageHandler) { previousMessageHandler = previous; }
        }
        auto fixture = std::make_unique<Fixture>();
        fixture->applet.reset(Plasma::PluginLoader::self()->loadApplet(
            QStringLiteral("org.example.punchi.recent-config-fixture")));
        if (!fixture->applet || !containment) {
            qWarning("Could not create the isolated configuration applet");
            return nullptr;
        }
        containment->addApplet(fixture->applet.get());
        auto *item = PlasmaQuick::AppletQuickItem::itemForApplet(fixture->applet.get());
        if (!item) { return nullptr; }
        QQmlComponent component(qmlEngine(item), QUrl::fromLocalFile(QStringLiteral(PUNCHI_PROJECT_SOURCE_DIR)
            + QStringLiteral("/contents/ui/config/ConfigGeneral.qml")));
        auto *page = qobject_cast<QQuickItem *>(component.create(qmlContext(item)));
        if (!page) {
            qWarning("Could not instantiate the real General configuration page");
            return nullptr;
        }
        page->setParentItem(parent);
        QQmlEngine::setObjectOwnership(page, QQmlEngine::CppOwnership);
        page->setWidth(650);
        page->setHeight(760);
        fixture->page = page;
        fixtures.push_back(std::move(fixture));
        return page;
    }

    Q_INVOKABLE void destroyPage(QQuickItem *page)
    {
        for (auto iterator = fixtures.begin(); iterator != fixtures.end(); ++iterator) {
            if ((*iterator)->page == page) {
                fixtures.erase(iterator);
                return;
            }
        }
        qWarning("The requested configuration page is not owned by this fixture");
    }

    Q_INVOKABLE bool isSwitch(QObject *control) const
    {
        return control && control->inherits("QQuickSwitch");
    }

public Q_SLOTS:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
#ifdef PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
        auto *context = KLocalization::setupLocalizedContext(engine);
#else
        auto *context = new KLocalizedContext(engine);
        engine->rootContext()->setContextObject(context);
#endif
        context->setTranslationDomain(QStringLiteral("plasma_applet_org.kde.plasma.punchi-dock-remastered"));
        engine->rootContext()->setContextProperty(QStringLiteral("recentGeneralTestSupport"), this);
    }

private:
    struct Fixture {
        std::unique_ptr<Plasma::Applet> applet;
        QPointer<QQuickItem> page;
        ~Fixture() { delete page; }
    };
    FixtureCorona corona;
    Plasma::Containment *containment = nullptr;
    std::vector<std::unique_ptr<Fixture>> fixtures;
};

int main(int argc, char **argv)
{
    // The existing parent wrapper owns this directory until Qt has shut down.
    const QString root = QFile::decodeName(qgetenv("PUNCHI_TEST_ENVIRONMENT_ROOT"));
    if (root.isEmpty() || !QDir(root).exists()) {
        qCritical("A parent-owned isolated environment is required");
        return 1;
    }
    for (const auto &entry : {std::pair{"XDG_CONFIG_HOME", "config"},
             std::pair{"XDG_CACHE_HOME", "cache"}, std::pair{"XDG_DATA_HOME", "data"},
             std::pair{"XDG_CONFIG_DIRS", "system-config"}}) {
        const QString path = root + QLatin1Char('/') + QString::fromLatin1(entry.second);
        if (!QDir().mkpath(path)) { return 1; }
        qputenv(entry.first, QFile::encodeName(path));
    }
    const QString package = root + QStringLiteral("/data/plasma/plasmoids/org.example.punchi.recent-config-fixture");
    if (!QDir().mkpath(package + QStringLiteral("/contents/config"))
        || !QDir().mkpath(package + QStringLiteral("/contents/ui"))) { return 1; }
    if (!QFile::copy(QStringLiteral(PUNCHI_PROJECT_SOURCE_DIR) + QStringLiteral("/contents/config/main.xml"),
            package + QStringLiteral("/contents/config/main.xml"))) { return 1; }
    QFile metadata(package + QStringLiteral("/metadata.json"));
    if (!metadata.open(QIODevice::WriteOnly)) { return 1; }
    metadata.write(R"({"KPlugin":{"Id":"org.example.punchi.recent-config-fixture","Name":"Recent Configuration Fixture"},"KPackageStructure":"Plasma/Applet","X-Plasma-API-Minimum-Version":"6.0"})");
    metadata.close();
    QFile mainFile(package + QStringLiteral("/contents/ui/main.qml"));
    if (!mainFile.open(QIODevice::WriteOnly)) { return 1; }
    mainFile.write("import org.kde.plasma.plasmoid\nPlasmoidItem {}\n");
    mainFile.close();
    QGuiApplication application(argc, argv);
    RecentGeneralTestSupport support;
    return quick_test_main_with_setup(argc, argv, "punchi_recent_general", nullptr, &support);
}

#include "recent_general_qml_test_runner.moc"
