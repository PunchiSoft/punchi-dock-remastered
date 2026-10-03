// SPDX-License-Identifier: GPL-2.0-or-later

#ifdef PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
#include <KLocalizedQmlContext>
#else
#include <KLocalizedContext>
#endif
#include <QApplication>
#include <QQmlContext>
#include <QQmlEngine>
#include <QtQuickTest>

// ConfigItems instantiates the QWidget-backed icon picker even when it is closed.
class ConfigItemsTestSetup : public QObject
{
    Q_OBJECT

public Q_SLOTS:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
#ifdef PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
        auto *context = KLocalization::setupLocalizedContext(engine);
#else
        auto *context = new KLocalizedContext(engine);
        engine->rootContext()->setContextObject(context);
#endif
        context->setTranslationDomain(
            QStringLiteral("plasma_applet_org.kde.plasma.punchi-dock-remastered"));
    }
};

int main(int argc, char **argv)
{
    QApplication application(argc, argv);
    ConfigItemsTestSetup setup;
    return quick_test_main_with_setup(argc, argv, "punchi_config_tests", nullptr, &setup);
}

#include "config_items_qml_test_runner.moc"
