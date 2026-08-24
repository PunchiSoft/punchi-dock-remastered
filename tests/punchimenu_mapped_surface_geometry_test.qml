// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components/punchimenu"

TestCase {
    id: testCase

    name: "PunchiMenuMappedSurfaceGeometry"
    when: windowShown
    width: 1000
    height: 700

    Item {
        id: target
        x: 17
        y: 23
        width: 900
        height: 620

        Item {
            id: surface
            anchors.fill: parent
            transform: Translate {
                id: surfaceTranslation
            }

            Item {
                id: background
                x: -10
                y: -12
                width: parent.width + 20
                height: parent.height + 24
            }
        }
    }

    PunchiMenuMappedSurfaceGeometry {
        id: mappedGeometry
        targetItem: target
        surfaceItem: surface
        backgroundItem: background
        translationX: surfaceTranslation.x
        translationY: surfaceTranslation.y
        leftInset: 12
        topInset: 14
        rightInset: 16
        bottomInset: 18
    }

    function roundedRect(topLeft, bottomRight) {
        return Qt.rect(
            Math.round(Math.min(topLeft.x, bottomRight.x)),
            Math.round(Math.min(topLeft.y, bottomRight.y)),
            Math.max(0, Math.round(Math.abs(bottomRight.x - topLeft.x))),
            Math.max(0, Math.round(Math.abs(bottomRight.y - topLeft.y))))
    }

    function copyRect(rectangle) {
        return Qt.rect(rectangle.x, rectangle.y,
            rectangle.width, rectangle.height)
    }

    function copyPoint(point) {
        return Qt.point(point.x, point.y)
    }

    function verifyFinalMappedGeometry(placementMode) {
        const finalGeometry = copyRect(
            mappedGeometry.effectiveBackdropGeometry)
        const finalOffset = copyPoint(mappedGeometry.backgroundMaskOffset)

        surface.transformOrigin = placementMode === "centered"
            ? Item.Center : Item.Bottom
        surface.scale = placementMode === "centered" ? 0.93 : 0.88
        surfaceTranslation.y = placementMode === "centered" ? 0 : 30
        tryVerify(function() {
            const current = mappedGeometry.effectiveBackdropGeometry
            return current.width < finalGeometry.width - 1
                && current.height < finalGeometry.height - 1
        })

        const transformedGeometry = copyRect(
            mappedGeometry.effectiveBackdropGeometry)
        const transformedOffset = copyPoint(
            mappedGeometry.backgroundMaskOffset)

        surface.scale = 1.0
        surfaceTranslation.y = 0
        tryVerify(function() {
            const current = mappedGeometry.effectiveBackdropGeometry
            return current.x === finalGeometry.x
                && current.y === finalGeometry.y
                && current.width === finalGeometry.width
                && current.height === finalGeometry.height
        })

        const expectedTopLeft = background.mapToItem(target,
            Qt.point(mappedGeometry.leftInset, mappedGeometry.topInset))
        const expectedBottomRight = background.mapToItem(target,
            Qt.point(background.width - mappedGeometry.rightInset,
                background.height - mappedGeometry.bottomInset))
        const expectedGeometry = roundedRect(expectedTopLeft,
            expectedBottomRight)
        const actualGeometry = mappedGeometry.effectiveBackdropGeometry

        compare(actualGeometry.x, expectedGeometry.x)
        compare(actualGeometry.y, expectedGeometry.y)
        compare(actualGeometry.width, expectedGeometry.width)
        compare(actualGeometry.height, expectedGeometry.height)

        const expectedOffset = background.mapToItem(null, Qt.point(0, 0))
        compare(mappedGeometry.backgroundMaskOffset.x,
            Math.round(expectedOffset.x))
        compare(mappedGeometry.backgroundMaskOffset.y,
            Math.round(expectedOffset.y))

        compare(actualGeometry.x, finalGeometry.x)
        compare(actualGeometry.y, finalGeometry.y)
        compare(actualGeometry.width, finalGeometry.width)
        compare(actualGeometry.height, finalGeometry.height)
        compare(mappedGeometry.backgroundMaskOffset.x, finalOffset.x)
        compare(mappedGeometry.backgroundMaskOffset.y, finalOffset.y)
        verify(transformedGeometry.width < actualGeometry.width - 1)
        verify(transformedGeometry.height < actualGeometry.height - 1)
        verify(mappedGeometry.backgroundMaskOffset.x !== transformedOffset.x
            || mappedGeometry.backgroundMaskOffset.y !== transformedOffset.y)
    }

    function init() {
        failOnWarning(/.?/)
        surface.scale = 1.0
        surface.transformOrigin = Item.Center
        surfaceTranslation.x = 0
        surfaceTranslation.y = 0
    }

    function test_centeredGeometryFollowsFinalScale() {
        verifyFinalMappedGeometry("centered")
    }

    function test_anchoredGeometryFollowsFinalScale() {
        verifyFinalMappedGeometry("anchored")
    }
}
