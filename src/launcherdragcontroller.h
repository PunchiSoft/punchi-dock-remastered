// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QQuickItem>
#include <qqmlregistration.h>

class LauncherDragController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool dragging READ dragging NOTIFY draggingChanged)
    Q_PROPERTY(int iconSize READ iconSize WRITE setIconSize NOTIFY iconSizeChanged)

public:
    explicit LauncherDragController(QObject *parent = nullptr);

    bool dragging() const;
    int iconSize() const;
    void setIconSize(int iconSize);

    Q_INVOKABLE bool startApplicationDrag(
        QQuickItem *sourceItem, const QString &storageId, const QString &iconName);

Q_SIGNALS:
    void draggingChanged();
    void iconSizeChanged();
    void dragFinished(bool accepted);

private:
    void setDragging(bool dragging);
    void runDrag(QQuickItem *sourceItem, const QString &launcherPath, const QString &iconName);

    bool m_dragging = false;
    int m_iconSize = 48;
};
