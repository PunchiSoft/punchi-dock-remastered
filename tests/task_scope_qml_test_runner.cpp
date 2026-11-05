#ifdef PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
#include <KLocalizedQmlContext>
#else
#include <KLocalizedContext>
#endif
#include <QDBusConnection>
#include <QQmlContext>
#include <QQmlEngine>
#include <QtQuickTest>

class VirtualDesktopManagerFixture : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.KWin.VirtualDesktopManager")
    Q_PROPERTY(bool navigationWrappingAround READ navigationWrappingAround CONSTANT)

public:
    bool navigationWrappingAround() const
    {
        return false;
    }
};

class TaskScopeTestSetup : public QObject
{
    Q_OBJECT

public Q_SLOTS:
    void applicationAvailable()
    {
        auto bus = QDBusConnection::sessionBus();
        if (!bus.registerService(QStringLiteral("org.kde.KWin"))
            || !bus.registerObject(QStringLiteral("/VirtualDesktopManager"), &m_desktops,
                                   QDBusConnection::ExportAllProperties)) {
            qFatal("Could not register the isolated virtual desktop manager fixture");
        }
    }

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

private:
    VirtualDesktopManagerFixture m_desktops;
};

QUICK_TEST_MAIN_WITH_SETUP(task_scope_tests, TaskScopeTestSetup)

#include "task_scope_qml_test_runner.moc"
