// SPDX-License-Identifier: GPL-2.0-or-later

#ifdef PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
#include <KLocalizedQmlContext>
#else
#include <KLocalizedContext>
#endif
#include <QQmlContext>
#include <QQmlEngine>
#include <QtQuickTest>

namespace {
QtMessageHandler previousMessageHandler = nullptr;

void nativePopupMessageHandler(QtMsgType type, const QMessageLogContext &context,
                               const QString &message)
{
    // The offscreen plugin cannot apply native masks, raise windows or forward
    // size hints from the real folder popup's Layout constraints. Keep
    // this exact allowlist opt-in for the native popup geometry test only.
    if (type == QtWarningMsg
        && (message == QLatin1StringView("This plugin does not support setting window masks")
            || message == QLatin1StringView("This plugin does not support raise()")
            || message == QLatin1StringView("This plugin does not support propagateSizeHints()"))) {
        return;
    }
    if (previousMessageHandler) {
        previousMessageHandler(type, context, message);
    }
}
}

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
    void allowNativePopupPlatformWarnings()
    {
        if (qEnvironmentVariableIntValue("PUNCHI_TEST_NATIVE_POPUP") == 1
            && qgetenv("QT_QPA_PLATFORM") == "offscreen") {
            const auto previous = qInstallMessageHandler(nativePopupMessageHandler);
            if (previous != nativePopupMessageHandler) {
                previousMessageHandler = previous;
            }
        }
    }

    void qmlEngineAvailable(QQmlEngine *engine)
    {
        if (qEnvironmentVariableIntValue("PUNCHI_TEST_NATIVE_POPUP") == 1) {
            engine->rootContext()->setContextProperty(
                QStringLiteral("nativePopupTestSupport"), this);
        }
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
