// SPDX-License-Identifier: GPL-3.0-or-later

#include "blurbehindcontroller.h"

#include <QMargins>
#include <QMetaMethod>
#include <QMetaObject>
#include <QMetaProperty>
#include <QPoint>
#include <QRect>
#include <QRegion>
#include <QVariant>
#include <QtGlobal>

#include <algorithm>
#include <iostream>

namespace
{
bool expect(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << "FAIL: " << message << '\n';
    }
    return condition;
}

QRegion referenceContractMask(const QRegion &sourceMask, const QMargins &insets)
{
    const int left = std::max(0, insets.left());
    const int top = std::max(0, insets.top());
    const int right = std::max(0, insets.right());
    const int bottom = std::max(0, insets.bottom());
    const int radialInset = std::min({left, top, right, bottom});
    const int residualLeft = left - radialInset;
    const int residualTop = top - radialInset;
    const int residualRight = right - radialInset;
    const int residualBottom = bottom - radialInset;
    const qint64 squaredRadius = qint64(radialInset) * radialInset;
    const QRect candidateBounds = sourceMask.boundingRect().adjusted(
        left, top, -right, -bottom);
    QRegion referenceRegion;

    for (int y = candidateBounds.top(); y <= candidateBounds.bottom(); ++y) {
        for (int x = candidateBounds.left(); x <= candidateBounds.right(); ++x) {
            const QPoint candidate(x, y);
            bool keepCandidate = true;
            for (int vertical = -residualBottom;
                 vertical <= residualTop && keepCandidate; ++vertical) {
                for (int horizontal = -residualRight;
                     horizontal <= residualLeft && keepCandidate; ++horizontal) {
                    for (int diskY = -radialInset;
                         diskY <= radialInset && keepCandidate; ++diskY) {
                        for (int diskX = -radialInset;
                             diskX <= radialInset; ++diskX) {
                            if (qint64(diskX) * diskX + qint64(diskY) * diskY
                                > squaredRadius) {
                                continue;
                            }
                            const QPoint sourcePoint = candidate - QPoint(
                                diskX + horizontal, diskY + vertical);
                            if (!sourceMask.contains(sourcePoint)) {
                                keepCandidate = false;
                                break;
                            }
                        }
                    }
                }
            }
            if (keepCandidate) {
                referenceRegion += QRegion(QRect(x, y, 1, 1));
            }
        }
    }
    return referenceRegion;
}
}

int main()
{
    BlurBehindController controller;
    const QMetaObject *metaObject = controller.metaObject();

    const int propertyIndex = metaObject->indexOfProperty("available");
    bool passed = expect(propertyIndex >= 0, "available property must be exposed");
    if (propertyIndex >= 0) {
        const QMetaProperty property = metaObject->property(propertyIndex);
        passed &= expect(property.hasNotifySignal(),
                         "available must notify QML when KWin blur availability changes");
        passed &= expect(!property.isConstant(),
                         "available must not cache KWin blur availability as a constant");
        passed &= expect(property.notifySignal().name() == "availableChanged",
                         "available must use availableChanged as its notifier");
    }

    passed &= expect(metaObject->indexOfMethod("reapply()") >= 0,
                     "reapply must remain invokable from QML");

    const int maskSourcePropertyIndex = metaObject->indexOfProperty("maskSource");
    passed &= expect(maskSourcePropertyIndex >= 0, "maskSource property must be exposed");
    if (maskSourcePropertyIndex >= 0) {
        const QMetaProperty property = metaObject->property(maskSourcePropertyIndex);
        passed &= expect(qstrcmp(property.typeName(), "QObject*") == 0,
                         "maskSource must accept a themed QML object");
        passed &= expect(property.isWritable(), "maskSource must be writable from QML");
        passed &= expect(property.notifySignal().name() == "maskSourceChanged",
                         "maskSource must use maskSourceChanged as its notifier");
    }

    int maskSourceChangeCount = 0;
    QObject::connect(&controller, &BlurBehindController::maskSourceChanged,
                     [&maskSourceChangeCount]() {
        ++maskSourceChangeCount;
    });
    QObject themedMaskSource;
    themedMaskSource.setProperty(
        "mask",
        QVariant::fromValue(QRegion(QRect(4, 6, 80, 48), QRegion::Ellipse)));
    controller.setMaskSource(&themedMaskSource);
    passed &= expect(controller.maskSource() == &themedMaskSource,
                     "maskSource must preserve the themed frame object");
    controller.setMaskSource(&themedMaskSource);
    passed &= expect(maskSourceChangeCount == 1,
                     "setting the same maskSource must not emit a duplicate change");

    int maskOffsetChangeCount = 0;
    QObject::connect(&controller, &BlurBehindController::maskOffsetChanged,
                     [&maskOffsetChangeCount]() {
        ++maskOffsetChangeCount;
    });
    const QPoint themedMaskOffset(-2, -3);
    controller.setMaskOffset(themedMaskOffset);
    passed &= expect(controller.maskOffset() == themedMaskOffset,
                     "maskOffset must preserve the themed frame position");
    controller.setMaskOffset(themedMaskOffset);
    passed &= expect(maskOffsetChangeCount == 1,
                     "setting the same maskOffset must not emit a duplicate change");

    const int useInsetsPropertyIndex = metaObject->indexOfProperty("useMaskSourceInsets");
    passed &= expect(useInsetsPropertyIndex >= 0,
                     "useMaskSourceInsets property must be exposed");
    if (useInsetsPropertyIndex >= 0) {
        const QMetaProperty property = metaObject->property(useInsetsPropertyIndex);
        passed &= expect(property.metaType().id() == QMetaType::Bool,
                         "useMaskSourceInsets must be a boolean");
        passed &= expect(property.isWritable(),
                         "useMaskSourceInsets must be writable from QML");
        passed &= expect(property.notifySignal().name() == "useMaskSourceInsetsChanged",
                         "useMaskSourceInsets must use its dedicated notifier");
    }

    int useInsetsChangeCount = 0;
    QObject::connect(&controller, &BlurBehindController::useMaskSourceInsetsChanged,
                     [&useInsetsChangeCount]() {
        ++useInsetsChangeCount;
    });
    controller.setUseMaskSourceInsets(true);
    controller.setUseMaskSourceInsets(true);
    passed &= expect(controller.useMaskSourceInsets(),
                     "useMaskSourceInsets must preserve the requested state");
    passed &= expect(useInsetsChangeCount == 1,
                     "setting the same inset mode must not emit a duplicate change");

    const QRegion rectangularMask(QRect(0, 0, 100, 80));
    const QRegion asymmetricContractedMask = BlurBehindController::contractMaskToInsets(
        rectangularMask, QMargins(10, 8, 6, 4));
    passed &= expect(asymmetricContractedMask.boundingRect() == QRect(10, 8, 84, 68),
                     "mask contraction must honor each runtime inset independently");

    const QRegion ellipticalMask(QRect(0, 0, 100, 80), QRegion::Ellipse);
    const QRegion roundedContractedMask = BlurBehindController::contractMaskToInsets(
        ellipticalMask, QMargins(10, 10, 10, 10));
    passed &= expect(roundedContractedMask.boundingRect() == QRect(10, 10, 80, 60),
                     "mask contraction must produce the effective inset bounds");
    passed &= expect(!roundedContractedMask.contains(QPoint(10, 10)),
                     "mask contraction must preserve a rounded corner");
    passed &= expect(roundedContractedMask.contains(QPoint(50, 40)),
                     "mask contraction must preserve the mask center");

    QRegion nonConvexMask(QRect(0, 0, 17, 17));
    nonConvexMask -= QRegion(QRect(8, 8, 1, 1));
    const QMargins radialInsets(2, 2, 2, 2);
    passed &= expect(BlurBehindController::contractMaskToInsets(
                         nonConvexMask, radialInsets)
                         == referenceContractMask(nonConvexMask, radialInsets),
                     "radial contraction must be exact around holes and concavities");

    const QMargins horizontalInsets(3, 0, 2, 0);
    passed &= expect(BlurBehindController::contractMaskToInsets(
                         nonConvexMask, horizontalInsets)
                         == referenceContractMask(nonConvexMask, horizontalInsets),
                     "asymmetric contraction must be exact for non-convex masks");
    controller.reapply();

    return passed ? 0 : 1;
}
