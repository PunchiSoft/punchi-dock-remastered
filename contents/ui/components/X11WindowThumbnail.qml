import QtQuick
import org.kde.plasma.core as PlasmaCore

Item {
    id: root

    property int winId: 0

    readonly property bool hasThumbnail: thumbnail.paintedWidth > 0
        && thumbnail.paintedHeight > 0

    // Plasma 6.8 removed WindowThumbnail together with X11 session support.
    // This file is loaded through Loader.source only when KWindowSystem reports
    // X11, so the type is never resolved in a Plasma 6.8/Wayland session.
    // qmllint disable import
    // Plasma 6.8 removes this type with X11; older X11 sessions still provide it.
    // qmllint disable unresolved-type unqualified
    PlasmaCore.WindowThumbnail {
        id: thumbnail

        anchors.fill: parent
        winId: root.winId
    }
    // qmllint enable unresolved-type unqualified
}
