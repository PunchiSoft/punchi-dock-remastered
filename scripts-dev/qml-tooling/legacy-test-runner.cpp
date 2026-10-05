// SPDX-License-Identifier: GPL-3.0-or-later

// Reuse the existing setup verbatim, including its warning policy and ki18n.
#define main punchiOriginalRunnerMain
#include PUNCHI_ORIGINAL_RUNNER
#undef main

#include <QApplication>
#include <QDir>
#include <KPluginMetaData>
#include <KConfigGroup>
#include <Plasma/Applet>
#include <PlasmaQuick/AppletQuickItem>
#include <memory>

class LegacyPlasmoidTestSetup : public PUNCHI_SETUP_CLASS
{
    Q_OBJECT
public Q_SLOTS:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        // Plasma 6.3 registers the actual module before checking destroyed().
        // No replacement QML types or dock UI are loaded here.
        if (qmlTypeId("org.kde.plasma.plasmoid", 2, 0, "PlasmoidItem") < 0) {
            auto applet = std::make_unique<Plasma::Applet>(nullptr, KPluginMetaData(), QVariantList{});
            applet->config();
            applet->destroy();
            PlasmaQuick::AppletQuickItem::itemForApplet(applet.get());
        }
        PUNCHI_SETUP_CLASS::qmlEngineAvailable(engine);
    }
};

int main(int argc, char **argv)
{
    // The parent wrapper owns this directory until the process has fully exited.
    const auto configuration = qgetenv("PUNCHI_LEGACY_CONFIG_ROOT");
    if (configuration.isEmpty() || qgetenv("XDG_CONFIG_HOME") != configuration
        || !QDir(QString::fromLocal8Bit(configuration)).exists()) {
        return 2;
    }
    QApplication application(argc, argv);
    LegacyPlasmoidTestSetup setup;
    return quick_test_main_with_setup(argc, argv, PUNCHI_TEST_NAME, nullptr, &setup);
}

#include "legacy-test-runner.moc"
