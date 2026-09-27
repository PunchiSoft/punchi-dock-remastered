// SPDX-License-Identifier: GPL-3.0-or-later

#include "panelrevealadapter.h"

#include <QQuickWindow>
#include <QSignalSpy>
#include <QTest>

class PanelRevealAdapterTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void defaultsAreIdle()
    {
        PanelRevealAdapter adapter;

        QCOMPARE(adapter.applet(), nullptr);
        QCOMPARE(adapter.panelWindow(), nullptr);
        QVERIFY(!adapter.requested());
        QVERIFY(!adapter.revealing());
    }

    void pendingRequestRetriesWhenDependenciesChange()
    {
        PanelRevealAdapter adapter;
        QSignalSpy requestedSpy(&adapter, &PanelRevealAdapter::requestedChanged);
        QSignalSpy revealingSpy(&adapter, &PanelRevealAdapter::revealingChanged);

        adapter.setRequested(true);
        QVERIFY(adapter.requested());
        QVERIFY(!adapter.revealing());
        QCOMPARE(requestedSpy.count(), 1);
        QCOMPARE(revealingSpy.count(), 0);

        QQuickWindow panelWindow;
        panelWindow.setProperty("visibilityMode", 1);
        adapter.setPanelWindow(&panelWindow);
        QCOMPARE(adapter.panelWindow(), &panelWindow);
        QVERIFY(!adapter.revealing());

        QObject nonApplet;
        adapter.setApplet(&nonApplet);
        QCOMPARE(adapter.applet(), &nonApplet);
        QVERIFY(!adapter.revealing());

        adapter.setRequested(false);
        QVERIFY(!adapter.requested());
        QCOMPARE(requestedSpy.count(), 2);
        QCOMPARE(revealingSpy.count(), 0);
    }

    void dependencyChangesAreIdempotentWhenIdle()
    {
        PanelRevealAdapter adapter;
        QQuickWindow panelWindow;
        QObject nonApplet;
        QSignalSpy appletSpy(&adapter, &PanelRevealAdapter::appletChanged);
        QSignalSpy windowSpy(&adapter, &PanelRevealAdapter::panelWindowChanged);

        adapter.setApplet(&nonApplet);
        adapter.setApplet(&nonApplet);
        adapter.setPanelWindow(&panelWindow);
        adapter.setPanelWindow(&panelWindow);

        QCOMPARE(appletSpy.count(), 1);
        QCOMPARE(windowSpy.count(), 1);
        QVERIFY(!adapter.revealing());

        adapter.setApplet(nullptr);
        adapter.setPanelWindow(nullptr);
        QCOMPARE(appletSpy.count(), 2);
        QCOMPARE(windowSpy.count(), 2);
    }
};

QTEST_MAIN(PanelRevealAdapterTest)

#include "panelrevealadapter_test.moc"
