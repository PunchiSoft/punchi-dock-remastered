// SPDX-License-Identifier: GPL-3.0-or-later

#include "blurbehindcontroller.h"

#include <QMetaMethod>
#include <QMetaObject>
#include <QMetaProperty>

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
}

int main()
{
    BlurBehindController controller;
    const QMetaObject *metaObject = controller.metaObject();

    const int propertyIndex = metaObject->indexOfProperty("available");
    bool passed = expect(propertyIndex >= 0, "available property must be exposed");
    if (propertyIndex >= 0) {
        const QMetaProperty property = metaObject->property(propertyIndex);
        passed &= expect(property.hasNotifySignal(), "available must notify QML when KWin blur availability changes");
        passed &= expect(!property.isConstant(), "available must not cache KWin blur availability as a constant");
        passed &= expect(property.notifySignal().name() == "availableChanged", "available must use availableChanged as its notifier");
    }

    passed &= expect(metaObject->indexOfMethod("reapply()") >= 0, "reapply must remain invokable from QML");
    controller.reapply();

    return passed ? 0 : 1;
}
