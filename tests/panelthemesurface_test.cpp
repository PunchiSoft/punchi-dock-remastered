// SPDX-License-Identifier: GPL-3.0-or-later
#include "panelthemesurface.h"

#include <QGuiApplication>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QSignalSpy>
#include <QTest>

#include <limits>
#include <memory>

class PanelThemeSurfaceTest : public QObject
{
    Q_OBJECT

private:
    static QQuickItem *createPanel(QQmlEngine &engine, QQuickWindow &window)
    {
        QQmlComponent component(&engine);
        component.setData(R"(
            import QtQuick
            Item {
                width: 1000; height: 90
                property var panelMask: null
                property real leftShadowMargin: -8
                property real rightShadowMargin: -8
                property real topShadowMargin: -10
                property real bottomShadowMargin: -16
            }
        )", QUrl());
        auto *root = qobject_cast<QQuickItem *>(component.create());
        if (root) {
            root->setParentItem(window.contentItem());
        }
        return root;
    }

private Q_SLOTS:
    void followsHostWithoutResizingPanel()
    {
        QQmlEngine engine;
        QQuickWindow window;
        window.resize(1000, 90);
        std::unique_ptr<QQuickItem> panel(createPanel(engine, window));
        QVERIFY(panel);
        PanelThemeSurface surface;
        surface.setPanelWindow(&window);
        surface.setRequested(true);
        QVERIFY(surface.hosting());
        QCOMPARE(surface.parentItem(), window.contentItem());
        QCOMPARE(surface.position(), QPointF(8, 10));
        QCOMPARE(surface.size(), QSizeF(984, 64));
        QVERIFY(surface.z() < panel->z());
        QVERIFY(!surface.isEnabled());
        QCOMPARE(surface.acceptedMouseButtons(), Qt::NoButton);
        QCOMPARE(surface.implicitWidth(), 0);
        QCOMPARE(surface.implicitHeight(), 0);

        QQuickItem otherWidget(panel.get());
        otherWidget.setSize(QSizeF(120, 40));
        otherWidget.setPosition(QPointF(800, 20));
        QSignalSpy panelSize(panel.get(), &QQuickItem::heightChanged);
        panel->setProperty("topShadowMargin", 0.0);
        panel->setProperty("bottomShadowMargin", -26.0);
        QCOMPARE(surface.position(), QPointF(8, 0));
        QCOMPARE(surface.height(), 64);
        QCOMPARE(panelSize.count(), 0);
        QCOMPARE(otherWidget.position(), QPointF(800, 20));
        QCOMPARE(otherWidget.size(), QSizeF(120, 40));

        panel->setWidth(700);
        QCOMPARE(surface.width(), 684);
        panel->setHeight(110);
        QCOMPARE(surface.height(), 84);
        QCOMPARE(window.size(), QSize(1000, 90));
        panel->setX(20);
        QCOMPARE(surface.x(), 28);
        panel->setZ(4);
        QCOMPARE(surface.z(), 3);

        panel->setProperty("leftShadowMargin", std::numeric_limits<double>::quiet_NaN());
        QVERIFY(!surface.hosting());
        QVERIFY(!surface.isVisible());
        panel->setProperty("leftShadowMargin", -8.0);
        QVERIFY(surface.hosting());
        panel->setProperty("rightShadowMargin", -900.0);
        QVERIFY(!surface.hosting());
    }

    void verticalAndShadowExtents()
    {
        QQmlEngine engine;
        QQuickWindow window;
        std::unique_ptr<QQuickItem> panel(createPanel(engine, window));
        QVERIFY(panel);
        panel->setSize(QSizeF(90, 1000));
        panel->setProperty("leftShadowMargin", -16.0);
        panel->setProperty("rightShadowMargin", -10.0);
        panel->setProperty("topShadowMargin", -8.0);
        panel->setProperty("bottomShadowMargin", -8.0);
        PanelThemeSurface surface;
        surface.setPanelWindow(&window);
        surface.setRequested(true);
        QCOMPARE(surface.position(), QPointF(16, 8));
        QCOMPARE(surface.size(), QSizeF(64, 984));
        panel->setProperty("leftShadowMargin", 0.0);
        panel->setProperty("rightShadowMargin", -26.0);
        QCOMPARE(surface.position(), QPointF(0, 8));
        QCOMPARE(surface.width(), 64);
    }

    void conflictFallbackAndDestruction()
    {
        QQmlEngine engine;
        auto window = std::make_unique<QQuickWindow>();
        std::unique_ptr<QQuickItem> panel(createPanel(engine, *window));
        QVERIFY(panel);
        PanelThemeSurface first;
        first.setPanelWindow(window.get());
        first.setRequested(true);
        QVERIFY(first.hosting());
        {
            PanelThemeSurface second;
            second.setPanelWindow(window.get());
            second.setRequested(true);
            QVERIFY(!first.hosting());
            QVERIFY(!second.hosting());
            second.setRequested(false);
            QVERIFY(first.hosting());
            second.setRequested(true);
        }
        QTRY_VERIFY(first.hosting());
        first.setRequested(false);
        QVERIFY(!first.hosting());
        first.setRequested(true);
        QVERIFY(first.hosting());
        panel.reset();
        QTRY_VERIFY(!first.hosting());
        panel.reset(createPanel(engine, *window));
        QTRY_VERIFY(first.hosting());
        window.reset();
        QVERIFY(!first.hosting());
        QVERIFY(!first.panelWindow());
    }

    void unsupportedHostDoesNotActivate()
    {
        QQuickWindow window;
        QQuickItem ordinaryRoot(window.contentItem());
        ordinaryRoot.setSize(QSizeF(1000, 60));
        PanelThemeSurface surface;
        surface.setPanelWindow(&window);
        surface.setRequested(true);
        QVERIFY(!surface.hosting());
        QVERIFY(!surface.isVisible());
    }

    void restingContentTracksAncestryAndLifetime()
    {
        QQmlEngine engine;
        QQuickWindow window;
        std::unique_ptr<QQuickItem> panel(createPanel(engine, window));
        QVERIFY(panel);
        QQuickItem wrapper(panel.get());
        wrapper.setPosition(QPointF(20, 5));
        auto row = std::make_unique<QQuickItem>(&wrapper);
        row->setPosition(QPointF(7, 24));
        row->setSize(QSizeF(500, 36));
        PanelThemeSurface surface;
        surface.setPanelWindow(&window);
        surface.setContentReference(row.get());
        surface.setRequested(true);
        QCOMPARE(surface.contentGeometry(), QRectF(19, 19, 500, 36));
        QSignalSpy changed(&surface, &PanelThemeSurface::contentGeometryChanged);
        wrapper.setY(15);
        QVERIFY(!changed.isEmpty());
        QCOMPARE(surface.contentGeometry(), QRectF(19, 29, 500, 36));

        wrapper.setTransformOrigin(QQuickItem::TopLeft);
        wrapper.setScale(2);
        QCOMPARE(surface.contentGeometry(), QRectF(26, 53, 1000, 72));
        QQuickItem otherWrapper(panel.get());
        otherWrapper.setPosition(QPointF(40, 10));
        row->setParentItem(&otherWrapper);
        QCOMPARE(surface.contentGeometry(), QRectF(39, 24, 500, 36));
        changed.clear();
        otherWrapper.setY(20);
        QVERIFY(!changed.isEmpty());
        QCOMPARE(surface.contentGeometry(), QRectF(39, 34, 500, 36));

        surface.setRequested(false);
        QVERIFY(surface.contentGeometry().isEmpty());
        surface.setRequested(true);
        QVERIFY(!surface.contentGeometry().isEmpty());
        row.reset();
        QVERIFY(!surface.contentReference());
        QVERIFY(surface.contentGeometry().isEmpty());
    }
};

QTEST_MAIN(PanelThemeSurfaceTest)
#include "panelthemesurface_test.moc"
