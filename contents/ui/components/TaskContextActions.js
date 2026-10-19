// SPDX-License-Identifier: GPL-3.0-or-later
// Pure construction of application-window context actions. Labels are passed
// in from QML so this library stays free of translation side effects.
.pragma library

function taskAction(operation, name, icon, snapshot, extra) {
    const action = {
        "kind": "taskAction",
        "operation": operation,
        "name": name,
        "icon": icon,
        "taskRow": snapshot.taskRow,
        "enabled": true
    }
    if (extra) {
        for (const key in extra) {
            action[key] = extra[key]
        }
    }
    return action
}

function desktopIds(snapshot) {
    const result = []
    const values = snapshot && snapshot.virtualDesktops instanceof Array
        ? snapshot.virtualDesktops : []
    for (let index = 0; index < values.length; index++) {
        result.push(String(values[index]))
    }
    return result
}

function onCurrentDesktop(snapshot) {
    const assigned = desktopIds(snapshot)
    return !snapshot.onAllDesktops && assigned.length === 1
        && assigned[0] === String(snapshot.currentDesktop || "")
}

function desktopIsAssigned(snapshot, desktopId) {
    const assigned = desktopIds(snapshot)
    for (let index = 0; index < assigned.length; index++) {
        if (assigned[index] === String(desktopId)) {
            return true
        }
    }
    return false
}

function moveToDesktopSubmenu(snapshot, labels) {
    const desktops = snapshot && snapshot.desktops instanceof Array
        ? snapshot.desktops : []
    if (!snapshot || !snapshot.desktopChangeable || desktops.length <= 1) {
        return null
    }

    const children = []
    const currentDesktop = String(snapshot.currentDesktop || "")
    if (currentDesktop.length > 0) {
        const checked = onCurrentDesktop(snapshot)
        children.push(taskAction("moveToDesktop", labels.moveToCurrentDesktop,
            "virtual-desktops", snapshot, {
                "desktopId": currentDesktop,
                "checked": checked,
                "enabled": !checked
            }))
    }
    children.push(taskAction("moveToDesktop", labels.allDesktops,
        "virtual-desktops", snapshot, {
            "allDesktops": true,
            "checked": !!snapshot.onAllDesktops,
            "enabled": !snapshot.onAllDesktops
        }))

    for (let index = 0; index < desktops.length; index++) {
        const desktop = desktops[index] || {}
        const desktopId = String(desktop.id === undefined ? desktop : desktop.id)
        if (desktopId.length === 0 || desktopId === currentDesktop) {
            continue
        }
        const checked = !snapshot.onAllDesktops
            && desktopIsAssigned(snapshot, desktopId)
        children.push(taskAction("moveToDesktop",
            String(desktop.name || desktopId), "virtual-desktops", snapshot, {
                "desktopId": desktopId,
                "checked": checked
            }))
    }

    children.push(taskAction("newVirtualDesktop", labels.newDesktop,
        "list-add", snapshot))

    return {
        "kind": "submenu",
        "name": labels.moveToDesktop,
        "icon": "virtual-desktops",
        "enabled": true,
        "children": children
    }
}

function moreSubmenu(snapshot, labels) {
    if (!snapshot || !snapshot.window) {
        return null
    }

    const children = []
    if (snapshot.movable) {
        children.push(taskAction("move", labels.move, "transform-move", snapshot))
    }
    if (snapshot.resizable) {
        children.push(taskAction("resize", labels.resize, "transform-scale", snapshot))
    }
    if (snapshot.maximizable) {
        children.push(taskAction("toggleMaximized",
            snapshot.maximized ? labels.restoreFromMaximized : labels.maximize,
            snapshot.maximized ? "window-restore" : "window-maximize", snapshot, {
                "checked": !!snapshot.maximized
            }))
    }
    if (snapshot.minimizable) {
        children.push(taskAction("toggleMinimized",
            snapshot.minimized ? labels.restore : labels.minimize,
            snapshot.minimized ? "window-restore" : "window-minimize", snapshot, {
                "checked": !!snapshot.minimized
            }))
    }
    children.push(taskAction("toggleKeepAbove",
        snapshot.keepAbove ? labels.doNotKeepAbove : labels.keepAbove,
        "window-keep-above", snapshot, {
            "checked": !!snapshot.keepAbove
        }))
    children.push(taskAction("toggleKeepBelow",
        snapshot.keepBelow ? labels.doNotKeepBelow : labels.keepBelow,
        "window-keep-below", snapshot, {
            "checked": !!snapshot.keepBelow
        }))
    if (snapshot.fullscreenable) {
        children.push(taskAction("toggleFullScreen",
            snapshot.fullscreen ? labels.exitFullscreen : labels.fullscreen,
            snapshot.fullscreen ? "view-restore" : "view-fullscreen", snapshot, {
                "checked": !!snapshot.fullscreen
            }))
    }
    if (snapshot.canSetNoBorder) {
        children.push(taskAction("toggleNoBorder", labels.noBorder,
            "edit-none-border", snapshot, {
                "checked": !!snapshot.noBorder
            }))
    }
    if (snapshot.canHideFromCapture) {
        children.push(taskAction("toggleExcludeFromCapture",
            labels.hideFromCapture, "view-private", snapshot, {
                "checked": !!snapshot.excludedFromCapture
            }))
    }

    if (children.length === 0) {
        return null
    }
    return {
        "kind": "submenu",
        "name": labels.more,
        "icon": "view-more-symbolic",
        "enabled": true,
        "children": children
    }
}

function windowActions(snapshot, labels, includeClose) {
    if (!snapshot || !snapshot.window) {
        return []
    }

    const actions = []
    const desktopMenu = moveToDesktopSubmenu(snapshot, labels)
    if (desktopMenu) {
        actions.push(desktopMenu)
    }
    const moreMenu = moreSubmenu(snapshot, labels)
    if (moreMenu) {
        actions.push(moreMenu)
    }
    if (includeClose && snapshot.closable) {
        actions.push(taskAction("close", labels.close, "window-close", snapshot, {
            "destructive": true
        }))
    }
    return actions
}
