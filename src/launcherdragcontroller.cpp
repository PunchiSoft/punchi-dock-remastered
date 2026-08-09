// SPDX-License-Identifier: GPL-3.0-or-later

#include "launcherdragcontroller.h"

#include "desktoplauncherresolver.h"

#include <KService>

#include <QDrag>
#include <QIcon>
#include <QMimeData>
#include <QPointer>
#include <QQuickItem>
#include <QQuickWindow>
#include <QUrl>

LauncherDragController::LauncherDragController(QObject *parent)
    : QObject(parent)
{
}

bool LauncherDragController::dragging() const
{
    return m_dragging;
}

int LauncherDragController::iconSize() const
{
    return m_iconSize;
}

void LauncherDragController::setIconSize(int iconSize)
{
    const int boundedSize = qBound(16, iconSize, 256);
    if (m_iconSize == boundedSize) {
        return;
    }
    m_iconSize = boundedSize;
    Q_EMIT iconSizeChanged();
}

bool LauncherDragController::startApplicationDrag(
    QQuickItem *sourceItem, const QString &storageId, const QString &iconName)
{
    if (m_dragging || !sourceItem) {
        return false;
    }

    const QString requestedStorageId = storageId.trimmed();
    if (requestedStorageId.isEmpty() || requestedStorageId.size() > 512) {
        return false;
    }

    KService::Ptr service = KService::serviceByStorageId(requestedStorageId);
    if (!service) {
        service = KService::serviceByMenuId(requestedStorageId);
    }
    if (!service || !service->isApplication() || service->noDisplay()) {
        return false;
    }

    const DesktopLauncherResolver::Resolution launcher
        = DesktopLauncherResolver::resolveLocalFile(service->entryPath());
    if (!launcher) {
        return false;
    }

    const QPointer<QQuickItem> guardedSource(sourceItem);
    const QString launcherPath = launcher.canonicalPath;
    QMetaObject::invokeMethod(this,
        [this, guardedSource, launcherPath, iconName]() {
            runDrag(guardedSource.data(), launcherPath, iconName);
        },
        Qt::QueuedConnection);
    return true;
}

void LauncherDragController::runDrag(
    QQuickItem *sourceItem, const QString &launcherPath, const QString &iconName)
{
    if (!sourceItem || m_dragging) {
        Q_EMIT dragFinished(false);
        return;
    }

    const DesktopLauncherResolver::Resolution launcher
        = DesktopLauncherResolver::resolveLocalFile(launcherPath);
    if (!launcher) {
        Q_EMIT dragFinished(false);
        return;
    }

    setDragging(true);
    if (sourceItem->window() && sourceItem->window()->mouseGrabberItem()) {
        sourceItem->window()->mouseGrabberItem()->ungrabMouse();
    }

    QDrag drag(this);
    auto *mimeData = new QMimeData;
    mimeData->setUrls({QUrl::fromLocalFile(launcher.canonicalPath)});
    mimeData->setData(QStringLiteral("application/x-punchi-launcher"),
        QByteArrayLiteral("1"));
    drag.setMimeData(mimeData);

    const QString effectiveIcon = iconName.trimmed().isEmpty()
        ? launcher.service->icon()
        : iconName.trimmed();
    if (!effectiveIcon.isEmpty()) {
        drag.setPixmap(QIcon::fromTheme(effectiveIcon).pixmap(m_iconSize, m_iconSize));
    }

    const Qt::DropAction action = drag.exec(Qt::CopyAction, Qt::CopyAction);
    setDragging(false);
    Q_EMIT dragFinished(action != Qt::IgnoreAction);
}

void LauncherDragController::setDragging(bool dragging)
{
    if (m_dragging == dragging) {
        return;
    }
    m_dragging = dragging;
    Q_EMIT draggingChanged();
}
