// SPDX-License-Identifier: GPL-3.0-or-later

#include "panelinputregionsynchronizer.h"

#include <QQuickWindow>
#include <QTest>

class PanelInputRegionSynchronizerTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void expandsHorizontalMaskAfterWindowResize()
    {
        QQuickWindow window;
        window.resize(320, 64);
        window.setMask(QRegion(QRect(0, 12, 320, 52)));

        PanelInputRegionSynchronizer synchronizer;
        synchronizer.setPanelWindow(&window);
        synchronizer.setEnabled(true);
        QTRY_COMPARE(window.mask().boundingRect(), QRect(0, 12, 320, 52));

        window.resize(760, 64);
        QTRY_COMPARE(window.mask().boundingRect(), QRect(0, 12, 760, 52));
    }

    void expandsVerticalMaskAfterWindowResize()
    {
        QQuickWindow window;
        window.resize(72, 280);
        window.setMask(QRegion(QRect(10, 0, 62, 280)));

        PanelInputRegionSynchronizer synchronizer;
        synchronizer.setVerticalPanel(true);
        synchronizer.setPanelWindow(&window);
        synchronizer.setEnabled(true);
        QTRY_COMPARE(window.mask().boundingRect(), QRect(10, 0, 62, 280));

        window.resize(72, 680);
        QTRY_COMPARE(window.mask().boundingRect(), QRect(10, 0, 62, 680));
    }

    void preservesEmptyAndComplexMasks()
    {
        QQuickWindow emptyWindow;
        emptyWindow.resize(320, 64);

        PanelInputRegionSynchronizer emptySynchronizer;
        emptySynchronizer.setPanelWindow(&emptyWindow);
        emptySynchronizer.setEnabled(true);
        emptyWindow.resize(640, 64);
        QTest::qWait(1);
        QVERIFY(emptyWindow.mask().isEmpty());

        QQuickWindow complexWindow;
        complexWindow.resize(320, 64);
        const QRegion complexMask(QRect(0, 12, 120, 52));
        const QRegion secondRect(QRect(180, 12, 140, 52));
        complexWindow.setMask(complexMask.united(secondRect));

        PanelInputRegionSynchronizer complexSynchronizer;
        complexSynchronizer.setPanelWindow(&complexWindow);
        complexSynchronizer.setEnabled(true);
        complexWindow.resize(640, 64);
        QTest::qWait(1);
        QCOMPARE(complexWindow.mask(), complexMask.united(secondRect));
    }

    void leavesMaskUntouchedWhileDisabled()
    {
        QQuickWindow window;
        window.resize(320, 64);
        window.setMask(QRegion(QRect(0, 12, 320, 52)));

        PanelInputRegionSynchronizer synchronizer;
        synchronizer.setPanelWindow(&window);
        window.resize(760, 64);
        QTest::qWait(1);

        QCOMPARE(window.mask().boundingRect(), QRect(0, 12, 320, 52));
    }
};

QTEST_MAIN(PanelInputRegionSynchronizerTest)

#include "panelinputregionsynchronizer_test.moc"
