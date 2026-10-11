// SPDX-License-Identifier: GPL-3.0-or-later

#ifdef PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
#include <KLocalizedQmlContext>
#else
#include <KLocalizedContext>
#endif
#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickItem>
#include <QTest>

class MediaDockItemDeferredUpdateTest : public QObject {
    Q_OBJECT
private Q_SLOTS:
    void destroyBeforeQueuedUpdate()
    {
        QTest::failOnWarning(QRegularExpression(QStringLiteral(".*")));
        QQmlEngine engine;
#ifdef PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
        auto *localizedContext = KLocalization::setupLocalizedContext(&engine);
#else
        auto *localizedContext = new KLocalizedContext(&engine);
        engine.rootContext()->setContextObject(localizedContext);
#endif
        localizedContext->setTranslationDomain(
            QStringLiteral("plasma_applet_org.kde.plasma.punchi-dock-remastered"));
        QQmlComponent component(&engine, QUrl::fromLocalFile(
            QStringLiteral(PUNCHI_PROJECT_SOURCE_DIR "/contents/ui/components/MediaDockItem.qml")));
        QVERIFY2(component.isReady(), qPrintable(component.errorString()));
        for (int cycle = 0; cycle < 12; ++cycle) {
            auto *item = qobject_cast<QQuickItem *>(component.create());
            QVERIFY2(item, qPrintable(component.errorString()));
            item->setSize(QSizeF(240, 64));
            QVERIFY(item->setProperty("defaultPlayerName", QStringLiteral("Player %1").arg(cycle)));
            // Plasma owns delegates and may destroy them synchronously before
            // the engine delivers the metadata callback queued in this turn.
            delete item;
            QCoreApplication::processEvents();
        }
        auto *recreated = component.create();
        QVERIFY(recreated);
        QCoreApplication::processEvents();
        QVERIFY(!recreated->property("metadataText").toString().isEmpty());
        delete recreated;
        QCoreApplication::processEvents();
    }
};

QTEST_MAIN(MediaDockItemDeferredUpdateTest)
#include "media_dock_item_deferred_update_test.moc"
