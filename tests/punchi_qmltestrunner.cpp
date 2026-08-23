// SPDX-License-Identifier: GPL-2.0-or-later

#ifdef PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
#include <KLocalizedQmlContext>
#else
#include <KLocalizedContext>
#endif
#include <QQmlContext>
#include <QQmlEngine>
#include <QtQuickTest>

class PunchiQmlTestSetup : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY_MOVE(PunchiQmlTestSetup)

public:
    explicit PunchiQmlTestSetup(QObject *parent = nullptr)
        : QObject(parent)
    {
    }

public Q_SLOTS:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
#ifdef PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
        auto *localizedContext = KLocalization::setupLocalizedContext(engine);
#else
        auto *localizedContext = new KLocalizedContext(engine);
#endif
        localizedContext->setTranslationDomain(
            QStringLiteral("plasma_applet_org.kde.plasma.punchi-dock-remastered"));
#ifndef PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
        engine->rootContext()->setContextObject(localizedContext);
#endif
    }
};

QUICK_TEST_MAIN_WITH_SETUP(punchi_qmltests, PunchiQmlTestSetup)

#include "punchi_qmltestrunner.moc"
